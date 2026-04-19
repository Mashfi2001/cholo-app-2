-- AlterTable
ALTER TABLE "VerificationRequest" ADD COLUMN     "documentPath" TEXT,
ADD COLUMN     "extractedData" JSONB,
ALTER COLUMN "documentUrl" DROP NOT NULL;
