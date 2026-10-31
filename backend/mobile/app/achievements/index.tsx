import { useEffect, useState } from "react";
import { View, Text, ScrollView, ActivityIndicator } from "react-native";
import { Stack } from "expo-router";
import { getAchievements, type Achievement, type UserAchievement } from "@/api/achievements";

export default function AchievementsScreen() {
  const [achievements, setAchievements] = useState<Achievement[]>([]);
  const [userAchievements, setUserAchievements] = useState<UserAchievement[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAchievements().then((d) => { setAchievements(d.achievements); setUserAchievements(d.userAchievements); }).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const earnedIds = new Set(userAchievements.map((ua) => ua.achievementId));

  return (
    <>
      <Stack.Screen options={{ title: "Conquistas" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 20 }}>Conquistas</Text>
          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : (
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10 }}>
              {achievements.map((ach) => {
                const earned = userAchievements.find((ua) => ua.achievementId === ach.id);
                return (
                  <View key={ach.id} style={{ width: "47%", backgroundColor: earned ? "#ea580c1a" : "#18181b", borderWidth: 1, borderColor: earned ? "#ea580c" : "#27272a", borderRadius: 20, padding: 16, alignItems: "center", opacity: earned ? 1 : 0.5 }}>
                    <Text style={{ fontSize: 36, marginBottom: 8 }}>{ach.icon}</Text>
                    <Text style={{ fontSize: 11, fontWeight: "900", fontStyle: "italic", color: "#fff", textAlign: "center" }}>{ach.title}</Text>
                    <Text style={{ fontSize: 9, color: "#71717a", textAlign: "center", marginTop: 4 }}>{ach.description}</Text>
                    <Text style={{ fontSize: 10, color: "#ea580c", fontWeight: "900", marginTop: 8 }}>+{ach.xpReward} XP</Text>
                    {earned && <Text style={{ fontSize: 9, color: "#10b981", marginTop: 4 }}>✅ {new Date(earned.earnedAt).toLocaleDateString("pt-BR")}</Text>}
                    {!earned && <Text style={{ fontSize: 14, color: "#52525b", marginTop: 4 }}>🔒</Text>}
                  </View>
                );
              })}
            </View>
          )}
        </View>
      </ScrollView>
    </>
  );
}
