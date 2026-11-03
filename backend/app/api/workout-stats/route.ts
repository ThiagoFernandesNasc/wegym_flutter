import { authenticate, handleError, json } from "@/lib/api-utils";
import { workoutSessionService } from "@/lib/services/workout-session.service";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const revalidate = 0;

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const period = (searchParams.get("period") ?? "week") as "week" | "month" | "year";

    const athlete = await prisma.athlete.findUnique({
      where: { userId: session.user.id },
      select: { id: true },
    });
    if (!athlete) {
      return Response.json({ error: "Atleta não encontrado" }, { status: 404 });
    }

    const stats = await workoutSessionService.getStats(athlete.id, period);
    return json({ data: stats });
  } catch (error) {
    return handleError(error);
  }
}
