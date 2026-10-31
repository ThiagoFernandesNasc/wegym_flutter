-- Migration: Add performance indexes for slow queries
-- Run with: npx prisma migrate dev --name add_performance_indexes

-- ============================================
-- WORKOUT SESSIONS TABLE
-- ============================================

-- Composite index for stats queries (filter by athlete + date range + order by date)
CREATE INDEX IF NOT EXISTS "workout_session_athlete_completed_idx"
ON "WorkoutSession" ("athleteId", "completedAt" DESC);

-- Index for list pagination with cursor
CREATE INDEX IF NOT EXISTS "workout_session_athlete_id_idx"
ON "WorkoutSession" ("athleteId", "id" DESC);

-- ============================================
-- SOCIAL POSTS TABLE
-- ============================================

-- Composite index for feed queries (filter by user IDs + order by date)
CREATE INDEX IF NOT EXISTS "social_post_user_created_idx"
ON "SocialPost" ("userId", "createdAt" DESC);

-- Composite index for cursor-based pagination
CREATE INDEX IF NOT EXISTS "social_post_id_created_idx"
ON "SocialPost" ("id", "createdAt" DESC);

-- ============================================
-- FRIENDSHIP TABLE
-- ============================================

-- Index for fetching accepted friends (used in feed queries)
CREATE INDEX IF NOT EXISTS "friendship_requester_status_idx"
ON "Friendship" ("requesterId", "status")
WHERE "status" = 'accepted';

CREATE INDEX IF NOT EXISTS "friendship_addressee_status_idx"
ON "Friendship" ("addresseeId", "status")
WHERE "status" = 'accepted';

-- ============================================
-- SOCIAL LIKES TABLE
-- ============================================

-- Index for checking if user liked a post (used in feed rendering)
CREATE INDEX IF NOT EXISTS "social_like_post_user_idx"
ON "SocialLike" ("postId", "userId");

-- ============================================
-- SOCIAL COMMENTS TABLE
-- ============================================

-- Index for fetching comments on a post
CREATE INDEX IF NOT EXISTS "social_comment_post_created_idx"
ON "SocialComment" ("postId", "createdAt" DESC);

-- ============================================
-- USER TABLE
-- ============================================

-- Index for session lookup by email (login)
CREATE INDEX IF NOT EXISTS "user_email_idx"
ON "User" ("email");

-- ============================================
-- ATHLETE TABLE
-- ============================================

-- Index for athlete lookup by userId
CREATE INDEX IF NOT EXISTS "athlete_user_idx"
ON "Athlete" ("userId");

-- ============================================
-- PERFORMANCE NOTES
-- ============================================
-- These indexes target the slowest queries:
-- 1. /api/workout-stats: athleteId + completedAt filter + aggregate
-- 2. /api/social (feed): userId IN (...) + createdAt ordering + cursor pagination
-- 3. /api/auth/session: user lookup by email (already unique)
-- 4. /stats page: same as workout-stats
--
-- Expected impact:
-- - /api/workout-stats: 1.7s -> <100ms (aggregate uses index)
-- - /feed: 5.6s -> <200ms (parallel fetch + cursor pagination + index)
-- - /stats: 3.6s -> <150ms (cached RSC + indexed queries)
-- - /api/auth/session: 2.1s -> <50ms (JWT strategy + cache headers)