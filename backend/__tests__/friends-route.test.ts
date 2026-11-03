import { beforeEach, describe, expect, it, vi } from 'vitest';

const routeMocks = vi.hoisted(() => ({
  authenticate: vi.fn(),
  withRateLimit: vi.fn(),
  getFriends: vi.fn(),
  getFriendRequests: vi.fn(),
  sendFriendRequest: vi.fn(),
  respondToFriend: vi.fn(),
  findUser: vi.fn(),
}));

vi.mock('@/lib/api-utils', () => ({
  authenticate: routeMocks.authenticate,
  handleError: (error: unknown) => Response.json({ error: String(error) }, { status: 500 }),
  json: (data: unknown, status = 200) => Response.json(data, { status }),
  withRateLimit: routeMocks.withRateLimit,
}));
vi.mock('@/lib/prisma', () => ({
  prisma: { user: { findUnique: routeMocks.findUser } },
}));
vi.mock('@/lib/services/social.service', () => ({
  socialService: {
    getFriends: routeMocks.getFriends,
    getFriendRequests: routeMocks.getFriendRequests,
    sendFriendRequest: routeMocks.sendFriendRequest,
    respondToFriend: routeMocks.respondToFriend,
  },
}));

import { GET, POST } from '@/app/api/friends/route';

describe('friends API route', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    routeMocks.authenticate.mockResolvedValue({ user: { id: 'current-user' } });
    routeMocks.withRateLimit.mockResolvedValue(null);
    routeMocks.getFriends.mockResolvedValue([]);
    routeMocks.getFriendRequests.mockResolvedValue({
      friends: [],
      incomingRequests: [],
      outgoingRequests: [],
    });
    routeMocks.sendFriendRequest.mockResolvedValue({ id: 'request-1' });
    routeMocks.respondToFriend.mockResolvedValue({ id: 'request-1' });
    routeMocks.findUser.mockResolvedValue({ id: 'recipient-user' });
  });

  it('keeps the old accepted-friends response unless requests are requested', async () => {
    const oldResponse = await GET(new Request('http://localhost/api/friends'));
    const requestResponse = await GET(
      new Request('http://localhost/api/friends?includeRequests=1'),
    );

    expect(await oldResponse.json()).toEqual([]);
    expect(routeMocks.getFriends).toHaveBeenCalledWith('current-user');
    expect(await requestResponse.json()).toMatchObject({
      friends: [],
      incomingRequests: [],
      outgoingRequests: [],
    });
    expect(routeMocks.getFriendRequests).toHaveBeenCalledWith('current-user');
  });

  it.each([
    ['accept', 'accepted'],
    ['reject', 'rejected'],
  ])('maps the %s decision to the friendship status', async (response, status) => {
    const result = await POST(
      new Request('http://localhost/api/friends', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          action: 'respond',
          friendshipId: '00000000-0000-4000-8000-000000000001',
          response,
        }),
      }),
    );

    expect(result.status).toBe(200);
    expect(routeMocks.respondToFriend).toHaveBeenCalledWith(
      '00000000-0000-4000-8000-000000000001',
      'current-user',
      status,
    );
  });

  it('resolves email invitations to a user ID before creating the request', async () => {
    const result = await POST(
      new Request('http://localhost/api/friends', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ addresseeEmail: 'Friend@Example.com' }),
      }),
    );

    expect(result.status).toBe(200);
    expect(routeMocks.findUser).toHaveBeenCalledWith({
      where: { email: 'friend@example.com' },
      select: { id: true },
    });
    expect(routeMocks.sendFriendRequest).toHaveBeenCalledWith(
      'current-user',
      'recipient-user',
    );
  });
});
