const prisma = require("../lib/prisma");

// Create a new broadcast message
exports.createBroadcast = async (req, res) => {
  try {
    const { title, content, type, expiresAt } = req.body;

    if (!title || !content || !type) {
      return res.status(400).json({ message: "Title, content, and type are required" });
    }

    const validTypes = ["ANNOUNCEMENT", "ALERT", "MAINTENANCE"];
    if (!validTypes.includes(type)) {
      return res.status(400).json({ message: "Invalid broadcast type" });
    }

    const broadcast = await prisma.broadcastMessage.create({
      data: {
        title,
        content,
        type,
        active: true,
        expiresAt: expiresAt ? new Date(expiresAt) : null,
      },
    });

    res.status(201).json(broadcast);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all broadcast messages (admin)
exports.getAllBroadcasts = async (req, res) => {
  try {
    const broadcasts = await prisma.broadcastMessage.findMany({
      orderBy: { createdAt: "desc" },
    });

    res.json(broadcasts);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get active broadcasts (public - for users/drivers)
exports.getActiveBroadcasts = async (req, res) => {
  try {
    const now = new Date();

    const broadcasts = await prisma.broadcastMessage.findMany({
      where: {
        active: true,
        OR: [
          { expiresAt: null },
          { expiresAt: { gt: now } },
        ],
      },
      orderBy: { createdAt: "desc" },
    });

    res.json(broadcasts);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Toggle broadcast active status
exports.toggleBroadcast = async (req, res) => {
  try {
    const { id } = req.params;

    const existing = await prisma.broadcastMessage.findUnique({
      where: { id: parseInt(id) },
    });

    if (!existing) {
      return res.status(404).json({ message: "Broadcast not found" });
    }

    const broadcast = await prisma.broadcastMessage.update({
      where: { id: parseInt(id) },
      data: { active: !existing.active },
    });

    res.json(broadcast);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete broadcast
exports.deleteBroadcast = async (req, res) => {
  try {
    const { id } = req.params;

    await prisma.broadcastMessage.delete({
      where: { id: parseInt(id) },
    });

    res.json({ message: "Broadcast deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

