const express = require("express");
const router = express.Router();
const broadcastController = require("../controllers/broadcastController");

// Public: get active broadcasts
router.get("/active", broadcastController.getActiveBroadcasts);

// Admin: get all broadcasts
router.get("/", broadcastController.getAllBroadcasts);

// Admin: create broadcast
router.post("/", broadcastController.createBroadcast);

// Admin: toggle broadcast active status
router.put("/:id/toggle", broadcastController.toggleBroadcast);

// Admin: delete broadcast
router.delete("/:id", broadcastController.deleteBroadcast);

module.exports = router;

