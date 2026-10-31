import { api } from "./client";

export type ChatMessage = { id: string; role: "user" | "assistant"; text: string; createdAt: string };

export async function sendChatMessage(text: string) {
  return api.post<{ reply: string; conversationId: string }>("/api/chat", { text });
}

export async function getChatHistory() {
  return api.post<ChatMessage[]>("/api/chat", { action: "history" });
}
