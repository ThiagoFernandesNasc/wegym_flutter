import { api } from "./client";

export async function exportUserData() {
  return api.get<{ url: string }>("/api/user/export");
}

export async function requestDataDeletion() {
  return api.delete<{ message: string }>("/api/user/account");
}

export async function acceptConsent(type: "terms" | "privacy" | "data") {
  return api.post("/api/user/consent", { type });
}
