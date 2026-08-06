const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const { requireAuth } = require("../middleware/auth");

// Public: reachable without a session.
router.post("/signup", authController.signup);
router.post("/login", authController.login);
router.post("/verify-otp", authController.verifyOtp);
router.post("/resend-otp", authController.resendOtp);
router.post("/forgot-password", authController.forgotPassword);
router.post("/verify-reset-otp", authController.verifyResetOtp);
router.post("/reset-password", authController.resetPassword);

// Session management: needs a valid session token.
router.get("/me", requireAuth, authController.me);
router.post("/logout", requireAuth, authController.logout);
router.get("/sessions", requireAuth, authController.getSessions);
router.post("/logout-all", requireAuth, authController.logoutAll);
router.delete("/sessions/:id", requireAuth, authController.revokeSessionById);

// Keep last: this wildcard would otherwise swallow the routes above.
router.get("/:id", authController.getUserById);

module.exports = router;
