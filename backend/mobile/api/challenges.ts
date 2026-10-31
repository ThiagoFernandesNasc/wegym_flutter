import { api } from "./client";

export type Challenge = {
  id: string; title: string; description: string; metric: string;
  targetValue: number; startDate: string; endDate: string;
  participants?: { userId: string; currentValue: number }[];
};
export type LeaderboardEntry = { userId: string; currentValue: number; user: { id: string; displayName: string; avatarUrl?: string } };

export async function getChallenges() { return api.get<Challenge[]>("/api/challenges"); }
export async function joinChallenge(challengeId: string) { return api.post("/api/challenges", { challengeId }); }
export async function getLeaderboard(challengeId: string) { return api.get<LeaderboardEntry[]>(`/api/challenges/${challengeId}/leaderboard`); }
