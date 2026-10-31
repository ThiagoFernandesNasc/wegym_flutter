import { revalidateTag, unstable_cache } from "next/cache";
import { authenticate, handleError, json, withRateLimit } from "@/lib/api-utils";
import { socialPostSchema } from "@/lib/validation";
import { ValidationError } from "@/lib/errors";
import { prisma } from "@/lib/prisma";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const revalidate = 0;

const PAGE_LIMIT = 10;

const getCachedFeed = unstable_cache(
  async (userId: string, cursor?: string) => {
    const where: Record<string, unknown> = {};
    if (cursor) where.id = { lt: cursor };

    const [posts, friends] = await Promise.all([
      prisma.socialPost.findMany({
        where,
        take: PAGE_LIMIT + 1,
        orderBy: { createdAt: "desc" },
        include: {
          user: { select: { id: true, displayName: true, avatarUrl: true } },
          likes: { select: { userId: true } },
          _count: { select: { likes: true, comments: true } },
        },
      }),
      prisma.friendship.findMany({
        where: {
          OR: [{ requesterId: userId }, { addresseeId: userId }],
          status: "accepted",
        },
        select: { requesterId: true, addresseeId: true },
      }),
    ]);

    const hasMore = posts.length > PAGE_LIMIT;
    const sliced = hasMore ? posts.slice(0, PAGE_LIMIT) : posts;
    const nextCursor = hasMore ? sliced[sliced.length - 1].id : null;

    return { posts: sliced, nextCursor, hasMore, friends };
  },
  ["social-feed"],
  { revalidate: 15, tags: ["social-feed"] }
);

const getCachedUserFeed = unstable_cache(
  async (userId: string, cursor?: string) => {
    const where: Record<string, unknown> = { userId };
    if (cursor) where.id = { lt: cursor };

    const [posts, friends] = await Promise.all([
      prisma.socialPost.findMany({
        where,
        take: PAGE_LIMIT + 1,
        orderBy: { createdAt: "desc" },
        include: {
          user: { select: { id: true, displayName: true, avatarUrl: true } },
          likes: { select: { userId: true } },
          _count: { select: { likes: true, comments: true } },
        },
      }),
      prisma.friendship.findMany({
        where: {
          OR: [{ requesterId: userId }, { addresseeId: userId }],
          status: "accepted",
        },
        select: { requesterId: true, addresseeId: true },
      }),
    ]);

    const hasMore = posts.length > PAGE_LIMIT;
    const sliced = hasMore ? posts.slice(0, PAGE_LIMIT) : posts;
    const nextCursor = hasMore ? sliced[sliced.length - 1].id : null;

    return { posts: sliced, nextCursor, hasMore, friends };
  },
  ["social-user-feed"],
  { revalidate: 15, tags: ["social-feed"] }
);

export async function GET(request: Request) {
  try {
    const session = await authenticate();
    const { searchParams } = new URL(request.url);
    const cursor = searchParams.get("cursor") ?? undefined;
    const feedType = searchParams.get("feed");

    let data;
    if (feedType === "friends") {
      data = await getCachedFeed(session.user.id, cursor);
    } else {
      data = await getCachedUserFeed(session.user.id, cursor);
    }

    return json(data, 200, 15);
  } catch (error) {
    return handleError(error);
  }
}

export async function POST(request: Request) {
  try {
    const session = await authenticate();
    const rateLimitResponse = await withRateLimit(request, `social:${session.user.id}`);
    if (rateLimitResponse) return rateLimitResponse;

    const body = await request.json();
    const parsed = socialPostSchema.safeParse(body);
    if (!parsed.success) throw new ValidationError("Post inválido", parsed.error.issues);

    const post = await prisma.socialPost.create({
      data: { userId: session.user.id, ...parsed.data },
    });

    revalidateTag("social-feed", "max");

    return json(post, 201);
  } catch (error) {
    return handleError(error);
  }
}