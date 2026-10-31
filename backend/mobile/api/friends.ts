import { api } from "./client";

export type Friend = {
  id: string;
  displayName: string;
  avatarUrl?: string;
};

export async function getFriends() {
  return api.get<Friend[]>("/api/friends");
}

export async function sendFriendRequest(userId: string) {
  return api.post("/api/friends", { userId, action: "send" });
}

export async function respondToFriend(userId: string, accept: boolean) {
  return api.post("/api/friends", { userId, action: accept ? "accept" : "reject" });
}
