const express = require("express");
const router = express.Router();
const ratingController = require("../controllers/ratingController");

router.post("/", ratingController.submitRating);
router.get("/driver/:driverId/average", ratingController.getDriverAverageRating);

module.exports = router;
