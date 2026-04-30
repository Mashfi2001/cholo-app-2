-- CreateEnum
CREATE TYPE "MessageType" AS ENUM ('ANNOUNCEMENT', 'ALERT', 'MAINTENANCE');

-- CreateEnum
CREATE TYPE "MessageStatus" AS ENUM ('ACTIVE', 'ARCHIVED', 'EXPIRED');

-- CreateTable
CREATE TABLE "SystemMessage" (
    "id" SERIAL NOT NULL,
    "type" "MessageType" NOT NULL DEFAULT 'ANNOUNCEMENT',
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "status" "MessageStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdBy" INTEGER NOT NULL,
    "expiresAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SystemMessage_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "SystemMessage" ADD CONSTRAINT "SystemMessage_createdBy_fkey" FOREIGN KEY ("createdBy") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
