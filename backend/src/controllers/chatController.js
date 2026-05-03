const prisma = require("../lib/prisma");
const socketHub = require("../lib/socketHub");

// Send a message
exports.sendMessage = async (req, res) => {
  try {
    const { rideId, senderId, receiverId, content } = req.body;

    if (!rideId || !senderId || !receiverId || !content) {
      return res.status(400).json({ message: "rideId, senderId, receiverId, and content are required." });
    }

    const message = await prisma.rideMessage.create({
      data: {
        rideId: Number(rideId),
        senderId: Number(senderId),
        receiverId: Number(receiverId),
        content,
      },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    socketHub.emitRideMessage(message);

    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get message history for a 1-on-1 chat in a ride
exports.getRideMessages = async (req, res) => {
  try {
    const rideId = Number(req.params.rideId);
    const userId = Number(req.query.userId);
    const otherUserId = Number(req.query.otherUserId);

    if (!userId || !otherUserId) {
      return res.status(400).json({ message: "userId and otherUserId query parameters are required." });
    }

    const messages = await prisma.rideMessage.findMany({
      where: {
        rideId,
        OR: [
          { senderId: userId, receiverId: otherUserId },
          { senderId: otherUserId, receiverId: userId },
        ],
      },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: { createdAt: "asc" },
    });

    res.json(messages);
  } catch (error) {
    console.error("Error fetching messages:", error);
    res.status(500).json({ message: error.message });
  }
};

// Delete all messages for a ride (cleanup)
exports.deleteRideMessages = async (rideId) => {
  try {
    await prisma.rideMessage.deleteMany({
      where: { rideId: Number(rideId) },
    });
    console.log(`Chat history deleted for ride ${rideId}`);
  } catch (error) {
    console.error(`Failed to delete chat history for ride ${rideId}:`, error);
  }
};
