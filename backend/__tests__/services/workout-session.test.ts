import { describe, it, expect, vi } from 'vitest';

vi.mock('@/lib/prisma', () => ({
  prisma: {
    workoutSession: {
      create: vi.fn(),
      findMany: vi.fn(),
    },
  },
}));

import { workoutSessionService } from '@/lib/services/workout-session.service';
import { prisma } from '@/lib/prisma';

describe('workoutSessionService', () => {
  it('should create a workout session', async () => {
    const mockSession = {
      id: 'ws-1',
      athleteId: 'ath-1',
      modality: 'running',
      durationSec: 1800,
      distanceKm: 5.2,
      avgPaceSecPerKm: 346,
      steps: 6500,
      calories: 420,
      avgHeartRate: 145,
      completedAt: new Date(),
      exercises: null,
      createdAt: new Date(),
    };

    vi.mocked(prisma.workoutSession.create).mockResolvedValue(mockSession);

    const result = await workoutSessionService.create({
      athleteId: 'ath-1',
      modality: 'running',
      durationSec: 1800,
      distanceKm: 5.2,
    });

    expect(result.athleteId).toBe('ath-1');
    expect(result.modality).toBe('running');
  });

  it('should return stats grouped by period', async () => {
    const mockSessions = [
      { id: '1', athleteId: 'ath-1', modality: 'running', durationSec: 1800, distanceKm: 5.2, avgPaceSecPerKm: 346, steps: 6500, calories: 420, avgHeartRate: 145, completedAt: new Date(), exercises: null, createdAt: new Date() },
      { id: '2', athleteId: 'ath-1', modality: 'cycling', durationSec: 3600, distanceKm: 25, avgPaceSecPerKm: 144, steps: 0, calories: 680, avgHeartRate: 130, completedAt: new Date(Date.now() - 86400000), exercises: null, createdAt: new Date() },
    ];

    vi.mocked(prisma.workoutSession.findMany).mockResolvedValue(mockSessions);

    const stats = await workoutSessionService.getStats('ath-1', 'week');

    expect(stats.totalSessions).toBe(2);
    expect(stats.totalVolume).toBe(5400);
    expect(stats.totalCalories).toBe(1100);
  });
});
