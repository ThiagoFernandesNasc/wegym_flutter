import { api } from "./client";

export type Message = {
  id: string; senderId: string; receiverId: string;
  text: string; createdAt: string;
  sender: { id: string; displayName: string };
  receiver: { id: string; displayName: string };
};
export type ConversationsData = {
  sent: Message[]; received: Message[];
};

export async function getConversations() { return api.get<{ conversations: ConversationsData }>("/api/messages"); }
export async function getMessages(userId: string) { return api.get<Message[]>(`/api/messages/${userId}`); }
export async function sendMessage(receiverId: string, text: string) { return api.post<Message>("/api/messages", { receiverId, text }); }
