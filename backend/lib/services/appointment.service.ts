import { prisma } from '@/lib/prisma';

export const appointmentService = {
  async createSlot(personalId: string, data: { date: Date; startTime: string; endTime: string }) {
    return prisma.appointmentSlot.create({ data: { personalId, ...data } });
  },

  async getSlots(personalId: string, date?: Date) {
    const where: Record<string, unknown> = { personalId, available: true };
    if (date) {
      const start = new Date(date);
      start.setHours(0, 0, 0, 0);
      const end = new Date(date);
      end.setHours(23, 59, 59, 999);
      where.date = { gte: start, lte: end };
    }
    return prisma.appointmentSlot.findMany({ where: where as any, orderBy: { date: 'asc' } });
  },

  async book(userId: string, slotId: string, type: string, notes?: string) {
    return prisma.$transaction(async (tx) => {
      const slot = await tx.appointmentSlot.findUnique({ where: { id: slotId } });
      if (!slot || !slot.available) throw new Error('Horário indisponível');
      const personalId = slot.personalId;
      const date = new Date(slot.date);
      const [h, m] = slot.startTime.split(':').map(Number);
      date.setHours(h, m, 0, 0);
      const [eh, em] = slot.endTime.split(':').map(Number);
      const endDate = new Date(slot.date);
      endDate.setHours(eh, em, 0, 0);
      const durationMin = Math.round((endDate.getTime() - date.getTime()) / 60000);
      const appointment = await tx.appointment.create({
        data: { athleteId: userId, personalId, date, durationMin, type, notes },
      });
      await tx.appointmentSlot.update({ where: { id: slotId }, data: { available: false } });
      return appointment;
    });
  },

  async getAppointments(userId: string, role: 'athlete' | 'personal') {
    const field = role === 'athlete' ? 'athleteId' : 'personalId';
    return prisma.appointment.findMany({
      where: { [field]: userId },
      orderBy: { date: 'desc' },
      include: {
        athlete: { select: { id: true, displayName: true } },
        personal: { select: { id: true, displayName: true } },
      },
    });
  },

  async cancel(id: string, userId: string) {
    const appointment = await prisma.appointment.findFirst({ where: { id, OR: [{ athleteId: userId }, { personalId: userId }] } });
    if (!appointment) throw new Error('Agendamento não encontrado');
    await prisma.appointment.update({ where: { id }, data: { status: 'cancelled' } });
    if (appointment.personalId === userId) {
      await prisma.appointmentSlot.create({
        data: { personalId: userId, date: appointment.date, startTime: appointment.date.toTimeString().slice(0, 5), endTime: new Date(appointment.date.getTime() + appointment.durationMin * 60000).toTimeString().slice(0, 5) },
      });
    }
  },

  async confirm(id: string) {
    return prisma.appointment.update({ where: { id }, data: { status: 'confirmed' } });
  },
};
