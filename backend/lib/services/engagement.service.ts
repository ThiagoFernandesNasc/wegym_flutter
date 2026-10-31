import { prisma } from '@/lib/prisma';

export const engagementService = {
  async sendMessage(senderId: string, receiverId: string, text: string) {
    return prisma.message.create({ data: { senderId, receiverId, text } });
  },

  async getConversation(userId: string, otherId: string, limit = 50) {
    return prisma.message.findMany({
      where: {
        OR: [
          { senderId: userId, receiverId: otherId },
          { senderId: otherId, receiverId: userId },
        ],
      },
      orderBy: { createdAt: 'asc' },
      take: limit,
    });
  },

  async getConversations(userId: string) {
    const sent = await prisma.message.findMany({
      where: { senderId: userId },
      distinct: ['receiverId'],
      orderBy: { createdAt: 'desc' },
      include: { receiver: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
    const received = await prisma.message.findMany({
      where: { receiverId: userId },
      distinct: ['senderId'],
      orderBy: { createdAt: 'desc' },
      include: { sender: { select: { id: true, displayName: true, avatarUrl: true } } },
    });
    return { sent, received };
  },

  async markAsRead(userId: string, senderId: string) {
    return prisma.message.updateMany({
      where: { receiverId: userId, senderId, read: false },
      data: { read: true },
    });
  },

  async getUnreadCount(userId: string) {
    return prisma.message.count({ where: { receiverId: userId, read: false } });
  },
};
