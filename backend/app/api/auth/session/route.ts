import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const revalidate = 0;

export async function GET() {
  const session = await getServerSession(authOptions);

  const response = NextResponse.json(session ?? null, {
    status: 200,
    headers: {
      "Cache-Control": "private, s-maxage=30, stale-while-revalidate=60",
    },
  });

  return response;
}