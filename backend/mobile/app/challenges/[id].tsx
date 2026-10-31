import { useEffect, useState } from "react";
import { View, Text, ScrollView, ActivityIndicator } from "react-native";
import { useLocalSearchParams, Stack } from "expo-router";
import { getLeaderboard, type LeaderboardEntry } from "@/api/challenges";

export default function ChallengeDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [leaderboard, setLeaderboard] = useState<LeaderboardEntry[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    getLeaderboard(id).then(setLeaderboard).catch(() => {}).finally(() => setLoading(false));
  }, [id]);

  return (
    <>
      <Stack.Screen options={{ title: "Ranking" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 20 }}>Ranking</Text>
          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : leaderboard.map((p, i) => (
            <View key={p.userId} style={{ flexDirection: "row", alignItems: "center", backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 14, marginBottom: 8, gap: 12 }}>
              <View style={{ width: 32, height: 32, borderRadius: 12, backgroundColor: i === 0 ? "#eab30833" : i === 1 ? "#a1a1aa33" : i === 2 ? "#b4530933" : "#18181b", alignItems: "center", justifyContent: "center" }}>
                <Text style={{ fontSize: 14, fontWeight: "900", color: i === 0 ? "#eab308" : i === 1 ? "#a1a1aa" : i === 2 ? "#b45309" : "#71717a" }}>
                  {i === 0 ? "👑" : i < 3 ? "🥇" : i + 1}
                </Text>
              </View>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 13, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{p.user.displayName || "Atleta"}</Text>
                <Text style={{ fontSize: 10, color: "#71717a" }}>{p.currentValue} pontos</Text>
              </View>
            </View>
          ))}
        </View>
      </ScrollView>
    </>
  );
}
