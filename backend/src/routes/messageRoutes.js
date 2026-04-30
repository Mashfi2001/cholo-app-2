const express = require("express");
const router = express.Router();
const messageController = require("../controllers/messageController");

// Get all active messages (for all users)
router.get("/active", messageController.getActiveMessages);

// Get all messages with filters (admin only)
router.get("/", messageController.getAllMessages);

// Get specific message by ID
router.get("/:messageId", messageController.getMessageById);

// Create new message (admin only)
router.post("/", messageController.createMessage);

// Update message (admin only)
router.put("/:messageId", messageController.updateMessage);

// Archive message (admin only)
router.patch("/:messageId/archive", messageController.archiveMessage);

// Delete message (admin only)
router.delete("/:messageId", messageController.deleteMessage);

module.exports = router;
