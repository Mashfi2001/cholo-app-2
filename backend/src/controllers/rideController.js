const prisma = require("../lib/prisma");

exports.createRide = async (req, res) => {
  try {
    const { driverId, origin, destination, departureTime, seats } = req.body;

    if (!driverId || !origin || !destination || !departureTime || !seats) {
      return res.status(400).json({ message: "All fields are required." });
    }

    const ride = await prisma.ride.create({
      data: {
        driverId: Number(driverId),
        origin,
        destination,
        departureTime: new Date(departureTime),
        seats: Number(seats),
        status: "PLANNED",
      },
    });

    res.status(201).json({
      message: "Ride created successfully",
      ride,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getRideById = async (req, res) => {
  try {
    const id = Number(req.params.id);

    const ride = await prisma.ride.findUnique({
      where: { id },
    });

    if (!ride) {
      return res.status(404).json({ message: "Ride not found" });
    }

    res.json(ride);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateRideRoute = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { origin, destination, departureTime, seats } = req.body;

    const existingRide = await prisma.ride.findUnique({
      where: { id },
    });

    if (!existingRide) {
      return res.status(404).json({ message: "Ride not found" });
    }

    if (existingRide.status !== "PLANNED") {
      return res.status(400).json({
        message: "Route can only be changed before departure.",
      });
    }

    const updatedRide = await prisma.ride.update({
      where: { id },
      data: {
        origin: origin ?? existingRide.origin,
        destination: destination ?? existingRide.destination,
        departureTime: departureTime
          ? new Date(departureTime)
          : existingRide.departureTime,
        seats: seats ? Number(seats) : existingRide.seats,
      },
    });

    res.json({
      message: "Ride route updated successfully",
      ride: updatedRide,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.cancelRide = async (req, res) => {
  try {
    const id = Number(req.params.id);

    const existingRide = await prisma.ride.findUnique({
      where: { id },
    });

    if (!existingRide) {
      return res.status(404).json({ message: "Ride not found" });
    }

    if (existingRide.status !== "PLANNED") {
      return res.status(400).json({
        message: "Ride can only be cancelled before departure.",
      });
    }

    const cancelledRide = await prisma.ride.update({
      where: { id },
      data: {
        status: "CANCELLED",
      },
    });

    res.json({
      message: "Ride cancelled successfully",
      ride: cancelledRide,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.startRide = async (req, res) => {
  try {
    const id = Number(req.params.id);

    const existingRide = await prisma.ride.findUnique({
      where: { id },
    });

    if (!existingRide) {
      return res.status(404).json({ message: "Ride not found" });
    }

    if (existingRide.status !== "PLANNED") {
      return res.status(400).json({
        message: "Only a planned ride can be started.",
      });
    }

    const startedRide = await prisma.ride.update({
      where: { id },
      data: {
        status: "ONGOING",
      },
    });

    res.json({
      message: "Ride started successfully",
      ride: startedRide,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};