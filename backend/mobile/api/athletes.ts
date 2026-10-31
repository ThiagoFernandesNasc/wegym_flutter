import { api } from "./client";

export type Athlete = {
  id: string; name: string; email: string; phone?: string;
  experienceLevel?: string; objective?: string;
  plan?: string; lastTrainingDate?: string;
  weightKg?: number; heightCm?: number;
  bodyFat?: number; availableDays?: string;
  restrictions?: string; injuries?: string;
  medications?: string; observations?: string;
};

export async function getAthletes(cursor?: string) {
  const params = cursor ? `?cursor=${cursor}` : "";
  return api.get<{ data: Athlete[]; nextCursor: string | null }>(`/api/athletes${params}`);
}

export async function registerAthlete(data: {
  name: string; email: string; cpf?: string; phone?: string;
  birthDate?: string; sex?: string;
  heightCm?: number; weightKg?: number;
  experienceLevel?: string; objective?: string;
  availableDays?: string; emergencyContact?: string;
  restrictions?: string; injuries?: string;
  medications?: string; observations?: string;
}) {
  return api.post<Athlete>("/api/athletes/register", data);
}

export async function deleteAthlete(id: string) {
  return api.delete(`/api/athletes/${id}`);
}
