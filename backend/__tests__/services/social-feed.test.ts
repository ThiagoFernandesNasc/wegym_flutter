import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('@/lib/prisma', () => ({
  prisma: {
    friendship: { findMany: vi.fn(), findFirst: vi.fn(), update: vi.fn() },
    socialPost: { findMany: vi.fn() },
  },
}));

import { prisma } from '@/lib/prisma';
import { socialService } from '@/lib/services/social.service';
import { NotFoundError } from '@/lib/errors';

describe('socialService.getFeedForUser', () => {
  it('limits the feed to accepted friends and the signed-in user', async () => {
    vi.mocked(prisma.friendship.findMany).mockResolvedValue([
      { requesterId: 'user-1', addresseeId: 'friend-1' },
      { requesterId: 'friend-2', addresseeId: 'user-1' },
    ] as never);
    vi.mocked(prisma.socialPost.findMany).mockResolvedValue([] as never);

    await socialService.getFeedForUser('user-1');

    expect(prisma.socialPost.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { userId: { in: ['friend-1', 'friend-2', 'user-1'] } },
        take: 50,
      }),
    );
  });
});

describe('socialService friend requests', () => {
  beforeEach(() => vi.clearAllMocks());

  it('returns accepted friends and both pending request directions', async () => {
    vi.mocked(prisma.friendship.findMany)
      .mockResolvedValueOnce([
        {
          requesterId: 'user-1',
          addressee: { id: 'friend-1', displayName: 'Amiga' },
          requester: { id: 'user-1', displayName: 'Eu' },
        },
      ] as never)
      .mockResolvedValueOnce([
        {
          id: 'incoming-1',
          status: 'pending',
          createdAt: new Date('2026-11-01T12:00:00Z'),
          requester: { id: 'sender-1', displayName: 'Lucas Mendes' },
        },
      ] as never)
      .mockResolvedValueOnce([
        {
          id: 'outgoing-1',
          status: 'pending',
          createdAt: new Date('2026-11-01T13:00:00Z'),
          addressee: { id: 'recipient-1', displayName: 'Camila' },
        },
      ] as never);

    await expect(socialService.getFriendRequests('user-1')).resolves.toMatchObject({
      friends: [{ id: 'friend-1', displayName: 'Amiga' }],
      incomingRequests: [{ friendshipId: 'incoming-1', displayName: 'Lucas Mendes' }],
      outgoingRequests: [{ friendshipId: 'outgoing-1', displayName: 'Camila' }],
    });
  });

  it('only lets the recipient accept or reject a pending request', async () => {
    vi.mocked(prisma.friendship.findFirst).mockResolvedValue({ id: 'request-1' } as never);
    vi.mocked(prisma.friendship.update).mockResolvedValue({ status: 'rejected' } as never);

    await socialService.respondToFriend('request-1', 'recipient-1', 'rejected');

    expect(prisma.friendship.findFirst).toHaveBeenCalledWith({
      where: { id: 'request-1', addresseeId: 'recipient-1', status: 'pending' },
      select: { id: true },
    });
    expect(prisma.friendship.update).toHaveBeenCalledWith({
      where: { id: 'request-1' },
      data: { status: 'rejected' },
    });
  });

  it('rejects responses from someone who is not the recipient', async () => {
    vi.mocked(prisma.friendship.findFirst).mockResolvedValue(null as never);

    await expect(
      socialService.respondToFriend('request-1', 'other-user', 'accepted'),
    ).rejects.toBeInstanceOf(NotFoundError);
    expect(prisma.friendship.update).not.toHaveBeenCalled();
  });
});
