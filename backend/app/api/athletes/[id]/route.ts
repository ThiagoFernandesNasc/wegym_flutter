import { prisma } from '@/lib/prisma';
import { requireRole, handleError, json, cache } from '@/lib/api-utils';
import { athleteRegisterSchema } from '@/lib/validation';
import { ForbiddenError } from '@/lib/errors';

async function owned(id: string) {
  const session = await requireRole(['personal']);
  const athlete = await prisma.athlete.findFirst({ where: { id, personal: { userId: session.user.id } }, include: { user: { select: { email: true } } } });
  if (!athlete) throw new ForbiddenError();
  return athlete;
}
export async function GET(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  try { const a = await owned((await params).id); return json({ ...a, email: a.user.email, user: undefined }); }
  catch(e) { return handleError(e); }
}
export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const a = await owned((await params).id);
    const parsed = athleteRegisterSchema.omit({ email: true, cpf: true, birthDate: true }).partial().parse(await req.json());
    const result = await prisma.athlete.update({ where: { id: a.id }, data: parsed });
    await cache.delPattern('athletes:list:*'); await cache.del(`profile:${a.userId}`);
    return json(result);
  } catch(e) { return handleError(e); }
}
export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  try {
    const a = await owned((await params).id);
    // Unlink the student without deleting their login, workouts or personal records.
    await prisma.athlete.update({ where: { id: a.id }, data: { personalId: null } });
    await cache.delPattern('athletes:list:*'); await cache.del(`profile:${a.userId}`);
    return json({ success: true });
  } catch(e) { return handleError(e); }
}
