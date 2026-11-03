import { prisma } from '@/lib/prisma';
import { NotFoundError } from '@/lib/errors';

export const socialService = {
  async createPost(userId: string, data: { text?: string; workoutId?: string; imageUrl?: string }) {
    return prisma.socialPost.create({ data: { userId, ...data } });
  },

  async getFeed(page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    return prisma.socialPost.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        user: {
          select: {
            id: true, displayName: true, avatarUrl: true,
            athlete: { select: { name: true } },
            personal: { select: { name: true } },
          },
        },
        likes: { select: { userId: true } },
        comments: { select: { id: true, text: true, userId: true, createdAt: true, user: {
            select: {
              displayName: true,
              athlete: { select: { name: true } },
              personal: { select: { name: true } },
            },
          } } },
        _count: { select: { likes: true, comments: true } },
      },
    });
  },

  async getFeedForUser(userId: string) {
    const friends = await prisma.friendship.findMany({
      where: { OR: [{ requesterId: userId }, { addresseeId: userId }], status: 'accepted' },
    });
    const friendIds = friends.map((f) => (f.requesterId === userId ? f.addresseeId : f.requesterId));
    friendIds.push(userId);
    return prisma.socialPost.findMany({
      where: { userId: { in: friendIds } },
      orderBy: { createdAt: 'desc' },
      take: 50,
      include: {
        user: {
          select: {
            id: true, displayName: true, avatarUrl: true,
            athlete: { select: { name: true } },
            personal: { select: { name: true } },
          },
        },
        likes: { select: { userId: true } },
        comments: { select: { id: true, text: true, userId: true, createdAt: true, user: {
            select: {
              displayName: true,
              athlete: { select: { name: true } },
              personal: { select: { name: true } },
            },
          } } },
        _count: { select: { likes: true, comments: true } },
      },
    });
  },

  async toggleLike(postId: string, userId: string) {
    return prisma.$transaction(async (tx) => {
      const existing = await tx.socialLike.findUnique({ where: { postId_userId: { postId, userId } } });
      if (existing) {
        await tx.socialLike.delete({ where: { id: existing.id } });
        return { liked: false };
      }
      await tx.socialLike.create({ data: { postId, userId } });
      return { liked: true };
    });
  },

  async addComment(postId: string, userId: string, text: string) {
    return prisma.socialComment.create({ data: { postId, userId, text } });
  },

  async sendFriendRequest(requesterId: string, addresseeId: string) {
    return prisma.friendship.upsert({
      where: { requesterId_addresseeId: { requesterId, addresseeId } },
      create: { requesterId, addresseeId },
      update: { status: 'pending' },
    });
  },

  async respondToFriend(
    friendshipId: string,
    userId: string,
    status: 'accepted' | 'rejected',
  ) {
    const request = await prisma.friendship.findFirst({
      where: { id: friendshipId, addresseeId: userId, status: 'pending' },
      select: { id: true },
    });
    if (!request) throw new NotFoundError('Solicitação de amizade');
    return prisma.friendship.update({ where: { id: request.id }, data: { status } });
  },

  async getFriends(userId: string) {
    const friendships = await prisma.friendship.findMany({
      where: { OR: [{ requesterId: userId }, { addresseeId: userId }], status: 'accepted' },
      include: {
        requester: { select: { id: true, displayName: true, avatarUrl: true } },
        addressee: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });
    return friendships.map((f) => (f.requesterId === userId ? f.addressee : f.requester));
  },

  async getFriendRequests(userId: string) {
    const [friends, incoming, outgoing] = await Promise.all([
      prisma.friendship.findMany({
        where: {
          OR: [{ requesterId: userId }, { addresseeId: userId }],
          status: 'accepted',
        },
        include: {
          requester: { select: { id: true, displayName: true, avatarUrl: true } },
          addressee: { select: { id: true, displayName: true, avatarUrl: true } },
        },
        orderBy: { updatedAt: 'desc' },
      }),
      prisma.friendship.findMany({
        where: { addresseeId: userId, status: 'pending' },
        include: {
          requester: { select: { id: true, displayName: true, avatarUrl: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.friendship.findMany({
        where: { requesterId: userId, status: 'pending' },
        include: {
          addressee: { select: { id: true, displayName: true, avatarUrl: true } },
        },
        orderBy: { createdAt: 'desc' },
      }),
    ]);
    return {
      friends: friends.map((f) =>
        f.requesterId === userId ? f.addressee : f.requester,
      ),
      incomingRequests: incoming.map((f) => ({
        friendshipId: f.id,
        status: f.status,
        createdAt: f.createdAt,
        ...f.requester,
      })),
      outgoingRequests: outgoing.map((f) => ({
        friendshipId: f.id,
        status: f.status,
        createdAt: f.createdAt,
        ...f.addressee,
      })),
    };
  },
};
