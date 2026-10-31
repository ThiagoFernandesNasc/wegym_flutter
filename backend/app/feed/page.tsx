import { unstable_cache } from "next/cache";
import { headers } from "next/headers";
import { getServerSession } from "next-auth/next";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import { FeedClient } from "./FeedClient";

const PAGE_LIMIT = 10;

async function getFeedData(userId: string, cursor?: string) {
  const where: Record<string, unknown> = {};
  if (cursor) where.id = { lt: cursor };

  const [posts, friendships] = await Promise.all([
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

  return { posts: sliced, nextCursor, hasMore, friends: friendships };
}

const getCachedFeed = unstable_cache(getFeedData, ["feed-page"], {
  revalidate: 15,
  tags: ["social-feed"],
});

async function getSessionData() {
  const session = await getServerSession(authOptions);
  return session;
}

export default async function FeedPage({
  searchParams,
}: {
  searchParams: Promise<{ cursor?: string }>;
}) {
  const { cursor } = await searchParams;
  const session = await getSessionData();

  if (!session?.user?.id) {
    redirect("/login");
  }

  const data = await getCachedFeed(session.user.id, cursor);

  return <FeedClient initialData={data} currentUserId={session.user.id} />;
}