const { PrismaClient } = require("@prisma/client");
const prisma = new PrismaClient();

exports.submitRating = async (req, res) => {
  const { rideId, userId, driverId, stars, comment } = req.body;

  if (!rideId || !userId || !driverId || !stars) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  if (stars < 1 || stars > 5) {
    return res.status(400).json({ error: "Stars must be between 1 and 5" });
  }

  try {
    const rating = await prisma.rating.upsert({
      where: {
        rideId_userId: {
          rideId: Number(rideId),
          userId: Number(userId),
        },
      },
      update: {
        stars: Number(stars),
        comment: comment || null,
      },
      create: {
        rideId: Number(rideId),
        userId: Number(userId),
        driverId: Number(driverId),
        stars: Number(stars),
        comment: comment || null,
      },
    });

    res.status(201).json({ message: "Rating submitted successfully", rating });
  } catch (error) {
    console.error("Error submitting rating:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};

exports.getDriverAverageRating = async (req, res) => {
  const driverId = Number(req.params.driverId);

  if (!driverId) {
    return res.status(400).json({ error: "driverId is required" });
  }

  try {
    const aggregate = await prisma.rating.aggregate({
      where: { driverId },
      _avg: {
        stars: true,
      },
      _count: {
        stars: true,
      },
    });

    res.json({
      averageRating: aggregate._avg.stars || 0,
      totalRatings: aggregate._count.stars || 0,
    });
  } catch (error) {
    console.error("Error fetching average rating:", error);
    res.status(500).json({ error: "Internal server error" });
  }
};
