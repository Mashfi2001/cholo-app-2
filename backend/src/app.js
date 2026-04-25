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

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/", (req, res) => {
  res.send("Cholo backend is running");
});

app.use("/api/auth", authRoutes);
app.use("/api/rides", rideRoutes);
app.use("/api/ride-search", rideSearchRoutes);
app.use("/api/fares", fareRoutes);
app.use("/api/bookings", bookingRoutes);
app.use("/seat-booking", seatBookingRoutes);
app.use("/api/complaints", complaintRoutes);
app.use("/api/verification", verificationRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/broadcasts", broadcastRoutes);
app.use("/api/messages", messageRoutes);

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
