import { authenticate, handleError, json } from "@/lib/api-utils";
import { workoutSessionService } from "@/lib/services/workout-session.service";
import { prisma } from "@/lib/prisma";
import { requireAthleteAccess } from "@/lib/athlete-access";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const revalidate = 0;

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const period = (searchParams.get("period") ?? "week") as "week" | "month" | "year";
    const requestedAthleteId = searchParams.get("athleteId");
    const athlete = requestedAthleteId
      ? await (async () => {
          await requireAthleteAccess(requestedAthleteId, session.user.id);
          return prisma.athlete.findUnique({ where: { id: requestedAthleteId }, select: { id: true } });
        })()
      : await prisma.athlete.findUnique({ where: { userId: session.user.id }, select: { id: true } });
    if (!athlete) {
      if ((session.user as { role?: string }).role === "personal") return json({ data: { totalSessions: 0, totalVolume: 0, totalDistance: 0, avgHeartRate: 0 } });
      return Response.json({ error: "Perfil de atleta não encontrado." }, { status: 404 });
    }
    return json({ data: await workoutSessionService.getStats(athlete.id, period) });
  } catch (error) {
    return handleError(error);
  }
}
