import bcrypt from "bcryptjs";
import { prisma } from "@/lib/prisma";
import { signMobileToken } from "@/lib/mobile-auth";
import { handleError, getIP, withRateLimit } from "@/lib/api-utils";
import { UnauthorizedError } from "@/lib/errors";

export const runtime = 'nodejs';

export async function POST(req: Request): Promise<Response> {
  try {
    const rl = await withRateLimit(req, `login:${getIP(req)}`);
    if (rl) return rl;

    const body = await req.json();
    const email = String(body?.email ?? "").trim().toLowerCase();
    const password = String(body?.password ?? "");

    if (!email || !password) {
      throw new UnauthorizedError("Email e senha são obrigatórios");
    }

    const user = await prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        role: true,
        passwordHash: true,
        athlete: { select: { name: true } },
        personal: { select: { name: true } },
      },
    });

    if (!user) {
      throw new UnauthorizedError("Email ou senha inválidos");
    }

    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      throw new UnauthorizedError("Email ou senha inválidos");
    }

    const token = await signMobileToken({
      id: user.id,
      role: user.role,
      email: user.email,
    });

    const name = user.athlete?.name ?? user.personal?.name ?? user.email;

    return Response.json(
      {
        token,
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          name,
        },
      },
      { status: 200 },
    );
  } catch (error) {
    return handleError(error);
  }
}
