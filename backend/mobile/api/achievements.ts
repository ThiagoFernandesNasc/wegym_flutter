import { api } from "./client";

export type Achievement = {
  id: string; icon: string; title: string; description: string;
  category: string; xpReward: number;
};
export type UserAchievement = { id: string; achievementId: string; userId: string; earnedAt: string; achievement: Achievement; };
export type AchievementsData = { achievements: Achievement[]; userAchievements: UserAchievement[]; };

export async function getAchievements() { return api.get<AchievementsData>("/api/achievements"); }
