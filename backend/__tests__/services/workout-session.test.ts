import { describe, it, expect, vi } from 'vitest';

vi.mock('@/lib/prisma', () => ({
  prisma: {
    workoutSession: {
      create: vi.fn(),
      findMany: vi.fn(),
      aggregate: vi.fn(),
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

  it('sums only explicitly completed resistance-training sets', async () => {
    vi.mocked(prisma.workoutSession.findMany).mockResolvedValue([
      {
        completedAt: new Date(),
        durationSec: 1800,
        exercises: [
          {
            name: 'Supino reto',
            performedSets: [
              { setNumber: 1, weightKg: 80, reps: 10, completed: true },
              { setNumber: 2, weightKg: 90, reps: 8, completed: true },
              { setNumber: 3, weightKg: 100, reps: 3, completed: false },
            ],
          },
          { name: 'Ficha antiga', sets: '3', reps: '10', load: '40 kg' },
        ],
      },
    ] as never);
    vi.mocked(prisma.workoutSession.aggregate).mockResolvedValue({
      _count: 1,
      _sum: { durationSec: 1800, calories: 0, distanceKm: 0 },
      _avg: { avgHeartRate: null },
    } as never);

    const stats = await workoutSessionService.getStats('ath-1', 'week');

    expect(stats.totalLiftedVolumeKg).toBe(1520);
  });

  it('should return stats grouped by period', async () => {
    const mockSessions = [
      { id: '1', athleteId: 'ath-1', modality: 'running', durationSec: 1800, distanceKm: 5.2, avgPaceSecPerKm: 346, steps: 6500, calories: 420, avgHeartRate: 145, completedAt: new Date(), exercises: null, createdAt: new Date() },
      { id: '2', athleteId: 'ath-1', modality: 'cycling', durationSec: 3600, distanceKm: 25, avgPaceSecPerKm: 144, steps: 0, calories: 680, avgHeartRate: 130, completedAt: new Date(Date.now() - 86400000), exercises: null, createdAt: new Date() },
    ];

    vi.mocked(prisma.workoutSession.findMany).mockResolvedValue(mockSessions);
    vi.mocked(prisma.workoutSession.aggregate).mockResolvedValue({
      _count: 2,
      _sum: { durationSec: 5400, calories: 1100, distanceKm: 30.2 },
      _avg: { avgHeartRate: 137.5 },
    } as never);

    const stats = await workoutSessionService.getStats('ath-1', 'week');

    expect(stats.totalSessions).toBe(2);
    expect(stats.totalVolume).toBe(5400);
    expect(stats.totalCalories).toBe(1100);
  });
});
