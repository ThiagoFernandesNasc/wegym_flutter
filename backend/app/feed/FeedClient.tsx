"use client";

import { useCallback, useState, lazy, Suspense } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Heart, MessageCircle, Loader2, Send } from "lucide-react";
import { useSession } from "next-auth/react";

const LazyHeart = lazy(async () => ({ default: (await import("lucide-react")).Heart }));
const LazyLoader2 = lazy(async () => ({ default: (await import("lucide-react")).Loader2 }));

type Post = {
  id: string;
  text?: string | null;
  createdAt: Date | string;
  user: { displayName: string | null; avatarUrl?: string | null };
  _count: { likes: number; comments: number };
  likes: { userId: string }[];
};

type FeedData = {
  posts: Post[];
  nextCursor: string | null;
  hasMore: boolean;
  friends: { requesterId: string; addresseeId: string }[];
};

interface FeedClientProps {
  initialData: FeedData;
  currentUserId: string;
}

export function FeedClient({ initialData, currentUserId }: FeedClientProps) {
  const { t } = useTranslations();
  const { data: session } = useSession();
  const [posts, setPosts] = useState<Post[]>(initialData.posts);
  const [loading, setLoading] = useState(false);
  const [newPost, setNewPost] = useState("");
  const [csrfToken, setCsrfToken] = useState<string>("");
  const [nextCursor, setNextCursor] = useState<string | null>(initialData.nextCursor);
  const [hasMore, setHasMore] = useState<boolean>(initialData.hasMore);
  const [loadingMore, setLoadingMore] = useState(false);

  const loadMore = useCallback(async () => {
    if (!nextCursor || loadingMore || !hasMore) return;
    setLoadingMore(true);
    try {
      const res = await fetch(`/api/social?feed=friends&cursor=${nextCursor}`, {
        credentials: "include",
        headers: { "Cache-Control": "no-cache" },
      });
      if (res.ok) {
        const data = await res.json();
        setPosts((prev) => [...prev, ...data.posts]);
        setNextCursor(data.nextCursor);
        setHasMore(data.hasMore);
      }
    } finally {
      setLoadingMore(false);
    }
  }, [nextCursor, loadingMore, hasMore]);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch("/api/social?feed=friends", {
        credentials: "include",
        headers: { "Cache-Control": "no-cache" },
      });
      if (res.ok) setPosts((await res.json()).posts);
    } finally {
      setLoading(false);
    }
  }, []);

  const getCsrfToken = useCallback(async () => {
    const res = await fetch("/api/csrf", { credentials: "include" });
    const data = await res.json();
    setCsrfToken(data.csrfToken || "");
  }, []);

  const createPost = async () => {
    if (!newPost.trim()) return;
    await fetch("/api/social", {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: newPost }),
    });
    setNewPost("");
    load();
  };

  const toggleLike = async (postId: string) => {
    const res = await fetch(`/api/social/${postId}/like`, {
      method: "POST",
      credentials: "include",
      headers: { "X-CSRF-TOKEN": csrfToken },
    });
    const data = await res.json();
    if (data.liked) load();
  };

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4">
          <h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">
            {t("feed.title")}
          </h1>
        </header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-4">
          <div className="bg-zinc-900/40 border border-white/5 rounded-4xl p-4 flex gap-3">
            <input
              value={newPost}
              onChange={(e) => setNewPost(e.target.value)}
              placeholder={t("feed.placeholder")}
              className="flex-1 bg-transparent text-sm text-white placeholder:text-zinc-600 outline-none"
            />
            <button
              onClick={createPost}
              disabled={!newPost.trim()}
              className="bg-orange-600 hover:bg-orange-700 disabled:bg-zinc-700 text-white p-3 rounded-xl cursor-pointer transition-colors disabled:cursor-not-allowed"
            >
              <Send size={16} />
            </button>
          </div>
          {loading ? (
            <div className="flex justify-center pt-12">
              <Suspense fallback={<Loader2 size={24} className="animate-spin text-orange-500" />}>
                <LazyLoader2 size={24} className="animate-spin text-orange-500" />
              </Suspense>
            </div>
          ) : posts.length === 0 ? (
            <div className="text-center pt-20">
              <MessageCircle size={48} className="mx-auto text-zinc-600 mb-4" />
              <p className="text-zinc-500 text-sm">{t("feed.noPosts")}</p>
            </div>
          ) : (
            <>
              {posts.map((post) => (
                <div key={post.id} className="bg-zinc-900/40 border border-white/5 rounded-4xl p-5">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-9 h-9 rounded-2xl bg-orange-600/20 flex items-center justify-center text-orange-500 text-sm font-bold">
                      {post.user.displayName?.charAt(0) || "?"}
                    </div>
                    <div>
                      <p className="text-sm font-black italic text-white">{post.user.displayName}</p>
                      <p className="text-[10px] text-zinc-500">
                        {new Date(post.createdAt).toLocaleDateString("pt-BR")}
                      </p>
                    </div>
                  </div>
                  {post.text && <p className="text-sm text-zinc-300 mb-4">{post.text}</p>}
                  <div className="flex items-center gap-4 text-xs text-zinc-500">
                    <button
                      onClick={() => toggleLike(post.id)}
                      className={`flex items-center gap-1 cursor-pointer transition-colors ${
                        post.likes.some((l) => l.userId === currentUserId) ? "text-rose-500" : "hover:text-rose-400"
                      }`}
                      aria-label={post.likes.some((l) => l.userId === currentUserId) ? t("feed.unlike") : t("feed.like")}
                    >
                      <Suspense fallback={<Heart size={14} />}>
                        <LazyHeart
                          size={14}
                          className={post.likes.some((l) => l.userId === currentUserId) ? "fill-rose-500 text-rose-500" : ""}
                        />
                      </Suspense>
                      {post._count.likes}
                    </button>
                    <span className="flex items-center gap-1">
                      <MessageCircle size={14} /> {post._count.comments}
                    </span>
                  </div>
                </div>
              ))}
              {hasMore && (
                <div className="flex justify-center pt-4">
                  <button
                    onClick={loadMore}
                    disabled={loadingMore}
                    className="px-6 py-2 bg-zinc-900/40 border border-white/5 rounded-xl text-sm font-medium text-zinc-300 hover:border-orange-500 hover:text-white transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {loadingMore ? (
                      <>
                        <Suspense fallback={<Loader2 size={14} className="animate-spin" />}>
                          <LazyLoader2 size={14} className="animate-spin" />
                        </Suspense>
                        Carregando...
                      </>
                    ) : (
                      t("feed.loadMore")
                    )}
                  </button>
                </div>
              )}
            </>
          )}
        </main>
      </div>
    </AuthGuard>
  );
}

