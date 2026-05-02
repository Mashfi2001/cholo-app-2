const express = require("express");
const router = express.Router();
const seatBookingController = require("../controllers/seatBookingController");

router.get("/:rideId/seats", seatBookingController.getSeatsByRide);
router.post("/", seatBookingController.createSeatBooking);
router.get("/driver/:driverId/requests", seatBookingController.getPendingRequestsForDriver);
router.post(
  "/requests/:rideId/:passengerId/decision",
  seatBookingController.decideSeatBookingRequest
);
router.post("/:rideId/complete-payment", seatBookingController.completePayment);

module.exports = router;
