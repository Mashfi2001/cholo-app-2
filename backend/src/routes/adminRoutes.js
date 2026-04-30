const express = require("express");
const router = express.Router();
const adminController = require("../controllers/adminController");

// Search users by ID or name
router.get("/users/search", adminController.searchUsers);

// Get all users with filters
router.get("/users", adminController.getAllUsers);

// Get user details
router.get("/users/:userId", adminController.getUserDetails);

// Suspend user temporarily
router.put("/users/:userId/suspend", adminController.suspendUser);

// Unsuspend user
router.put("/users/:userId/unsuspend", adminController.unsuspendUser);

// Delete user permanently
router.delete("/users/:userId", adminController.deleteUser);

module.exports = router;
