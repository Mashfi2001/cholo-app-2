const express = require("express");
const router = express.Router();

const { searchRides } = require("../controllers/rideSearchController");

router.post("/search", searchRides);

module.exports = router;
