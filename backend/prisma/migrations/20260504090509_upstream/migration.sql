/*
  Warnings:

  - You are about to drop the column `farePerSeat` on the `Ride` table. All the data in the column will be lost.
  - You are about to drop the column `isOnline` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `vehicleModel` on the `User` table. All the data in the column will be lost.
  - You are about to drop the column `vehiclePlate` on the `User` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Ride" DROP COLUMN "farePerSeat";

-- AlterTable
ALTER TABLE "User" DROP COLUMN "isOnline",
DROP COLUMN "vehicleModel",
DROP COLUMN "vehiclePlate";
