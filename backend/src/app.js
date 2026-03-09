const express = require("express");
const cors = require("cors");
const rideRoutes = require("./routes/rideRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.send("Cholo backend is running");
});

app.use("/api/rides", rideRoutes);

module.exports = app;