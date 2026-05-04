const express = require("express");
const router = express.Router();
const driverController = require("../controllers/driverController");

router.post("/:id/accept", driverController.acceptRequest);
router.post("/:id/reject", driverController.rejectRequest);

module.exports = router;
