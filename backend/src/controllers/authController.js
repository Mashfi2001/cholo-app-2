const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');
const { sendOtpEmail, sendPasswordResetEmail } = require('../lib/mailer');
const {
  createSession,
  revokeSession,
  revokeAllSessions,
  listActiveSessions,
  purgeDeadSessions,
} = require('../lib/sessions');

const RESET_OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes

// Generic reply used by forgot-password so the endpoint cannot be used to
// discover which email addresses are registered.
const FORGOT_PASSWORD_MESSAGE =
  "If an account exists for that email, we've sent a password reset OTP to it.";

// Finds a verified, non-banned user that is allowed to reset its password.
// Returns null when no such user exists (unknown email, still-pending signup,
// or permanently banned account).
const findResettableUser = async (email) => {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !user.isEmailVerified || user.status === 'DELETED') return null;
  return user;
};

exports.signup = async (req, res) => {
  try {
    const { name, email, password, role, phone } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({ error: "Name, email, and password are required" });
    }

    // Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: "Invalid email format" });
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: "Email already registered" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

    // Create or update PendingUser
    const pendingUser = await prisma.pendingUser.upsert({
      where: { email },
      update: {
        name,
        password: hashedPassword,
        role: role || 'PASSENGER',
        phone: phone || null,
        otp,
        otpExpiresAt,
      },
      create: {
        name,
        email,
        password: hashedPassword,
        role: role || 'PASSENGER',
        phone: phone || null,
        otp,
        otpExpiresAt,
      }
    });

    // Send email
    await sendOtpEmail(email, otp);

    res.json({
      success: true,
      requiresOtp: true,
      message: "Registration successful. Please check your email for the OTP.",
      email: pendingUser.email
    });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: "Signup failed" });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    // Find user
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      // Check if they are in PendingUser
      const pendingUser = await prisma.pendingUser.findUnique({ where: { email } });
      if (pendingUser) {
        return res.status(403).json({ 
          error: "Email not verified. Please verify your email first.",
          requiresOtp: true,
          email: pendingUser.email
        });
      }
      return res.status(401).json({ error: "Invalid email or password" });
    }

    // Note: isEmailVerified check is no longer strictly needed here since unverified users 
    // are in PendingUser, but we keep it for backward compatibility with old records.
    if (!user.isEmailVerified && user.email !== 'admin1') {
      return res.status(403).json({ 
        error: "Email not verified. Please verify your email first.",
        requiresOtp: true,
        email: user.email
      });
    }

    // Check if user is permanently banned
    if (user.status === 'DELETED') {
      return res.status(403).json({ 
        error: "Your account has been permanently banned. You cannot login.", 
        banned: true,
        banType: "permanent"
      });
    }

    // Check if user is temporarily suspended
    if (user.status === 'SUSPENDED') {
      const now = new Date();
      if (user.suspendedUntil && new Date(user.suspendedUntil) > now) {
        const bannedUntil = new Date(user.suspendedUntil).toLocaleString();
        return res.status(403).json({ 
          error: `Your account is temporarily banned until ${bannedUntil}. Please try again later.`,
          banned: true,
          banType: "temporary",
          suspendedUntil: user.suspendedUntil
        });
      } else {
        // Suspension period is over, update status back to ACTIVE
        await prisma.user.update({
          where: { id: user.id },
          data: { status: 'ACTIVE', suspendedUntil: null }
        });
      }
    }

    // Check password
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: "Invalid email or password" });
    }

    // Issue a session for this device. Sessions already held by the same user
    // on other devices are left untouched, so multi-device login keeps working.
    const { token, session } = await createSession(user.id, req);

    // Opportunistic housekeeping; failures here never affect the login.
    purgeDeadSessions();

    res.json({
      success: true,
      token,
      expiresAt: session.expiresAt,
      sessionId: session.id,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: "Login failed" });
  }
};

/** Returns the account behind the caller's session token. */
exports.me = async (req, res) => {
  res.json({ success: true, user: req.user, sessionId: req.session.id });
};

/** Ends the calling device's session only; other devices stay signed in. */
exports.logout = async (req, res) => {
  try {
    await revokeSession(req.session.id);
    res.json({ success: true, message: "Logged out on this device." });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: "Failed to log out" });
  }
};

/** Lists the user's currently signed-in devices. */
exports.getSessions = async (req, res) => {
  try {
    const sessions = await listActiveSessions(req.user.id);
    res.json({
      success: true,
      currentSessionId: req.session.id,
      sessions: sessions.map((s) => ({ ...s, current: s.id === req.session.id })),
    });
  } catch (error) {
    console.error('List sessions error:', error);
    res.status(500).json({ error: "Failed to load sessions" });
  }
};

/**
 * Signs the user out everywhere. The calling device is kept unless the request
 * explicitly asks to be included.
 */
exports.logoutAll = async (req, res) => {
  try {
    const includeCurrent = req.body?.includeCurrent === true;
    const revoked = await revokeAllSessions(
      req.user.id,
      includeCurrent ? null : req.session.id
    );
    res.json({
      success: true,
      revoked,
      message: includeCurrent
        ? "Logged out on all devices."
        : "Logged out on all other devices.",
    });
  } catch (error) {
    console.error('Logout all error:', error);
    res.status(500).json({ error: "Failed to log out other devices" });
  }
};

/** Ends one specific session, so a user can drop a single lost device. */
exports.revokeSessionById = async (req, res) => {
  try {
    const sessionId = Number(req.params.id);
    if (!Number.isInteger(sessionId)) {
      return res.status(400).json({ error: "Invalid session id" });
    }

    // Scoped to the caller's own sessions so one user cannot end another's.
    const target = await prisma.session.findFirst({
      where: { id: sessionId, userId: req.user.id },
    });

    if (!target) {
      return res.status(404).json({ error: "Session not found" });
    }

    await revokeSession(target.id);
    res.json({ success: true, message: "Device signed out." });
  } catch (error) {
    console.error('Revoke session error:', error);
    res.status(500).json({ error: "Failed to sign out that device" });
  }
};

exports.getUserById = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        phone: true,
        status: true,
        createdAt: true,
      }
    });

    if (!user) {
      return res.status(404).json({ error: "User not found" });
    }

    res.json(user);
  } catch (error) {
    console.error('GetUserById error:', error);
    res.status(500).json({ error: "Failed to fetch user" });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ error: "Email and OTP are required" });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser && existingUser.isEmailVerified) {
      return res.status(400).json({ error: "Email is already verified. Please login." });
    }

    const pendingUser = await prisma.pendingUser.findUnique({ where: { email } });
    
    // Also handle old unverified records in the User table if they exist
    const userToVerify = pendingUser || existingUser;

    if (!userToVerify) {
      return res.status(404).json({ error: "Registration not found. Please sign up again." });
    }

    if (userToVerify.otp !== otp) {
      return res.status(400).json({ error: "Invalid OTP" });
    }

    if (new Date() > new Date(userToVerify.otpExpiresAt)) {
      return res.status(400).json({ error: "OTP has expired" });
    }

    if (pendingUser) {
      // Move from PendingUser to User
      await prisma.$transaction([
        prisma.user.create({
          data: {
            name: pendingUser.name,
            email: pendingUser.email,
            password: pendingUser.password,
            role: pendingUser.role,
            phone: pendingUser.phone,
            isEmailVerified: true,
            otp: null,
            otpExpiresAt: null,
          }
        }),
        prisma.pendingUser.delete({
          where: { id: pendingUser.id }
        })
      ]);
    } else {
      // Mark old unverified User as verified
      await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          isEmailVerified: true,
          otp: null,
          otpExpiresAt: null,
        },
      });
    }

    res.json({
      success: true,
      message: "Email verified successfully. You can now log in.",
    });
  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({ error: "Failed to verify OTP" });
  }
};

exports.resendOtp = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: "Email is required" });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser && existingUser.isEmailVerified) {
      return res.status(400).json({ error: "Email is already verified. Please login." });
    }

    const pendingUser = await prisma.pendingUser.findUnique({ where: { email } });
    const userToUpdate = pendingUser || existingUser;

    if (!userToUpdate) {
      return res.status(404).json({ error: "Registration not found. Please sign up again." });
    }

    // Generate new OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiresAt = new Date(Date.now() + 15 * 60 * 1000);

    if (pendingUser) {
      await prisma.pendingUser.update({
        where: { id: pendingUser.id },
        data: { otp, otpExpiresAt },
      });
    } else {
      await prisma.user.update({
        where: { id: existingUser.id },
        data: { otp, otpExpiresAt },
      });
    }

    await sendOtpEmail(email, otp);

    res.json({
      success: true,
      message: "A new OTP has been sent to your email.",
    });
  } catch (error) {
    console.error('Resend OTP error:', error);
    res.status(500).json({ error: "Failed to resend OTP" });
  }
};

// Step 1 of password reset: email an OTP to the account owner.
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: "Email is required" });
    }

    const user = await findResettableUser(email);

    // Always answer the same way, whether or not the account exists.
    if (!user) {
      console.warn(`Password reset requested for non-resettable email: ${email}`);
      return res.json({ success: true, message: FORGOT_PASSWORD_MESSAGE });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiresAt = new Date(Date.now() + RESET_OTP_TTL_MS);

    await prisma.user.update({
      where: { id: user.id },
      data: { otp, otpExpiresAt },
    });

    await sendPasswordResetEmail(email, otp);

    res.json({ success: true, message: FORGOT_PASSWORD_MESSAGE });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: "Failed to send password reset OTP" });
  }
};

// Step 2 of password reset: check the OTP before showing the new-password form.
// The OTP is left in place so it can be spent by resetPassword.
exports.verifyResetOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ error: "Email and OTP are required" });
    }

    const user = await findResettableUser(email);
    if (!user || !user.otp || !user.otpExpiresAt) {
      return res.status(400).json({ error: "Invalid or expired OTP" });
    }

    if (user.otp !== String(otp).trim()) {
      return res.status(400).json({ error: "Invalid OTP" });
    }

    if (new Date() > new Date(user.otpExpiresAt)) {
      return res.status(400).json({ error: "OTP has expired. Please request a new one." });
    }

    res.json({ success: true, message: "OTP verified. You can now set a new password." });
  } catch (error) {
    console.error('Verify reset OTP error:', error);
    res.status(500).json({ error: "Failed to verify OTP" });
  }
};

// Step 3 of password reset: re-check the OTP, then store the new password and
// clear the OTP so it cannot be reused.
exports.resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ error: "Email, OTP, and new password are required" });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ error: "Password must be at least 6 characters long" });
    }

    const user = await findResettableUser(email);
    if (!user || !user.otp || !user.otpExpiresAt) {
      return res.status(400).json({ error: "Invalid or expired OTP" });
    }

    if (user.otp !== String(otp).trim()) {
      return res.status(400).json({ error: "Invalid OTP" });
    }

    if (new Date() > new Date(user.otpExpiresAt)) {
      return res.status(400).json({ error: "OTP has expired. Please request a new one." });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashedPassword,
        otp: null,
        otpExpiresAt: null,
      },
    });

    // A reset is how a user locks out someone who got into their account, so
    // every existing device is signed out and must log in with the new password.
    const revokedSessions = await revokeAllSessions(user.id);

    res.json({
      success: true,
      revokedSessions,
      message: "Password reset successfully. You can now log in with your new password.",
    });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: "Failed to reset password" });
  }
};