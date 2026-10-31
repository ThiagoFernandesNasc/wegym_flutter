import { api } from "./client";

export async function updateProfile(data: {
  name?: string; email?: string;
  weightKg?: number; heightCm?: number;
  experienceLevel?: string; goal?: string;
  avatarUrl?: string;
}) {
  return api.patch("/api/user/profile", data);
}
