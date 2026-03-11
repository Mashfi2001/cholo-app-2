const express = require("express");
const cors = require("cors");
const rideRoutes = require("./routes/rideRoutes");
const bookingRoutes = require("./routes/bookingRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Cholo backend is running");
});

app.use("/api/rides", rideRoutes);
app.use("/api/bookings", bookingRoutes);

module.exports = app;