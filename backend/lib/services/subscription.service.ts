import { prisma } from '@/lib/prisma';

export const subscriptionService = {
  async create(userId: string, plan: string, paymentId: string) {
    const existing = await prisma.subscription.findFirst({
      where: { userId, status: 'active' },
    });
    if (existing) {
      return prisma.subscription.update({
        where: { id: existing.id },
        data: { plan, paymentId, status: 'active', endDate: null },
      });
    }
    return prisma.subscription.create({
      data: { userId, plan, paymentId, status: 'active' },
    });
  },

  async getActive(userId: string) {
    return prisma.subscription.findFirst({
      where: { userId, status: 'active' },
    });
  },

  async getByPaymentId(paymentId: string) {
    return prisma.subscription.findUnique({
      where: { paymentId },
    });
  },

  async cancel(userId: string) {
    return prisma.subscription.updateMany({
      where: { userId, status: 'active' },
      data: { status: 'cancelled', endDate: new Date() },
    });
  },
};
