const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');

exports.signup = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({ error: "Name, email, and password are required" });
    }

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: "Email already registered" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
        role: role || 'PASSENGER'
      }
    });

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
      return res.status(401).json({ error: "Invalid email or password" });
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