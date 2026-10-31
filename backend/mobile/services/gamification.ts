import AsyncStorage from "@react-native-async-storage/async-storage";

const XP_KEY = "wegym_xp";
const LEVEL_KEY = "wegym_level";
const STREAK_KEY = "wegym_streak";
const LAST_ACTIVITY_KEY = "wegym_last_activity";

const XP_PER_LEVEL = 500;
const STREAK_BONUS = 50;

export type GamificationState = {
  xp: number;
  level: number;
  streak: number;
  nextLevelXp: number;
  progress: number;
};

export async function getGamificationState(): Promise<GamificationState> {
  const xp = Number(await AsyncStorage.getItem(XP_KEY)) || 0;
  const level = Number(await AsyncStorage.getItem(LEVEL_KEY)) || 1;
  const streak = Number(await AsyncStorage.getItem(STREAK_KEY)) || 0;
  const nextLevelXp = level * XP_PER_LEVEL;
  const progress = Math.min(xp / nextLevelXp, 1);
  return { xp, level, streak, nextLevelXp, progress };
}

export async function addXP(amount: number): Promise<{ levelUp: boolean; newLevel: number; achievements: string[] }> {
  const state = await getGamificationState();
  let xp = state.xp + amount;
  let level = state.level;
  let levelUp = false;
  const achievements: string[] = [];

  const today = new Date().toISOString().slice(0, 10);
  const lastActivity = await AsyncStorage.getItem(LAST_ACTIVITY_KEY);

  if (lastActivity !== today) {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().slice(0, 10);
    const streak = lastActivity === yesterdayStr ? state.streak + 1 : 1;
    await AsyncStorage.setItem(STREAK_KEY, String(streak));
    await AsyncStorage.setItem(LAST_ACTIVITY_KEY, today);
    if (streak === 7) achievements.push("streak_7");
    if (streak === 30) achievements.push("streak_30");
    xp += STREAK_BONUS;
  }

  while (xp >= level * XP_PER_LEVEL) {
    xp -= level * XP_PER_LEVEL;
    level++;
    levelUp = true;
    achievements.push(`level_${level}`);
  }

  await AsyncStorage.setItem(XP_KEY, String(xp));
  await AsyncStorage.setItem(LEVEL_KEY, String(level));

  return { levelUp, newLevel: level, achievements };
}

export async function resetGamification() {
  await AsyncStorage.multiRemove([XP_KEY, LEVEL_KEY, STREAK_KEY, LAST_ACTIVITY_KEY]);
}
