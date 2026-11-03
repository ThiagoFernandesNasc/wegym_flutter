import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('@/lib/prisma', () => ({
  prisma: { athlete: { findUnique: vi.fn() } },
}));

import { prisma } from '@/lib/prisma';
import { requireAthleteAccess } from '@/lib/athlete-access';
import { ForbiddenError, NotFoundError } from '@/lib/errors';

describe('requireAthleteAccess', () => {
  beforeEach(() => vi.clearAllMocks());

  it('allows the athlete to access their own record', async () => {
    vi.mocked(prisma.athlete.findUnique).mockResolvedValue({
      userId: 'athlete-1',
      personal: { userId: 'coach-1' },
    } as never);

    await expect(requireAthleteAccess('athlete-1', 'athlete-1')).resolves.toBeUndefined();
  });

  it('allows the linked Personal to access the athlete', async () => {
    vi.mocked(prisma.athlete.findUnique).mockResolvedValue({
      userId: 'athlete-1',
      personal: { userId: 'coach-1' },
    } as never);

    await expect(requireAthleteAccess('athlete-1', 'coach-1')).resolves.toBeUndefined();
  });

  it('rejects an unrelated account', async () => {
    vi.mocked(prisma.athlete.findUnique).mockResolvedValue({
      userId: 'athlete-1',
      personal: { userId: 'coach-1' },
    } as never);

    await expect(requireAthleteAccess('athlete-1', 'other-user')).rejects.toBeInstanceOf(
      ForbiddenError,
    );
  });

  it('reports a missing athlete', async () => {
    vi.mocked(prisma.athlete.findUnique).mockResolvedValue(null as never);

    await expect(requireAthleteAccess('missing-athlete', 'user-1')).rejects.toBeInstanceOf(
      NotFoundError,
    );
  });
});
