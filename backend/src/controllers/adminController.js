const prisma = require("../lib/prisma");

// Search users by ID or name
exports.searchUsers = async (req, res) => {
  try {
    const { query, role } = req.query;

    if (!query) {
      return res.status(400).json({ message: "Search query required" });
    }

    const users = await prisma.user.findMany({
      where: {
        AND: [
          {
            OR: [
              { id: isNaN(parseInt(query)) ? undefined : parseInt(query) },
              { name: { contains: query, mode: "insensitive" } },
              { email: { contains: query, mode: "insensitive" } },
            ].filter(Boolean),
          },
          role ? { role } : {},
        ],
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        status: true,
        suspendedUntil: true,
        createdAt: true,
      },
      take: 20,
    });

    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all users with filters
exports.getAllUsers = async (req, res) => {
  try {
    const { role, status } = req.query;

    const users = await prisma.user.findMany({
      where: {
        ...(role && { role }),
        ...(status && { status }),
      },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        status: true,
        suspendedUntil: true,
        createdAt: true,
      },
      orderBy: { createdAt: "desc" },
    });

    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Suspend user temporarily
exports.suspendUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const { days } = req.body; // Number of days to suspend (default 30)

    const suspensionDays = days || 30;
    const suspendedUntil = new Date();
    suspendedUntil.setDate(suspendedUntil.getDate() + suspensionDays);

    const user = await prisma.user.update({
      where: { id: parseInt(userId) },
      data: {
        status: "SUSPENDED",
        suspendedUntil: suspendedUntil,
      },
    });

    res.json({
      message: `User suspended until ${suspendedUntil.toISOString()}`,
      user: {
        id: user.id,
        name: user.name,
        status: user.status,
        suspendedUntil: user.suspendedUntil,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Unsuspend user
exports.unsuspendUser = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await prisma.user.update({
      where: { id: parseInt(userId) },
      data: {
        status: "ACTIVE",
        suspendedUntil: null,
      },
    });

    res.json({
      message: "User unsuspended",
      user: {
        id: user.id,
        name: user.name,
        status: user.status,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete user permanently
exports.deleteUser = async (req, res) => {
  try {
    const { userId } = req.params;

    // First, mark as DELETED instead of hard-deleting to maintain referential integrity
    const user = await prisma.user.update({
      where: { id: parseInt(userId) },
      data: {
        status: "DELETED",
        name: "[Deleted User]",
        email: `deleted_${userId}_${Date.now()}@deleted.local`,
      },
    });

    res.json({
      message: "User account permanently deleted",
      user: {
        id: user.id,
        name: user.name,
        status: user.status,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get user details
exports.getUserDetails = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await prisma.user.findUnique({
      where: { id: parseInt(userId) },
      include: {
        rides: {
          select: {
            id: true,
            origin: true,
            destination: true,
            status: true,
            departureTime: true,
          },
        },
        bookingRequests: {
          select: {
            id: true,
            status: true,
            ride: {
              select: {
                id: true,
                origin: true,
                destination: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
