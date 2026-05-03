/** Socket.IO instance set from server.js so routes can emit without circular imports. */
let ioInstance = null;

module.exports = {
  attach(io) {
    ioInstance = io;
  },
  emitFareUpdate(payload) {
    if (ioInstance) {
      ioInstance.emit("fareUpdate", payload);
    }
  },
  emitRideMessage(message) {
    if (ioInstance) {
      const u1 = Math.min(message.senderId, message.receiverId);
      const u2 = Math.max(message.senderId, message.receiverId);
      const room = `chat_${message.rideId}_${u1}_${u2}`;
      ioInstance.to(room).emit("new_message", message);
    }
  },
};
