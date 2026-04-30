-- AlterTable
ALTER TABLE "Ride" ADD COLUMN     "currentLat" DOUBLE PRECISION,
ADD COLUMN     "currentLng" DOUBLE PRECISION,
ADD COLUMN     "routePolyline" TEXT;
