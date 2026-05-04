const express = require("express");
const router = express.Router();
const driverController = require("../controllers/driverController");

router.get("/:id/status", driverController.getDriverStatus);
router.post("/:id/status", driverController.updateDriverStatus);
router.get("/:id/vehicle", driverController.getDriverVehicle);
router.get("/:id/all-requests", driverController.getAllRequests);
router.get("/:id/pending-requests-count", driverController.getPendingRequestsCount);


module.exports = router;


