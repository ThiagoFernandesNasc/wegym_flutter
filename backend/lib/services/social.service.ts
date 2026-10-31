import { prisma } from '@/lib/prisma';

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
        user: { select: { id: true, displayName: true, avatarUrl: true } },
        likes: { select: { userId: true } },
        comments: { select: { id: true, text: true, userId: true, createdAt: true, user: { select: { displayName: true } } } },
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
        user: { select: { id: true, displayName: true, avatarUrl: true } },
        likes: { select: { userId: true } },
        comments: { select: { id: true, text: true, userId: true, createdAt: true, user: { select: { displayName: true } } } },
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

  async respondToFriend(friendshipId: string, status: 'accepted' | 'blocked') {
    return prisma.friendship.update({ where: { id: friendshipId }, data: { status } });
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
};
