const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');
const { sendOtpEmail } = require('../lib/mailer');

exports.signup = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

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
        otp,
        otpExpiresAt,
      },
      create: {
        name,
        email,
        password: hashedPassword,
        role: role || 'PASSENGER',
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
    if (!user.isEmailVerified) {
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

    res.json({
      success: true,
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