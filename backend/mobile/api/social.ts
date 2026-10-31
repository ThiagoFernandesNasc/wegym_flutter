import { api } from "./client";

export type SocialPost = {
  id: string; text?: string; createdAt: string;
  user: { id: string; displayName: string; avatarUrl?: string };
  _count: { likes: number; comments: number };
  likes: { userId: string }[];
  comments: { id: string; text: string; userId: string; user: { displayName: string } }[];
};

export async function getFeed() { return api.get<SocialPost[]>("/api/social?feed=friends"); }
export async function createPost(text: string) { return api.post<SocialPost>("/api/social", { text }); }
export async function toggleLike(postId: string) { return api.post(`/api/social/${postId}/like`); }
export async function addComment(postId: string, text: string) { return api.post(`/api/social/${postId}/comment`, { text }); }
