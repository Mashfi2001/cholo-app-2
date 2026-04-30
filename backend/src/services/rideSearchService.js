const prisma = require("../lib/prisma");

// -------------------------------
// Distance (Haversine)
// -------------------------------
function getDistance(lat1, lng1, lat2, lng2) {
  const R = 6371e3;
  const toRad = (deg) => deg * Math.PI / 180;

  const φ1 = toRad(lat1);
  const φ2 = toRad(lat2);
  const Δφ = toRad(lat2 - lat1);
  const Δλ = toRad(lng2 - lng1);

  const a =
    Math.sin(Δφ / 2) ** 2 +
    Math.cos(φ1) * Math.cos(φ2) *
    Math.sin(Δλ / 2) ** 2;

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return R * c; // meters
}

// -------------------------------
// POLYLINE DECODER (Google encoded polyline)
// -------------------------------
function decodePolyline(encoded) {
  if (!encoded) return [];
  
  const points = [];
  let index = 0, lat = 0, lng = 0;

  while (index < encoded.length) {
    let byte = 0, shift = 0, result = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      byte = encoded.charCodeAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);

    const dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    points.push([lat * 1e-5, lng * 1e-5]);
  }
  return points;
}

// -------------------------------
// Distance to line segment
// -------------------------------
function distanceToSegment(point, a, b) {
  const px = point[0], py = point[1];
  const ax = a[0], ay = a[1];
  const bx = b[0], by = b[1];

  const dx = bx - ax, dy = by - ay;
  const lenSq = dx*dx + dy*dy;
  
  if (lenSq === 0) return getDistance(px, py, ax, ay);

  let t = ((px - ax) * dx + (py - ay) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));

  const projX = ax + t * dx;
  const projY = ay + t * dy;
  return getDistance(px, py, projX, projY);
}

function calculateETA(distanceMeters, avgSpeedKmh = 50) {
  // Convert speed from km/h to m/s
  const speedMs = (avgSpeedKmh * 1000) / 3600;
  
  // Time in seconds
  const timeSeconds = distanceMeters / speedMs;
  
  // Convert to minutes
  const etaMinutes = timeSeconds / 60;
  
  return Math.round(etaMinutes);
}

// ===== FIXED FUNCTIONS - SCOPE ISSUE RESOLVED =====
// -------------------------------
// FORMAT FOR FLUTTER MAP
// -------------------------------
function formatRide(pickupLat, pickupLng, dropLat, dropLng, ride, pickupToOrigin, dropToDest, requestedTime, pickupRouteDist, dropRouteDist, eta, driver) {
  return {
    id: ride.id,
    driver: {
      id: driver.id,
      name: driver.name || 'Unknown Driver'
    },
    origin: {
      lat: ride.originLat,
      lng: ride.originLng
    },
    
    destination: {
      lat: ride.destinationLat,
      lng: ride.destinationLng
    },
    departureTime: ride.departureTime,
    eta: eta.toISOString(),
    routePolyline: ride.routePolyline,
    requestedTime: requestedTime,
    seats: ride.seats,

    pickupMarker: {
      lat: pickupLat,
      lng: pickupLng
    },
    dropMarker: {
      lat: dropLat,
      lng: dropLng
    },

    meta: {
      pickupDistance: Math.round(pickupToOrigin),
      dropDistance: Math.round(dropToDest),
      pickupRouteDist: Math.round(pickupRouteDist),
      dropRouteDist: Math.round(dropRouteDist),
      etaMinutes: Math.round((new Date(eta) - new Date(requestedTime)) / 60000)
    }
  };
}

// -------------------------------
// MAP CONFIG
// -------------------------------
function getMapConfig(type) {
  switch (type) {
    case "MATCH":
      return {
        showRoutes: true,
        zoomLevel: "normal"
      };

    case "SOLO_SUGGESTION":
      return {
        showRoutes: false,
        showDirectLine: true,
        zoomLevel: "normal"
      };

    default:
      return {};
  }
}

// -------------------------------
// MAIN SEARCH ENGINE
// -------------------------------
exports.findRides = async ({
  pickupLat,
  pickupLng,
  dropLat,
  dropLng,
  requestedTime,
  requestedTimeWindowStart,
  requestedTimeWindowEnd
}, debug = false) => {

  const rides = await prisma.ride.findMany({
    where: {
      status: {
        in: ["PLANNED", "ONGOING"]
      }
    },
    include: {
      driver: true
    }
  });

  let matches = [];

  if (debug) {
    console.log("\n========== RIDE SEARCH DEBUG ==========");
    console.log(`Passenger: pickup(${pickupLat}, ${pickupLng}) → drop(${dropLat}, ${dropLng})`);
    console.log(`Requested time: ${requestedTime}`);
    console.log(`Total rides in DB: ${rides.length}`);
    console.log("========================================\n");
  }

  for (const ride of rides) {
    // Skip if missing coordinates
    if (!ride.originLat || !ride.originLng || !ride.destinationLat || !ride.destinationLng) {
      if (debug) console.log(`❌ Ride ${ride.id}: Missing coordinates`);
      continue;
    }

    // Calculate all key distances first for pickupRouteDist
    const pickupToOrigin = getDistance(pickupLat, pickupLng, ride.originLat, ride.originLng);
    const pickupToDest = getDistance(pickupLat, pickupLng, ride.destinationLat, ride.destinationLng);
    const dropToOrigin = getDistance(dropLat, dropLng, ride.originLat, ride.originLng);
    const dropToDest = getDistance(dropLat, dropLng, ride.destinationLat, ride.destinationLng);
    const rideDistance = getDistance(ride.originLat, ride.originLng, ride.destinationLat, ride.destinationLng);

    // 2. CHECK: Both pickup and drop should be reasonably close to the driver's route
    // This allows pickup/drop anywhere along the route corridor
    const maxDistToRoute = 3000; // 3km tolerance to the route
    
    // POLYLINE ROUTE MATCHING (5km tolerance)
    const routePoints = decodePolyline(ride.routePolyline);
    let pickupRouteDist = Infinity, dropRouteDist = Infinity;

    if (routePoints.length > 1) {
      for (let i = 0; i < routePoints.length - 1; i++) {
        const segDistPickup = distanceToSegment([pickupLat, pickupLng], routePoints[i], routePoints[i+1]);
        const segDistDrop = distanceToSegment([dropLat, dropLng], routePoints[i], routePoints[i+1]);
        pickupRouteDist = Math.min(pickupRouteDist, segDistPickup);
        dropRouteDist = Math.min(dropRouteDist, segDistDrop);
      }
      if (debug) console.log(`  Route polyline: ${routePoints.length} points, pickupDist=${pickupRouteDist.toFixed(0)}m, dropDist=${dropRouteDist.toFixed(0)}m`);
    } else {
      // Fallback to endpoint matching
      pickupRouteDist = Math.min(pickupToOrigin, pickupToDest);
      dropRouteDist = Math.min(dropToOrigin, dropToDest);
    }

    // 1. ETA / TIME WINDOW CHECK (±15min margin) - now pickupRouteDist is available
    const etaMinutes = calculateETA(pickupRouteDist, 50);
    let eta = new Date(requestedTime);
    eta = new Date(eta.getTime() + etaMinutes * 60 * 1000);
    
    if (debug) console.log(`  ETA calc: pickupRouteDist=${pickupRouteDist.toFixed(0)}m, etaMinutes=${etaMinutes}, ETA=${eta.toISOString()}`);

    const timeWindowMarginMin = 15;
    const windowStart = requestedTimeWindowStart ? new Date(requestedTimeWindowStart) : new Date(requestedTime);
    const windowEnd = requestedTimeWindowEnd ? new Date(requestedTimeWindowEnd) : new Date(requestedTime);
    windowStart.setMinutes(windowStart.getMinutes() - timeWindowMarginMin);
    windowEnd.setMinutes(windowEnd.getMinutes() + timeWindowMarginMin);

    if (eta < windowStart || eta > windowEnd) {
      if (debug) console.log(`❌ Ride ${ride.id}: ETA ${eta.toISOString()} outside window [${windowStart.toISOString()}, ${windowEnd.toISOString()}]`);
      continue;
    }


    if (debug) {
      console.log(`Ride ${ride.id}:`);
      console.log(`  Driver route: (${ride.originLat.toFixed(5)}, ${ride.originLng.toFixed(5)}) → (${ride.destinationLat.toFixed(5)}, ${ride.destinationLng.toFixed(5)}), distance=${rideDistance.toFixed(0)}m`);
      console.log(`  Passenger: pickup(${pickupLat.toFixed(5)}, ${pickupLng.toFixed(5)}) → drop(${dropLat.toFixed(5)}, ${dropLng.toFixed(5)})`);
      console.log(`  pickupToOrigin=${pickupToOrigin.toFixed(0)}m, pickupToDest=${pickupToDest.toFixed(0)}m`);
      console.log(`  dropToOrigin=${dropToOrigin.toFixed(0)}m, dropToDest=${dropToDest.toFixed(0)}m`);
    }

    const maxPolylineTolerance = 5000; // 5km
    const pickupCloseToRoute = pickupRouteDist <= maxPolylineTolerance;
    const dropCloseToRoute = dropRouteDist <= maxPolylineTolerance;

    if (!pickupCloseToRoute) {
      if (debug) console.log(`  ❌ Pickup too far from route polyline (${pickupRouteDist.toFixed(0)}m > ${maxPolylineTolerance}m)`);
      continue;
    }
    if (!dropCloseToRoute) {
      if (debug) console.log(`  ❌ Drop too far from route polyline (${dropRouteDist.toFixed(0)}m > ${maxPolylineTolerance}m)`);
      continue;
    }


    // 3. CHECK: Pickup should come before drop (passenger boards before getting off)
    // Allow some flexibility - pickup closer to origin, drop closer to destination
    const pickupBeforeDrop = pickupToOrigin + 1500 <= dropToDest;

    if (!pickupBeforeDrop) {
      if (debug) console.log(`  ⚠️  Direction check (pickupToOrigin + 1500 > dropToDest), but allowing if both near route...`);
      // Still allow if both are reasonably close to route
      if (Math.min(pickupToOrigin, pickupToDest) > 2500 || Math.min(dropToOrigin, dropToDest) > 2500) {
        if (debug) console.log(`  ❌ Both pickup and drop too far from route`);
        continue;
      }
    }

    // ALL CHECKS PASSED - THIS IS A MATCH
    if (debug) console.log(`  ✅ MATCH ACCEPTED\n`);

console.log(`DEBUG: formatRide called with requestedTime=${requestedTime}`);
    matches.push({
      ride: formatRide(pickupLat, pickupLng, dropLat, dropLng, ride, pickupToOrigin, dropToDest, requestedTime, pickupRouteDist, dropRouteDist, eta, ride.driver),
      pickupDist: pickupRouteDist
    });
  }


  if (debug) {
    console.log(`========== RESULTS ==========`);
    console.log(`Matches found: ${matches.length}`);
    console.log(`=============================\n`);
  }

  // Sort by closest pickup
  matches.sort((a, b) => a.pickupDist - b.pickupDist);
  const rides_list = matches.map(m => m.ride);

  if (rides_list.length > 0) {
    return {
      type: "MATCH",
      message: `Found ${rides_list.length} ride(s)`,
      rides: rides_list,
      mapConfig: getMapConfig("MATCH")
    };
  }

  return {
    type: "SOLO_SUGGESTION",
    message: "No shared rides available for your route.",
    soloRide: {
      origin: { lat: pickupLat || 0, lng: pickupLng || 0 },
      destination: { lat: dropLat || 0, lng: dropLng || 0 },
      estimatedType: "PRIVATE_RIDE"
    },
    mapConfig: getMapConfig("SOLO_SUGGESTION")
  };
};
