const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/authRoutes");
const rideRoutes = require("./routes/rideRoutes");
const fareRoutes = require("./routes/fareRoutes");
const bookingRoutes = require("./routes/bookingRoutes");
const verificationRoutes = require("./routes/verificationRoutes");
const rideSearchRoutes = require("./routes/rideSearchRoutes");
const adminRoutes = require("./routes/adminRoutes");
const broadcastRoutes = require("./routes/broadcastRoutes");
const messageRoutes = require("./routes/messageRoutes");
const seatBookingRoutes = require("./routes/seatBookingRoutes");
const complaintRoutes = require("./routes/complaintRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const chatRoutes = require("./routes/chatRoutes");
const ratingRoutes = require("./routes/ratingRoutes");
const { requireAuth } = require("./middleware/auth");

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/", (req, res) => {
  res.send("Cholo backend is running");
});

// Public: login, signup, OTP and password reset must work without a session.
app.use("/api/auth", authRoutes);

// Passenger and driver surface: every request needs a valid session token.
// `requireAuth` populates req.user, so controllers can trust the caller's id.
app.use("/api/rides", requireAuth, rideRoutes);
app.use("/api/ride-search", requireAuth, rideSearchRoutes);
app.use("/api/fares", requireAuth, fareRoutes);
app.use("/api/bookings", requireAuth, bookingRoutes);
app.use("/seat-booking", requireAuth, seatBookingRoutes);
app.use("/api/complaints", requireAuth, complaintRoutes);
app.use("/api/notifications", requireAuth, notificationRoutes);
app.use("/api/chat", requireAuth, chatRoutes);
app.use("/api/verification", requireAuth, verificationRoutes);
app.use("/api/messages", requireAuth, messageRoutes);
app.use("/api/ratings", requireAuth, ratingRoutes);

// Left unauthenticated for now: these back the admin panel, which is outside
// the passenger/driver session work.
app.use("/api/admin", adminRoutes);
app.use("/api/broadcasts", broadcastRoutes);

// Global error handler for file upload and backend errors
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);

  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ message: 'Uploaded file is too large. Maximum size is 5MB.' });
  }

  if (err.message) {
    return res.status(400).json({ message: err.message });
  }

  res.status(500).json({ message: 'Internal server error' });
});

module.exports = app;
