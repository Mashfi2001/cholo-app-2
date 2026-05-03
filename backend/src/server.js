require("dotenv").config();
const http = require("http");
const socketIo = require("socket.io");
const app = require("./app");
const socketHub = require("./lib/socketHub");

const server = http.createServer(app);
const io = socketIo(server);
socketHub.attach(io);

io.on("connection", (socket) => {
  console.log("A user connected");
  
  socket.on("join_chat", (payload) => {
    const { rideId, userId, otherUserId } = payload;
    const u1 = Math.min(userId, otherUserId);
    const u2 = Math.max(userId, otherUserId);
    const room = `chat_${rideId}_${u1}_${u2}`;
    socket.join(room);
    console.log(`User joined private chat room: ${room}`);
  });

  socket.on("disconnect", () => {
    console.log("A user disconnected");
  });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
