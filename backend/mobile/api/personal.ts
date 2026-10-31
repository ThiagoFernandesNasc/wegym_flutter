import { api } from "./client";

export type PersonalStats = {
  activeStudents: number;
  classesPerWeek: number;
  monthlyRevenue: number;
  retentionRate: number;
};

export async function getPersonalStats() {
  return api.get<PersonalStats>("/api/personal-stats");
}
