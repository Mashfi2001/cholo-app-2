/*
  Warnings:

  - A unique constraint covering the columns `[rideId]` on the table `SeatBooking` will be added. If there are existing duplicate values, this will fail.

*/
-- DropIndex
DROP INDEX "SeatBooking_rideId_seatNo_key";

-- CreateIndex
CREATE UNIQUE INDEX "SeatBooking_rideId_key" ON "SeatBooking"("rideId");
