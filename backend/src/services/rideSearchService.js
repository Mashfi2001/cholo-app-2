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
// MAIN SEARCH ENGINE
// -------------------------------
exports.findRides = async ({
  pickupLat,
  pickupLng,
  dropLat,
  dropLng,
  requestedTime
}, debug = false) => {

  const rides = await prisma.ride.findMany({
    where: {
      status: "PLANNED"
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

    // 1. TIME CHECK - must be within 90 minutes
    const timeDiffMs = Math.abs(new Date(ride.departureTime) - new Date(requestedTime));
    const timeDiffMins = timeDiffMs / (1000 * 60);

    if (timeDiffMins > 90) {
      if (debug) console.log(`❌ Ride ${ride.id}: Time diff=${timeDiffMins.toFixed(1)}min > 90min`);
      continue;
    }

    // Calculate all key distances
    const pickupToOrigin = getDistance(pickupLat, pickupLng, ride.originLat, ride.originLng);
    const pickupToDest = getDistance(pickupLat, pickupLng, ride.destinationLat, ride.destinationLng);
    const dropToOrigin = getDistance(dropLat, dropLng, ride.originLat, ride.originLng);
    const dropToDest = getDistance(dropLat, dropLng, ride.destinationLat, ride.destinationLng);
    const rideDistance = getDistance(ride.originLat, ride.originLng, ride.destinationLat, ride.destinationLng);

    if (debug) {
      console.log(`Ride ${ride.id}:`);
      console.log(`  Driver route: (${ride.originLat.toFixed(5)}, ${ride.originLng.toFixed(5)}) → (${ride.destinationLat.toFixed(5)}, ${ride.destinationLng.toFixed(5)}), distance=${rideDistance.toFixed(0)}m`);
      console.log(`  Passenger: pickup(${pickupLat.toFixed(5)}, ${pickupLng.toFixed(5)}) → drop(${dropLat.toFixed(5)}, ${dropLng.toFixed(5)})`);
      console.log(`  pickupToOrigin=${pickupToOrigin.toFixed(0)}m, pickupToDest=${pickupToDest.toFixed(0)}m`);
      console.log(`  dropToOrigin=${dropToOrigin.toFixed(0)}m, dropToDest=${dropToDest.toFixed(0)}m`);
    }

    // 2. CHECK: Both pickup and drop should be reasonably close to the driver's route
    // This allows pickup/drop anywhere along the route corridor
    const maxDistToRoute = 3000; // 3km tolerance to the route
    
    const pickupCloseToRoute = Math.min(pickupToOrigin, pickupToDest) <= maxDistToRoute;
    const dropCloseToRoute = Math.min(dropToOrigin, dropToDest) <= maxDistToRoute;

    if (!pickupCloseToRoute) {
      if (debug) console.log(`  ❌ Pickup too far from route (min dist=${Math.min(pickupToOrigin, pickupToDest).toFixed(0)}m > ${maxDistToRoute}m)`);
      continue;
    }

    if (!dropCloseToRoute) {
      if (debug) console.log(`  ❌ Drop too far from route (min dist=${Math.min(dropToOrigin, dropToDest).toFixed(0)}m > ${maxDistToRoute}m)`);
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
      ride: formatRide(ride, pickupToOrigin, dropToDest, requestedTime),
      pickupDist: pickupToOrigin
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
      origin: { lat: pickupLat, lng: pickupLng },
      destination: { lat: dropLat, lng: dropLng },
      estimatedType: "PRIVATE_RIDE"
    },
    mapConfig: getMapConfig("SOLO_SUGGESTION")
  };
};

// -------------------------------
// FORMAT FOR FLUTTER MAP
// -------------------------------
function formatRide(ride, pickupDist, dropDist, requestedTime) {
  return {
    id: ride.id,
    origin: {
      lat: ride.originLat,
      lng: ride.originLng
    },
    destination: {
      lat: ride.destinationLat,
      lng: ride.destinationLng
    },
    departureTime: ride.departureTime,
    requestedTime: requestedTime,
    seats: ride.seats,

    pickupMarker: {
      lat: ride.originLat,
      lng: ride.originLng
    },
    dropMarker: {
      lat: ride.destinationLat,
      lng: ride.destinationLng
    },

    meta: {
      pickupDistance: Math.round(pickupDist),
      dropDistance: Math.round(dropDist)
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