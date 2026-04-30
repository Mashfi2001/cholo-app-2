-- CreateEnum
CREATE TYPE "BroadcastType" AS ENUM ('ANNOUNCEMENT', 'ALERT', 'MAINTENANCE');

-- CreateTable
CREATE TABLE "BroadcastMessage" (
    "id" SERIAL NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "type" "BroadcastType" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3),

    CONSTRAINT "BroadcastMessage_pkey" PRIMARY KEY ("id")
);
