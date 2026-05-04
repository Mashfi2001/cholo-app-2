const prisma = require("../lib/prisma");
const stripe = process.env.STRIPE_SECRET_KEY ? require("stripe")(process.env.STRIPE_SECRET_KEY) : null;

const {
  passengerFareForRide,
  billableDistanceKmForRide,
  RATE_PER_KM,
  MIN_TRIP_KM,
} = require("./fareController");
const socketHub = require("../lib/socketHub");
const PENDING_APPROVAL_MARKER = "__PENDING_DRIVER_APPROVAL__";

const parseSeatNumbers = (input) => {
  if (!Array.isArray(input)) return [];
  return [...new Set(input.map((value) => Number(value)).filter(Number.isInteger))];
};

exports.getSeatsByRide = async (req, res) => {
  const rideId = Number(req.params.rideId);
  const userId = req.query.userId ? Number(req.query.userId) : null;

  if (!Number.isInteger(rideId)) {
    return res.status(400).json({ error: "Invalid rideId" });
  }

  try {
    const ride = await prisma.ride.findUnique({
      where: { id: rideId },
      select: {
        seats: true,
        totalFare: true,
        originLat: true,
        originLng: true,
        destinationLat: true,
        destinationLng: true,
        routeDistanceKm: true,
      },
    });

    if (!ride) {
      return res.status(404).json({ error: "Ride not found" });
    }

    let unitPassengerFare = null;
    let billableDistanceKm = null;
    
    // Extract passenger coordinates from query params
    const passengerCoords = {
      pickupLat: req.query.pickupLat ? Number(req.query.pickupLat) : null,
      pickupLng: req.query.pickupLng ? Number(req.query.pickupLng) : null,
      dropLat: req.query.dropLat ? Number(req.query.dropLat) : null,
      dropLng: req.query.dropLng ? Number(req.query.dropLng) : null,
    };

    try {
      unitPassengerFare = passengerFareForRide(ride, passengerCoords);
      billableDistanceKm = billableDistanceKmForRide(ride, passengerCoords);
    } catch (e) {
      if (e.code !== "NO_DISTANCE_FOR_FARE") throw e;
    }

    const activeBookings = await prisma.seatBooking.findMany({
      where: { rideId, paidAt: null },
      include: {
        user: { select: { id: true, name: true, email: true } },
      },
    });

    const paidBookings = await prisma.seatBooking.findMany({
      where: { rideId, paidAt: { not: null } },
      include: {
        user: { select: { id: true, name: true } },
      },
      orderBy: { paidAt: "desc" },
    });

    const bookingBySeat = new Map(activeBookings.map((booking) => [booking.seatNo, booking]));
    const seats = Array.from({ length: ride.seats }, (_, index) => {
      const seatNo = index + 1;
      const booking = bookingBySeat.get(seatNo);
      const isMine = Boolean(userId && booking?.userId === userId);
      const isPending = booking?.paymentMethod === PENDING_APPROVAL_MARKER;

      if (!booking) {
        return { seatNo, state: "AVAILABLE", isMine: false, passenger: null, fare: null };
      }

      return {
        seatNo,
        state: isPending
          ? isMine
            ? "PENDING_BY_ME"
            : "PENDING"
          : isMine
          ? "BOOKED_BY_ME"
          : "BOOKED",
        isMine,
        isPending,
        fare: booking.fare,
        passenger: {
          id: booking.user.id,
          name: booking.user.name,
          email: booking.user.email,
        },
      };
    });

    const gotTotalMoney = paidBookings.reduce((sum, item) => sum + Math.ceil(Number(item.fare) || 0), 0);
    const breakdownByPassenger = new Map();
    for (const item of paidBookings) {
      const current = breakdownByPassenger.get(item.userId) || {
        userId: item.userId,
        passengerName: item.user?.name || `P${item.userId}`,
        amount: 0,
      };
      current.amount += Math.ceil(Number(item.fare) || 0);
      breakdownByPassenger.set(item.userId, current);
    }

    return res.json({
      totalSeats: ride.seats,
      totalFare: ride.totalFare,
      gotTotalMoney,
      paidBreakdown: Array.from(breakdownByPassenger.values()).sort((a, b) => b.amount - a.amount),
      unitPassengerFare,
      billableDistanceKm,
      fareRatePerKm: RATE_PER_KM,
      minBillableKm: MIN_TRIP_KM,
      seats,
      bookedSeats: activeBookings.map((booking) => booking.seatNo),
      myBookedSeats: userId
        ? activeBookings
            .filter((booking) => booking.userId === userId && booking.paymentMethod !== PENDING_APPROVAL_MARKER)
            .map((booking) => booking.seatNo)
        : [],
      myPendingSeats: userId
        ? activeBookings
            .filter((booking) => booking.userId === userId && booking.paymentMethod === PENDING_APPROVAL_MARKER)
            .map((booking) => booking.seatNo)
        : [],
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Internal server error" });
  }
};

exports.createSeatBooking = async (req, res) => {
  const rideId = Number(req.body.rideId);
  const userId = Number(req.body.userId);
  const seatNumbers = parseSeatNumbers(req.body.seats ?? [req.body.seatNo]);

  if (!Number.isInteger(rideId) || !Number.isInteger(userId)) {
    return res.status(400).json({ error: "rideId and userId are required" });
  }
  if (!seatNumbers.length) {
    return res.status(400).json({ error: "At least one seat must be selected" });
  }

  try {
    const payload = await prisma.$transaction(async (tx) => {
      const ride = await tx.ride.findUnique({
        where: { id: rideId },
        select: {
          id: true,
          seats: true,
          originLat: true,
          originLng: true,
          destinationLat: true,
          destinationLng: true,
          routeDistanceKm: true,
        },
      });

      if (!ride) throw new Error("RIDE_NOT_FOUND");

      const outOfRangeSeat = seatNumbers.find((seatNo) => seatNo < 1 || seatNo > ride.seats);
      if (outOfRangeSeat) throw new Error("INVALID_SEAT_NUMBER");

      const existingUserBookings = await tx.seatBooking.findMany({
        where: { rideId, userId, paidAt: null },
        select: { seatNo: true },
      });
      if (existingUserBookings.length > 0) throw new Error("USER_ALREADY_BOOKED");

      const conflictingBookings = await tx.seatBooking.findMany({
        where: { rideId, paidAt: null, seatNo: { in: seatNumbers } },
        select: { seatNo: true },
      });
      if (conflictingBookings.length > 0) {
        const conflictError = new Error("SEAT_ALREADY_BOOKED");
        conflictError.conflictSeatNos = conflictingBookings.map((booking) => booking.seatNo);
        throw conflictError;
      }

      let unitFare;
      
      // Extract passenger coordinates from request body
      const passengerCoords = {
        pickupLat: req.body.pickupLat ? Number(req.body.pickupLat) : null,
        pickupLng: req.body.pickupLng ? Number(req.body.pickupLng) : null,
        dropLat: req.body.dropLat ? Number(req.body.dropLat) : null,
        dropLng: req.body.dropLng ? Number(req.body.dropLng) : null,
      };

      try {
        unitFare = passengerFareForRide(ride, passengerCoords);
      } catch (e) {
        if (e.code === "NO_DISTANCE_FOR_FARE") throw new Error("NO_DISTANCE_FOR_FARE");
        throw e;
      }

      const bookingTotal = unitFare * seatNumbers.length;
      const rideWithDriver = await tx.ride.findUnique({
        where: { id: rideId },
        select: { driverId: true, origin: true, destination: true },
      });
      if (!rideWithDriver) throw new Error("RIDE_NOT_FOUND");
      await tx.seatBooking.createMany({
        data: seatNumbers.map((seatNo) => ({
          rideId,
          userId,
          seatNo,
          fare: unitFare,
          paymentMethod: PENDING_APPROVAL_MARKER,
          paymentPhone: null,
          paidAt: null,
        })),
      });
      const passenger = await tx.user.findUnique({
        where: { id: userId },
        select: { name: true },
      });
      await tx.notification.create({
        data: {
          userId: rideWithDriver.driverId,
          type: "INFO",
          title: "New seat booking request",
          message: `${passenger?.name || "A passenger"} requested seat ${seatNumbers.sort((a, b) => a - b).join(", ")} for ${rideWithDriver.origin} -> ${rideWithDriver.destination}.`,
        },
      });

      return {
        seats: seatNumbers,
        unitFare,
        bookingTotal,
        rideTotalFare: null,
      };
    });

    return res.status(201).json({
      message: "Seat booking request sent. Waiting for driver approval.",
      seats: payload.seats,
      unitFare: payload.unitFare,
      bookingTotal: payload.bookingTotal,
      rideTotalFare: payload.rideTotalFare,
    });
  } catch (e) {
    if (e.message === "RIDE_NOT_FOUND") return res.status(404).json({ error: "Ride not found" });
    if (e.message === "INVALID_SEAT_NUMBER") {
      return res.status(400).json({ error: "One or more seat numbers are invalid" });
    }
    if (e.message === "USER_ALREADY_BOOKED") {
      return res.status(409).json({
        error: "You already confirmed booking for this ride. Seats cannot be changed.",
      });
    }
    if (e.message === "SEAT_ALREADY_BOOKED") {
      return res.status(409).json({
        error: "One or more selected seats are already booked",
        seats: e.conflictSeatNos ?? [],
      });
    }
    if (e.message === "NO_DISTANCE_FOR_FARE") {
      return res.status(400).json({
        error: "Ride has no usable distance data (coordinates or route distance). Cannot compute fare.",
      });
    }
    console.error(e);
    return res.status(500).json({ error: "Internal server error" });
  }
};

exports.completePayment = async (req, res) => {
  const rideId = Number(req.params.rideId);
  const userId = Number(req.body.userId);
  const paymentMethod = String(req.body.paymentMethod || "").toLowerCase();
  const paymentPhone = String(req.body.paymentPhone || "").trim();
  const allowedMethods = ["cash", "bkash", "nagad", "stripe"];

  if (!Number.isInteger(rideId) || !Number.isInteger(userId)) {
    return res.status(400).json({ error: "rideId and userId are required" });
  }
  if (!allowedMethods.includes(paymentMethod)) {
    return res.status(400).json({ error: "Invalid payment method" });
  }
  if (paymentMethod !== "cash" && !/^\d{11}$/.test(paymentPhone)) {
    return res.status(400).json({ error: "Valid 11-digit phone number is required" });
  }

  try {
    const payload = await prisma.$transaction(async (tx) => {
      const myBookings = await tx.seatBooking.findMany({
        where: { rideId, userId, paidAt: null, paymentMethod: null },
        select: { id: true, seatNo: true, fare: true },
        orderBy: { seatNo: "asc" },
      });
      if (!myBookings.length) throw new Error("NO_ACTIVE_BOOKINGS");

      const payableAmount = myBookings.reduce((sum, b) => sum + Math.ceil(Number(b.fare) || 0), 0);
      const bookingIds = myBookings.map((b) => b.id);

      // Call external payment API (Stripe) for non-cash payments
      if (paymentMethod !== "cash") {
        try {
          // Stripe expects amount in cents (or smallest currency unit)
          // We'll use 'bdt' as currency to match the local context
          if (!stripe) {
            throw new Error("STRIPE_NOT_CONFIGURED");
          }
          const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(payableAmount * 100),
            currency: "bdt",
            payment_method_types: ["card"],
            description: `Ride ${rideId} payment for user ${userId}`,
            metadata: {
              rideId: rideId.toString(),
              userId: userId.toString(),
              seats: myBookings.map((b) => b.seatNo).join(","),
            },
          });
          console.log(`Stripe Payment Intent created: ${paymentIntent.id}`);
        } catch (stripeErr) {
          console.error("Stripe Error:", stripeErr);
          throw new Error("EXTERNAL_PAYMENT_FAILED");
        }
      }

      const now = new Date();


      await tx.seatBooking.updateMany({
        where: { id: { in: bookingIds } },
        data: {
          paymentMethod,
          paymentPhone: paymentMethod === "cash" ? null : paymentPhone,
          paidAt: now,
        },
      });

      const updatedRide = await tx.ride.update({
        where: { id: rideId },
        data: { totalFare: { decrement: payableAmount } },
        select: { totalFare: true },
      });

      return {
        payableAmount,
        seats: myBookings.map((b) => b.seatNo),
        rideTotalFare: Math.max(0, Math.ceil(Number(updatedRide.totalFare) || 0)),
      };
    });

    socketHub.emitFareUpdate({ rideId, totalFare: payload.rideTotalFare });
    return res.json({
      message: "Payment completed and seats released",
      rideId,
      userId,
      paymentMethod,
      payableAmount: payload.payableAmount,
      seats: payload.seats,
      rideTotalFare: payload.rideTotalFare,
    });
  } catch (err) {
    if (err.message === "NO_ACTIVE_BOOKINGS") {
      return res.status(404).json({ error: "No active booked seats found for this passenger" });
    }
    if (err.message === "EXTERNAL_PAYMENT_FAILED") {
      return res.status(402).json({ error: "External payment failed. Please try again." });
    }
    if (err.message === "STRIPE_NOT_CONFIGURED") {
      return res.status(503).json({ error: "Stripe payment is not configured on this server." });
    }

    console.error(err);
    return res.status(500).json({ error: "Internal server error" });
  }
};

exports.getPendingRequestsForDriver = async (req, res) => {
  const driverId = Number(req.params.driverId);
  if (!Number.isInteger(driverId)) {
    return res.status(400).json({ error: "Invalid driverId" });
  }

  try {
    const pendingBookings = await prisma.seatBooking.findMany({
      where: {
        paidAt: null,
        paymentMethod: PENDING_APPROVAL_MARKER,
        ride: { driverId },
      },
      include: {
        user: { select: { id: true, name: true, email: true } },
        ride: { select: { id: true, origin: true, destination: true } },
      },
      orderBy: { createdAt: "asc" },
    });

    const requestMap = new Map();
    for (const booking of pendingBookings) {
      const key = `${booking.rideId}:${booking.userId}`;
      if (!requestMap.has(key)) {
        requestMap.set(key, {
          rideId: booking.rideId,
          passengerId: booking.userId,
          passengerName: booking.user?.name || "Passenger",
          passengerEmail: booking.user?.email || "",
          origin: booking.ride.origin,
          destination: booking.ride.destination,
          seatNumbers: [],
          requestedAt: booking.createdAt,
          totalFare: 0,
        });
      }
      const current = requestMap.get(key);
      current.seatNumbers.push(booking.seatNo);
      current.totalFare += Math.ceil(Number(booking.fare) || 0);
      if (booking.createdAt < current.requestedAt) current.requestedAt = booking.createdAt;
    }

    const requests = Array.from(requestMap.values())
      .map((item) => ({
        ...item,
        seatNumbers: item.seatNumbers.sort((a, b) => a - b),
      }))
      .sort((a, b) => new Date(a.requestedAt) - new Date(b.requestedAt));

    return res.json({ requests });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Failed to fetch pending requests" });
  }
};

exports.decideSeatBookingRequest = async (req, res) => {
  const rideId = Number(req.params.rideId);
  const passengerId = Number(req.params.passengerId);
  const driverId = Number(req.body.driverId);
  const decision = String(req.body.decision || "").toUpperCase();

  if (!Number.isInteger(rideId) || !Number.isInteger(passengerId) || !Number.isInteger(driverId)) {
    return res.status(400).json({ error: "rideId, passengerId and driverId are required" });
  }
  if (!["ACCEPT", "REJECT"].includes(decision)) {
    return res.status(400).json({ error: "decision must be ACCEPT or REJECT" });
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
      const ride = await tx.ride.findUnique({
        where: { id: rideId },
        select: { id: true, driverId: true, origin: true, destination: true, totalFare: true },
      });
      if (!ride) throw new Error("RIDE_NOT_FOUND");
      if (ride.driverId !== driverId) throw new Error("FORBIDDEN");

      const pending = await tx.seatBooking.findMany({
        where: {
          rideId,
          userId: passengerId,
          paidAt: null,
          paymentMethod: PENDING_APPROVAL_MARKER,
        },
        select: { id: true, seatNo: true, fare: true },
      });
      if (!pending.length) throw new Error("NO_PENDING_REQUEST");

      const seatNumbers = pending.map((item) => item.seatNo).sort((a, b) => a - b);
      const bookingTotal = pending.reduce((sum, item) => sum + (Number(item.fare) || 0), 0);
      const bookingIds = pending.map((item) => item.id);

      if (decision === "ACCEPT") {
        await tx.seatBooking.updateMany({
          where: { id: { in: bookingIds } },
          data: { paymentMethod: null },
        });
        const updatedRide = await tx.ride.update({
          where: { id: rideId },
          data: { totalFare: { increment: bookingTotal } },
          select: { totalFare: true },
        });
        await tx.notification.create({
          data: {
            userId: passengerId,
            type: "SUCCESS",
            title: "Seat request approved",
            message: `Driver approved your seat request for ${ride.origin} -> ${ride.destination}. Seats ${seatNumbers.join(", ")} are now confirmed.`,
          },
        });
        return {
          decision,
          seatNumbers,
          bookingTotal: Math.ceil(bookingTotal),
          rideTotalFare: Math.ceil(Number(updatedRide.totalFare) || 0),
        };
      }

      await tx.seatBooking.deleteMany({
        where: { id: { in: bookingIds } },
      });
      await tx.notification.create({
        data: {
          userId: passengerId,
          type: "WARNING",
          title: "Seat request rejected",
          message: `Driver rejected your seat request for ${ride.origin} -> ${ride.destination}. Please try different seats or another ride.`,
        },
      });
      return {
        decision,
        seatNumbers,
        bookingTotal: Math.ceil(bookingTotal),
        rideTotalFare: Math.ceil(Number(ride.totalFare) || 0),
      };
    });

    if (result.decision === "ACCEPT") {
      socketHub.emitFareUpdate({ rideId, totalFare: result.rideTotalFare });
    }
    return res.json({
      message:
        result.decision === "ACCEPT"
          ? "Seat booking request accepted"
          : "Seat booking request rejected",
      ...result,
    });
  } catch (err) {
    if (err.message === "RIDE_NOT_FOUND") return res.status(404).json({ error: "Ride not found" });
    if (err.message === "FORBIDDEN") {
      return res.status(403).json({ error: "You are not allowed to manage this ride requests" });
    }
    if (err.message === "NO_PENDING_REQUEST") {
      return res.status(404).json({ error: "No pending request found for this passenger" });
    }
    console.error(err);
    return res.status(500).json({ error: "Internal server error" });
  }
};

exports.getActiveBooking = async (req, res) => {
  const userId = Number(req.params.userId);
  if (!Number.isInteger(userId)) {
    return res.status(400).json({ error: "Invalid userId" });
  }

  try {
    const booking = await prisma.seatBooking.findFirst({
      where: {
        userId,
        paidAt: null,
        ride: {
          status: { in: ["PLANNED", "ONGOING"] },
        },
      },
      include: {
        ride: {
          select: {
            id: true,
            origin: true,
            destination: true,
            departureTime: true,
            status: true,
            driverId: true,
            driver: {
              select: {
                id: true,
                name: true,
                email: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    if (!booking) {
      return res.json({ booking: null });
    }

    // Map status based on paymentMethod marker
    const status = booking.paymentMethod === "__PENDING_DRIVER_APPROVAL__" ? "PENDING" : "APPROVED";

    return res.json({
      booking: {
        ...booking,
        status,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Internal server error" });
  }
};

exports.getPassengerRideHistory = async (req, res) => {
  const userId = Number(req.params.userId);
  if (!Number.isInteger(userId)) {
    return res.status(400).json({ error: "Invalid userId" });
  }

  try {
    // Find all rides where the user had a booking and the ride is COMPLETED or CANCELLED
    // Or if the ride is finished (paidAt is not null)
    const bookings = await prisma.seatBooking.findMany({
      where: {
        userId,
      },
      include: {
        ride: {
          include: {
            driver: {
              select: {
                id: true,
                name: true,
                email: true,
              },
            },
          },
        },
      },
      orderBy: { createdAt: "desc" },
    });

    // Group bookings by ride to avoid duplicates if user booked multiple seats
    const rideMap = new Map();
    for (const b of bookings) {
      if (!rideMap.has(b.rideId)) {
        rideMap.set(b.rideId, {
          ...b.ride,
          status: b.ride.status,
          bookedAt: b.createdAt,
          paidAt: b.paidAt,
        });
      }
    }

    return res.json({ rides: Array.from(rideMap.values()) });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: "Internal server error" });
  }
};
