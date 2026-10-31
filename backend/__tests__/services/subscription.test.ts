import { describe, it, expect, vi } from 'vitest';

vi.mock('@/lib/prisma', () => ({
  prisma: {
    subscription: {
      findFirst: vi.fn(),
      findUnique: vi.fn(),
      findMany: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      updateMany: vi.fn(),
    },
  },
}));

import { subscriptionService } from '@/lib/services/subscription.service';
import { prisma } from '@/lib/prisma';

describe('subscriptionService', () => {
  it('should create a new subscription', async () => {
    const mockSubscription = {
      id: 'sub-1',
      userId: 'user-1',
      plan: 'wegym-pro',
      status: 'active',
      paymentId: 'pay-123',
      startDate: new Date(),
      endDate: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    vi.mocked(prisma.subscription.findFirst).mockResolvedValue(null);
    vi.mocked(prisma.subscription.create).mockResolvedValue(mockSubscription);

    const result = await subscriptionService.create('user-1', 'wegym-pro', 'pay-123');
    expect(result.plan).toBe('wegym-pro');
    expect(result.status).toBe('active');
  });

  it('should update existing active subscription', async () => {
    const existing = {
      id: 'sub-1',
      userId: 'user-1',
      plan: 'wegym-basic',
      status: 'active',
      paymentId: 'pay-old',
      startDate: new Date(),
      endDate: null,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    const updated = {
      ...existing,
      plan: 'wegym-pro',
      paymentId: 'pay-new',
    };

    vi.mocked(prisma.subscription.findFirst).mockResolvedValue(existing);
    vi.mocked(prisma.subscription.update).mockResolvedValue(updated);

    const result = await subscriptionService.create('user-1', 'wegym-pro', 'pay-new');
    expect(result.plan).toBe('wegym-pro');
    expect(prisma.subscription.update).toHaveBeenCalled();
  });

  it('should cancel active subscriptions', async () => {
    vi.mocked(prisma.subscription.updateMany).mockResolvedValue({ count: 1 });

    await subscriptionService.cancel('user-1');
    expect(prisma.subscription.updateMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', status: 'active' },
      data: { status: 'cancelled', endDate: expect.any(Date) },
    });
  });
});
