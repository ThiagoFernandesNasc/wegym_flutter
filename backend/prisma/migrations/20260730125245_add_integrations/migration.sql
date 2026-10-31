/*
  Warnings:

  - You are about to alter the column `weightKg` on the `athletes` table. The data in that column could be lost. The data in that column will be cast from `Decimal(5,2)` to `DoublePrecision`.
  - The `muscleMass` column on the `progress_entries` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - The `bodyFat` column on the `progress_entries` table would be dropped and recreated. This will lead to data loss if there is data in the column.
  - You are about to alter the column `time` on the `weekly_classes` table. The data in that column could be lost. The data in that column will be cast from `VarChar(10)` to `VarChar(5)`.
  - Changed the type of `weight` on the `progress_entries` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `day` on the `training_plans` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `day` on the `weekly_classes` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `date` on the `weekly_classes` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- CreateEnum
CREATE TYPE "WeekDay" AS ENUM ('Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom');

-- DropIndex
DROP INDEX "progress_entries_athleteId_idx";

-- DropIndex
DROP INDEX "training_plans_athleteId_idx";

-- DropIndex
DROP INDEX "weekly_classes_athleteId_idx";

-- AlterTable
ALTER TABLE "athletes" ADD COLUMN     "availableDays" VARCHAR(100),
ADD COLUMN     "emergencyContact" VARCHAR(255),
ADD COLUMN     "objective" VARCHAR(255),
ADD COLUMN     "observations" TEXT,
ADD COLUMN     "phone" VARCHAR(20),
ALTER COLUMN "weightKg" SET DATA TYPE DOUBLE PRECISION;

-- AlterTable
ALTER TABLE "progress_entries" DROP COLUMN "weight",
ADD COLUMN     "weight" DOUBLE PRECISION NOT NULL,
DROP COLUMN "muscleMass",
ADD COLUMN     "muscleMass" DOUBLE PRECISION,
DROP COLUMN "bodyFat",
ADD COLUMN     "bodyFat" DOUBLE PRECISION;

-- AlterTable
ALTER TABLE "training_plans" DROP COLUMN "day",
ADD COLUMN     "day" "WeekDay" NOT NULL;

-- AlterTable
ALTER TABLE "users" ALTER COLUMN "termsAcceptedAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "privacyAcceptedAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "dataConsentAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "markedForDeletionAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "anonymizedAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "resetTokenExpires" SET DATA TYPE TIMESTAMP(3);

-- AlterTable
ALTER TABLE "weekly_classes" DROP COLUMN "day",
ADD COLUMN     "day" "WeekDay" NOT NULL,
DROP COLUMN "date",
ADD COLUMN     "date" TIMESTAMP(3) NOT NULL,
ALTER COLUMN "time" SET DATA TYPE VARCHAR(5);

-- CreateTable
CREATE TABLE "integrations" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "provider" VARCHAR(50) NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "syncEnabled" BOOLEAN NOT NULL DEFAULT true,
    "accessToken" TEXT NOT NULL,
    "refreshToken" TEXT,
    "tokenType" VARCHAR(50),
    "expiresAt" TIMESTAMP(3),
    "scope" VARCHAR(255),
    "providerData" JSONB,
    "lastSyncAt" TIMESTAMP(3),
    "nextSyncAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "integrations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "integrations_userId_idx" ON "integrations"("userId");

-- CreateIndex
CREATE INDEX "integrations_provider_idx" ON "integrations"("provider");

-- CreateIndex
CREATE UNIQUE INDEX "integrations_userId_provider_key" ON "integrations"("userId", "provider");

-- CreateIndex
CREATE INDEX "athletes_createdAt_idx" ON "athletes"("createdAt");

-- CreateIndex
CREATE INDEX "exercises_planId_idx" ON "exercises"("planId");

-- CreateIndex
CREATE INDEX "progress_entries_athleteId_date_idx" ON "progress_entries"("athleteId", "date");

-- CreateIndex
CREATE INDEX "training_plans_athleteId_day_idx" ON "training_plans"("athleteId", "day");

-- CreateIndex
CREATE INDEX "weekly_classes_athleteId_date_idx" ON "weekly_classes"("athleteId", "date");

-- AddForeignKey
ALTER TABLE "integrations" ADD CONSTRAINT "integrations_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
