import { api } from "./client";

export async function forgotPassword(email: string) {
  return api.post<{ message: string }>("/api/auth/forgot-password", { email });
}

export async function resetPassword(token: string, password: string) {
  return api.post<{ message: string }>("/api/auth/reset-password", { token, password });
}
