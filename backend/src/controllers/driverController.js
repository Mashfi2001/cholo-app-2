const prisma = require("../lib/prisma");

exports.getDriverStatus = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const user = await prisma.user.findUnique({
      where: { id },
      select: { isOnline: true }
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ isOnline: user.isOnline });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateDriverStatus = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { isOnline } = req.body;

    const user = await prisma.user.update({
      where: { id },
      data: { isOnline: Boolean(isOnline) },
      select: { isOnline: true }
    });

    res.json({ isOnline: user.isOnline });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getDriverVehicle = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const user = await prisma.user.findUnique({
      where: { id },
      select: { 
        vehicleModel: true, 
        vehiclePlate: true 
      }
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json({ 
      vehicle: { 
        model: user.vehicleModel || "Not set", 
        plateNumber: user.vehiclePlate || "Not set" 
      } 
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getAllRequests = async (req, res) => {
  try {
    const driverId = Number(req.params.id);
    const requests = await prisma.bookingRequest.findMany({
      where: {
        ride: { driverId }
      },
      include: {
        passenger: true,
        ride: true
      }
    });

    const result = {
      pending: requests.filter(r => r.status === "PENDING"),
      confirmed: requests.filter(r => r.status === "ACCEPTED"),
      past: requests.filter(r => r.status === "REJECTED" || r.status === "CANCELLED")
    };

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.acceptRequest = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const request = await prisma.bookingRequest.update({
      where: { id },
      data: { status: "ACCEPTED" }
    });
    res.json(request);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.rejectRequest = async (req, res) => {
  try {
    const id = Number(req.params.id);
    const request = await prisma.bookingRequest.update({
      where: { id },
      data: { status: "REJECTED" }
    });
    res.json(request);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getPendingRequestsCount = async (req, res) => {
  try {
    const driverId = Number(req.params.id);
    const count = await prisma.bookingRequest.count({
      where: {
        ride: { driverId },
        status: "PENDING"
      }
    });
    res.json({ count });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

