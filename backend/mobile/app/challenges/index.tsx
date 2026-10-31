import { useEffect, useState } from "react";
import { View, Text, TouchableOpacity, ScrollView, ActivityIndicator } from "react-native";
import { router, Stack } from "expo-router";
import { getChallenges, joinChallenge, type Challenge } from "@/api/challenges";

export default function ChallengesScreen() {
  const [challenges, setChallenges] = useState<Challenge[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { getChallenges().then(setChallenges).catch(() => {}).finally(() => setLoading(false)); }, []);

  const handleJoin = async (id: string) => {
    try { await joinChallenge(id); router.push(`/challenges/${id}`); } catch { /* silent */ }
  };

  return (
    <>
      <Stack.Screen options={{ title: "Desafios" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 20 }}>Desafios</Text>
          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : challenges.length === 0 ? (
            <View style={{ alignItems: "center", paddingTop: 60 }}>
              <Text style={{ fontSize: 48, marginBottom: 12 }}>⚔️</Text>
              <Text style={{ color: "#71717a", fontSize: 14 }}>Nenhum desafio ativo</Text>
            </View>
          ) : challenges.map((c) => (
            <View key={c.id} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 12 }}>
              <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{c.title}</Text>
                  <Text style={{ fontSize: 10, color: "#71717a", marginTop: 4 }}>{c.description}</Text>
                  <Text style={{ fontSize: 9, color: "#52525b", marginTop: 8 }}>
                    📅 {new Date(c.startDate).toLocaleDateString()} - {new Date(c.endDate).toLocaleDateString()} · 👥 {c.participants?.length || 0}
                  </Text>
                </View>
                <TouchableOpacity onPress={() => handleJoin(c.id)} style={{ backgroundColor: "#ea580c", borderRadius: 14, paddingHorizontal: 16, paddingVertical: 10, alignSelf: "flex-start" }}>
                  <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>Participar</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))}
        </View>
      </ScrollView>
    </>
  );
}
