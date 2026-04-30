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

  return R * c;
}

// -------------------------------
// Decode polyline
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
// Find closest point index
// -------------------------------
function findClosestPointIndex(point, routePoints) {
  let minDist = Infinity;
  let closestIndex = -1;

  for (let i = 0; i < routePoints.length; i++) {
    const dist = getDistance(
      point[0],
      point[1],
      routePoints[i][0],
      routePoints[i][1]
    );

    if (dist < minDist) {
      minDist = dist;
      closestIndex = i;
    }
  }

  return { index: closestIndex, distance: minDist };
}

// -------------------------------
// ETA calculation
// -------------------------------
function calculateETA(distanceMeters, speedKmh = 40) {
  const speedMs = (speedKmh * 1000) / 3600;
  const seconds = distanceMeters / speedMs;
  return Math.round(seconds / 60);
}

// -------------------------------
// Format response
// -------------------------------
function formatRide(ride, pickupLat, pickupLng, dropLat, dropLng, pickupMatch, dropMatch, eta, pickupName, dropName) {
  // Ensure names are not empty
  const finalPickupName = pickupName && pickupName.trim() ? pickupName : `${pickupLat.toFixed(4)}, ${pickupLng.toFixed(4)}`;
  const finalDropName = dropName && dropName.trim() ? dropName : `${dropLat.toFixed(4)}, ${dropLng.toFixed(4)}`;
  
  return {
    id: ride.id,
    driver: {
      id: ride.driver.id,
      name: ride.driver.name || "Driver"
    },
    origin: {
      lat: ride.originLat,
      lng: ride.originLng,
      name: ride.origin
    },
    destination: {
      lat: ride.destinationLat,
      lng: ride.destinationLng,
      name: ride.destination
    },
    departureTime: ride.departureTime,
    eta: eta,
    routePolyline: ride.routePolyline,
    seats: ride.seats,

    pickupMarker: {
      lat: pickupLat,
      lng: pickupLng,
      name: finalPickupName
    },
    dropMarker: {
      lat: dropLat,
      lng: dropLng,
      name: finalDropName
    },

    meta: {
      pickupDistance: Math.round(pickupMatch.distance),
      dropDistance: Math.round(dropMatch.distance),
      pickupIndex: pickupMatch.index,
      dropIndex: dropMatch.index
    }
  };
}

// -------------------------------
// Fallback: Simple distance-based matching (no polyline)
// -------------------------------
function matchRideWithoutPolyline(ride, pickupLat, pickupLng, dropLat, dropLng, requestedTime) {
  const MAX_START_DISTANCE = 5000; // 5km from ride origin
  const MAX_END_DISTANCE = 5000; // 5km from ride destination

  // Check pickup distance to ride origin
  const pickupToOrigin = getDistance(
    pickupLat, pickupLng,
    ride.originLat, ride.originLng
  );

  // Check drop distance to ride destination
  const dropToDestination = getDistance(
    dropLat, dropLng,
    ride.destinationLat, ride.destinationLng
  );

  if (pickupToOrigin > MAX_START_DISTANCE) return null;
  if (dropToDestination > MAX_END_DISTANCE) return null;

  // Check if direction is reasonable (pickup shouldn't be too far from origin, drop too close to origin)
  const pickupToDestination = getDistance(pickupLat, pickupLng, ride.destinationLat, ride.destinationLng);
  const originToDestination = getDistance(ride.originLat, ride.originLng, ride.destinationLat, ride.destinationLng);

  // Pickup should be closer to origin than destination
  if (pickupToOrigin > pickupToDestination) return null;

  // Time window check
  const requested = new Date(requestedTime);
  const diff = Math.abs(ride.departureTime - requested) / 60000;

  if (diff > 45) return null;

  // Calculate rough ETA
  const eta = ride.departureTime;

  return {
    pickupMatch: { distance: pickupToOrigin, index: 0 },
    dropMatch: { distance: dropToDestination, index: 1 },
    eta: eta,
    score: pickupToOrigin + dropToDestination
  };
}

// -------------------------------
// MAIN SEARCH FUNCTION
// -------------------------------
exports.findRides = async ({
  pickupLat,
  pickupLng,
  dropLat,
  dropLng,
  requestedTime,
  pickupName,
  dropName
}, debug = false) => {

  if (debug) {
    console.log("🔍 SEARCH REQUEST:");
    console.log(`  Pickup: "${pickupName}" (${pickupLat}, ${pickupLng})`);
    console.log(`  Drop: "${dropName}" (${dropLat}, ${dropLng})`);
    console.log(`  Time: ${requestedTime}`);
    console.log(`  [DEBUG] pickupName type: ${typeof pickupName}, value: '${pickupName}'`);
    console.log(`  [DEBUG] dropName type: ${typeof dropName}, value: '${dropName}'`);
  }

  const rides = await prisma.ride.findMany({
    where: {
      status: { in: ["PLANNED", "ONGOING"] }
    },
    include: {
      driver: true
    }
  });

  if (debug) {
    console.log(`📍 Found ${rides.length} rides to check`);
    for (const ride of rides) {
      console.log(`  - Ride ${ride.id}: Driver ID=${ride.driverId}, Name=${ride.driver?.name || 'N/A'}`);
    }
    console.log("");
  }

  const matches = [];
  const rejectedReasons = [];

  for (const ride of rides) {

    if (debug) {
      console.log(`\n🚗 RIDE ${ride.id}:`);
      console.log(`  Driver: ${ride.driver.name}`);
      console.log(`  Route: ${ride.origin} → ${ride.destination}`);
      console.log(`  Coords: (${ride.originLat}, ${ride.originLng}) → (${ride.destinationLat}, ${ride.destinationLng})`);
      console.log(`  Time: ${ride.departureTime}`);
      console.log(`  Seats: ${ride.seats}`);
      console.log(`  Polyline: ${ride.routePolyline ? "Yes" : "No"}`);
    }

    if (!ride.originLat || !ride.destinationLat) {
      if (debug) console.log("  ❌ REJECTED: Missing coordinates");
      continue;
    }

    let pickupMatch, dropMatch, eta;

    // Try polyline-based matching first
    if (ride.routePolyline) {
      const routePoints = decodePolyline(ride.routePolyline);

      if (routePoints && routePoints.length >= 2) {
        // POLYLINE-BASED MATCHING
        pickupMatch = findClosestPointIndex(
          [pickupLat, pickupLng],
          routePoints
        );

        dropMatch = findClosestPointIndex(
          [dropLat, dropLng],
          routePoints
        );

        if (debug) {
          console.log(`  Using polyline matching:`);
          console.log(`    Pickup distance: ${Math.round(pickupMatch.distance)}m`);
          console.log(`    Drop distance: ${Math.round(dropMatch.distance)}m`);
        }

        // Distance to route check
        const MAX_DISTANCE = 2000; // 2km

        if (pickupMatch.distance > MAX_DISTANCE) {
          if (debug) console.log(`  ❌ REJECTED: Pickup too far from route (${Math.round(pickupMatch.distance)}m > ${MAX_DISTANCE}m)`);
          continue;
        }
        if (dropMatch.distance > MAX_DISTANCE) {
          if (debug) console.log(`  ❌ REJECTED: Drop too far from route (${Math.round(dropMatch.distance)}m > ${MAX_DISTANCE}m)`);
          continue;
        }

        // Direction check (pickup before drop on route)
        if (pickupMatch.index >= dropMatch.index) {
          if (debug) console.log(`  ❌ REJECTED: Wrong direction (pickup index ${pickupMatch.index} >= drop index ${dropMatch.index})`);
          continue;
        }

        // ETA calculation
        const distanceFromStart = getDistance(
          ride.originLat,
          ride.originLng,
          routePoints[pickupMatch.index][0],
          routePoints[pickupMatch.index][1]
        );

        const etaMinutes = calculateETA(distanceFromStart);
        eta = new Date(ride.departureTime);
        eta = new Date(eta.getTime() + etaMinutes * 60000);

        const requested = new Date(requestedTime);
        const diff = Math.abs(eta - requested) / 60000;

        if (debug) console.log(`    ETA: ${eta}, Diff: ${Math.round(diff)}min`);

        if (diff > 45) {
          if (debug) console.log(`  ❌ REJECTED: Time mismatch (${Math.round(diff)}min > 45min)`);
          continue;
        }
      } else {
        // Polyline present but invalid, fallback to distance-based
        const fallbackMatch = matchRideWithoutPolyline(ride, pickupLat, pickupLng, dropLat, dropLng, requestedTime);
        if (!fallbackMatch) {
          if (debug) console.log(`  ❌ REJECTED: Fallback distance matching failed`);
          continue;
        }
        
        if (debug) {
          console.log(`  Using fallback distance matching:`);
          console.log(`    Pickup distance to origin: ${Math.round(fallbackMatch.pickupMatch.distance)}m`);
          console.log(`    Drop distance to destination: ${Math.round(fallbackMatch.dropMatch.distance)}m`);
        }
        
        pickupMatch = fallbackMatch.pickupMatch;
        dropMatch = fallbackMatch.dropMatch;
        eta = fallbackMatch.eta;
      }
    } else {
      // NO POLYLINE - Use fallback distance-based matching
      const fallbackMatch = matchRideWithoutPolyline(ride, pickupLat, pickupLng, dropLat, dropLng, requestedTime);
      if (!fallbackMatch) {
        if (debug) console.log(`  ❌ REJECTED: Distance-based matching failed`);
        continue;
      }
      
      if (debug) {
        console.log(`  Using distance-based matching (no polyline):`);
        console.log(`    Pickup distance to origin: ${Math.round(fallbackMatch.pickupMatch.distance)}m`);
        console.log(`    Drop distance to destination: ${Math.round(fallbackMatch.dropMatch.distance)}m`);
      }
      
      pickupMatch = fallbackMatch.pickupMatch;
      dropMatch = fallbackMatch.dropMatch;
      eta = fallbackMatch.eta;
    }

    // MATCH FOUND
    if (debug) console.log(`  ✅ MATCHED!`);
    
    matches.push({
      ride: formatRide(
        ride,
        pickupLat,
        pickupLng,
        dropLat,
        dropLng,
        pickupMatch,
        dropMatch,
        eta,
        pickupName,
        dropName
      ),
      score: pickupMatch.distance
    });
  }

  // Sort best matches
  matches.sort((a, b) => a.score - b.score);

  const rides_list = matches.map(m => m.ride);

  if (debug) {
    console.log(`\n📊 RESULT: ${rides_list.length} rides matched\n`);
  }

  if (rides_list.length > 0) {
    return {
      type: "MATCH",
      message: `Found ${rides_list.length} ride(s)`,
      rides: rides_list
    };
  }

  return {
    type: "SOLO_SUGGESTION",
    message: "No shared rides available",
    soloRide: {
      origin: { lat: pickupLat, lng: pickupLng },
      destination: { lat: dropLat, lng: dropLng }
    }
  };
};