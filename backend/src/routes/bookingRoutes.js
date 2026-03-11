const express = require("express");
const router = express.Router();
const bookingController = require("../controllers/bookingController");

router.post("/", bookingController.createBookingRequest);
router.get("/ride/:rideId", bookingController.getBookingRequestsByRide);
router.put("/:id/accept", bookingController.acceptBookingRequest);
router.put("/:id/reject", bookingController.rejectBookingRequest);

module.exports = router;