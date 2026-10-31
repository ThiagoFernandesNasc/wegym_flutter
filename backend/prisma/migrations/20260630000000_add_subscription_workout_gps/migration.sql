-- CreateTable
CREATE TABLE "subscriptions" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "plan" VARCHAR(50) NOT NULL,
    "status" VARCHAR(20) NOT NULL,
    "paymentId" VARCHAR(255),
    "startDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endDate" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workout_sessions" (
    "id" UUID NOT NULL,
    "athleteId" UUID NOT NULL,
    "modality" VARCHAR(50) NOT NULL,
    "durationSec" INTEGER NOT NULL,
    "distanceKm" DOUBLE PRECISION,
    "avgPaceSecPerKm" INTEGER,
    "steps" INTEGER,
    "calories" DOUBLE PRECISION,
    "avgHeartRate" INTEGER,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "exercises" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workout_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gps_sessions" (
    "id" UUID NOT NULL,
    "athleteId" UUID NOT NULL,
    "modality" VARCHAR(50) NOT NULL,
    "distanceKm" DOUBLE PRECISION NOT NULL,
    "durationSec" INTEGER NOT NULL,
    "avgPaceSecPerKm" INTEGER,
    "steps" INTEGER,
    "coordinates" JSONB,
    "startLat" DOUBLE PRECISION,
    "startLng" DOUBLE PRECISION,
    "endLat" DOUBLE PRECISION,
    "endLng" DOUBLE PRECISION,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gps_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_paymentId_key" ON "subscriptions"("paymentId");

-- CreateIndex
CREATE INDEX "subscriptions_userId_idx" ON "subscriptions"("userId");

-- CreateIndex
CREATE INDEX "subscriptions_status_idx" ON "subscriptions"("status");

-- CreateIndex
CREATE INDEX "subscriptions_paymentId_idx" ON "subscriptions"("paymentId");

-- CreateIndex
CREATE INDEX "workout_sessions_athleteId_completedAt_idx" ON "workout_sessions"("athleteId", "completedAt");

-- CreateIndex
CREATE INDEX "gps_sessions_athleteId_completedAt_idx" ON "gps_sessions"("athleteId", "completedAt");

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_athleteId_fkey" FOREIGN KEY ("athleteId") REFERENCES "athletes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "gps_sessions" ADD CONSTRAINT "gps_sessions_athleteId_fkey" FOREIGN KEY ("athleteId") REFERENCES "athletes"("id") ON DELETE CASCADE ON UPDATE CASCADE;
