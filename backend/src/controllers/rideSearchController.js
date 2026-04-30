const rideSearchService = require("../services/rideSearchService");

exports.searchRides = async (req, res) => {
  try {
    const {
      pickupLat,
      pickupLng,
      dropLat,
      dropLng,
      requestedTime,
      pickupName,
      dropName,
      debug
    } = req.body;

    const result = await rideSearchService.findRides({
      pickupLat,
      pickupLng,
      dropLat,
      dropLng,
      pickupName,
      dropName,
      requestedTime
    }, debug === true);

    res.json(result);

  } catch (error) {
    res.status(500).json({
      message: error.message
    });
  }
};
