const prisma = require("../lib/prisma");

// Get all active system messages
exports.getActiveMessages = async (req, res) => {
  try {
    const now = new Date();
    const messages = await prisma.systemMessage.findMany({
      where: {
        status: "ACTIVE",
        OR: [
          { expiresAt: null },
          { expiresAt: { gt: now } },
        ],
      },
      select: {
        id: true,
        type: true,
        title: true,
        content: true,
        createdAt: true,
        expiresAt: true,
        admin: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    res.json(messages);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all messages with filters (admin only)
exports.getAllMessages = async (req, res) => {
  try {
    const { type, status, limit = 50, offset = 0 } = req.query;

    const where = {};
    if (type && type !== "ALL") where.type = type;
    if (status) where.status = status;

    const messages = await prisma.systemMessage.findMany({
      where,
      select: {
        id: true,
        type: true,
        title: true,
        content: true,
        status: true,
        createdAt: true,
        expiresAt: true,
        admin: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: { createdAt: "desc" },
      take: parseInt(limit),
      skip: parseInt(offset),
    });

    const total = await prisma.systemMessage.count({ where });

    res.json({ messages, total });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Create a new system message
exports.createMessage = async (req, res) => {
  try {
    const { type, title, content, expiresAt, adminId } = req.body;

    // Validate required fields
    if (!type || !title || !content) {
      return res.status(400).json({ 
        message: "Missing required fields: type, title, content" 
      });
    }

    // Validate message type
    const validTypes = ["ANNOUNCEMENT", "ALERT", "MAINTENANCE"];
    if (!validTypes.includes(type)) {
      return res.status(400).json({ 
        message: `Invalid type. Must be one of: ${validTypes.join(", ")}` 
      });
    }

    // Check if admin exists
    if (adminId) {
      const admin = await prisma.user.findUnique({ where: { id: adminId } });
      if (!admin) {
        return res.status(404).json({ message: "Admin user not found" });
      }
    }

    const message = await prisma.systemMessage.create({
      data: {
        type,
        title,
        content,
        expiresAt: expiresAt ? new Date(expiresAt) : null,
        createdBy: adminId || 1, // Default to admin ID 1 if not provided
      },
      include: {
        admin: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    res.status(201).json({
      message: "System message created successfully",
      data: message,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update a system message
exports.updateMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const { type, title, content, expiresAt, status } = req.body;

    // Check if message exists
    const existingMessage = await prisma.systemMessage.findUnique({
      where: { id: parseInt(messageId) },
    });

    if (!existingMessage) {
      return res.status(404).json({ message: "Message not found" });
    }

    const updateData = {};
    if (type) updateData.type = type;
    if (title) updateData.title = title;
    if (content) updateData.content = content;
    if (status) updateData.status = status;
    if (expiresAt !== undefined) {
      updateData.expiresAt = expiresAt ? new Date(expiresAt) : null;
    }

    const updatedMessage = await prisma.systemMessage.update({
      where: { id: parseInt(messageId) },
      data: updateData,
      include: {
        admin: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    res.json({
      message: "Message updated successfully",
      data: updatedMessage,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Archive a message
exports.archiveMessage = async (req, res) => {
  try {
    const { messageId } = req.params;

    const message = await prisma.systemMessage.update({
      where: { id: parseInt(messageId) },
      data: { status: "ARCHIVED" },
      include: {
        admin: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    res.json({
      message: "Message archived successfully",
      data: message,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete a message
exports.deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;

    await prisma.systemMessage.delete({
      where: { id: parseInt(messageId) },
    });

    res.json({ message: "Message deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get message by ID
exports.getMessageById = async (req, res) => {
  try {
    const { messageId } = req.params;

    const message = await prisma.systemMessage.findUnique({
      where: { id: parseInt(messageId) },
      include: {
        admin: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    if (!message) {
      return res.status(404).json({ message: "Message not found" });
    }

    res.json(message);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
