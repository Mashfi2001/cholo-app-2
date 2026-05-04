/*
  Warnings:

  - You are about to drop the column `state` on the `SeatBooking` table. All the data in the column will be lost.
  - You are about to drop the `Payment` table. If the table is not empty, all the data it contains will be lost.

*/
-- AlterTable
ALTER TABLE "SeatBooking" DROP COLUMN "state";

-- DropTable
DROP TABLE "Payment";

-- DropEnum
DROP TYPE "PaymentStatus";
