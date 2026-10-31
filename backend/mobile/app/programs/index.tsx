import { useCallback, useEffect, useState } from "react";
import { View, Text, TouchableOpacity, ScrollView, ActivityIndicator } from "react-native";
import { router, Stack } from "expo-router";
import { getPrograms, type Program } from "@/api/programs";

const CAT_ICONS: Record<string, string> = { gym: "🏋️", running: "🏃", weight_loss: "❤️" };

export default function ProgramsScreen() {
  const [programs, setPrograms] = useState<Program[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => { getPrograms().then(setPrograms).catch(() => {}).finally(() => setLoading(false)); }, []);

  return (
    <>
      <Stack.Screen options={{ title: "Programas" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 20 }}>Programas</Text>
          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : programs.map((p) => (
            <TouchableOpacity key={p.id} onPress={() => router.push(`/programs/${p.id}`)} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: p.featured ? "#ea580c40" : "#27272a", borderRadius: 20, padding: 16, marginBottom: 12 }}>
              {p.featured && (
                <View style={{ position: "absolute", top: -1, right: 16, backgroundColor: "#ea580c", borderRadius: 10, paddingHorizontal: 10, paddingVertical: 3, zIndex: 1 }}>
                  <Text style={{ fontSize: 8, fontWeight: "900", textTransform: "uppercase", color: "#fff" }}>⭐ Destaque</Text>
                </View>
              )}
              <View style={{ flexDirection: "row", gap: 14 }}>
                <View style={{ width: 48, height: 48, borderRadius: 16, backgroundColor: "#ea580c33", alignItems: "center", justifyContent: "center" }}>
                  <Text style={{ fontSize: 22 }}>{CAT_ICONS[p.category] || "📖"}</Text>
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{p.title}</Text>
                  <Text style={{ fontSize: 10, color: "#71717a", marginTop: 4, lineHeight: 14 }}>{p.description}</Text>
                  <Text style={{ fontSize: 9, color: "#52525b", fontWeight: "800", textTransform: "uppercase", marginTop: 8 }}>{p.durationWeeks} semanas · {p.daysPerWeek}x/sem</Text>
                </View>
              </View>
            </TouchableOpacity>
          ))}
        </View>
      </ScrollView>
    </>
  );
}
