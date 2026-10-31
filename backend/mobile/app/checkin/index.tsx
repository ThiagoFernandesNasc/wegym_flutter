import { useCallback, useEffect, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator } from "react-native";
import { Stack } from "expo-router";
import { getCheckIn, getCheckInHistory, saveCheckIn } from "@/api/checkin";

const MOODS = [
  { v: 1, label: "😢", color: "#ef4444" }, { v: 2, label: "😕", color: "#f97316" },
  { v: 3, label: "😐", color: "#eab308" }, { v: 4, label: "😊", color: "#22c55e" }, { v: 5, label: "🔥", color: "#22c55e" },
];

export default function CheckinScreen() {
  const [mood, setMood] = useState(3);
  const [energy, setEnergy] = useState(3);
  const [sleepHours, setSleepHours] = useState("7");
  const [trained, setTrained] = useState(false);
  const [note, setNote] = useState("");
  const [saved, setSaved] = useState(false);
  const [streak, setStreak] = useState(0);
  const [loading, setLoading] = useState(true);
  const [history, setHistory] = useState<{ date: string; mood: number; energy: number; trained: boolean }[]>([]);
  const [showHistory, setShowHistory] = useState(false);

  const load = useCallback(async () => {
    try {
      const [checkinData, historyData] = await Promise.all([
        getCheckIn().catch(() => null),
        getCheckInHistory().catch(() => ({ checkIns: [], streak: 0 })),
      ]);
      if (checkinData) { setMood(checkinData.mood); setEnergy(checkinData.energy); setSleepHours(String(checkinData.sleepHours ?? "7")); setTrained(checkinData.trained ?? false); setNote(checkinData.note ?? ""); }
      setStreak(historyData?.streak ?? 0);
      setHistory(historyData?.checkIns ?? []);
    } catch { /* silent */ } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const handleSave = async () => {
    await saveCheckIn({ mood, energy, sleepHours: Number(sleepHours), trained, note });
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
    load();
  };

  return (
    <>
      <Stack.Screen options={{ title: "Check-in" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
            <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Check-in Diário</Text>
            {history.length > 0 && (
              <TouchableOpacity onPress={() => setShowHistory(!showHistory)} style={{ backgroundColor: "#27272a", borderRadius: 14, paddingHorizontal: 14, paddingVertical: 8 }}>
                <Text style={{ color: "#a1a1aa", fontSize: 10, fontWeight: "800", textTransform: "uppercase" }}>
                  {showHistory ? "Fechar" : "Histórico"}
                </Text>
              </TouchableOpacity>
            )}
          </View>

          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : (
            <>
              {streak > 0 && <Text style={{ color: "#10b981", fontSize: 14, fontWeight: "900", fontStyle: "italic", textAlign: "center", marginBottom: 16 }}>🔥 Sequência: {streak} dias</Text>}

              {/* History list */}
              {showHistory && history.length > 0 && (
                <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
                  <Text style={{ fontSize: 10, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 10 }}>Registros anteriores</Text>
                  {history.map((h, i) => (
                    <View key={i} style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 6, borderBottomWidth: i < history.length - 1 ? 1 : 0, borderBottomColor: "#27272a" }}>
                      <Text style={{ color: "#a1a1aa", fontSize: 11 }}>{new Date(h.date).toLocaleDateString("pt-BR", { day: "2-digit", month: "short" })}</Text>
                      <View style={{ flexDirection: "row", gap: 8 }}>
                        <Text style={{ fontSize: 14 }}>{MOODS[h.mood - 1]?.label}</Text>
                        <Text style={{ color: "#ea580c", fontSize: 11 }}>{h.trained ? "🏋️" : ""}</Text>
                      </View>
                    </View>
                  ))}
                </View>
              )}

              <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 20 }}>
                <Text style={{ fontSize: 10, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Humor</Text>
                <View style={{ flexDirection: "row", justifyContent: "center", gap: 8, marginBottom: 20 }}>
                  {MOODS.map((m) => (
                    <TouchableOpacity key={m.v} onPress={() => setMood(m.v)} style={{ padding: 12, borderRadius: 16, backgroundColor: mood === m.v ? "#27272a" : "#09090b", borderWidth: 1, borderColor: mood === m.v ? "#ea580c" : "#27272a", transform: mood === m.v ? [{ scale: 1.1 }] : [] }}>
                      <Text style={{ fontSize: 28 }}>{m.label}</Text>
                    </TouchableOpacity>
                  ))}
                </View>

                <Text style={{ fontSize: 10, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Energia</Text>
                <View style={{ flexDirection: "row", justifyContent: "center", gap: 8, marginBottom: 20 }}>
                  {MOODS.map((m) => (
                    <TouchableOpacity key={m.v} onPress={() => setEnergy(m.v)} style={{ padding: 12, borderRadius: 16, backgroundColor: energy === m.v ? "#27272a" : "#09090b", borderWidth: 1, borderColor: energy === m.v ? "#ea580c" : "#27272a", transform: energy === m.v ? [{ scale: 1.1 }] : [] }}>
                      <Text style={{ fontSize: 28 }}>{m.label}</Text>
                    </TouchableOpacity>
                  ))}
                </View>

                <Text style={{ fontSize: 10, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 8 }}>Horas de sono</Text>
                <TextInput value={sleepHours} onChangeText={setSleepHours} keyboardType="numeric" placeholderTextColor="#71717a" style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 20 }} />

                <TouchableOpacity onPress={() => setTrained(!trained)} style={{ flexDirection: "row", alignItems: "center", gap: 10, marginBottom: 20 }}>
                  <View style={{ width: 22, height: 22, borderRadius: 6, borderWidth: 2, borderColor: trained ? "#ea580c" : "#52525b", backgroundColor: trained ? "#ea580c" : "transparent", alignItems: "center", justifyContent: "center" }}>
                    {trained && <Text style={{ color: "#fff", fontSize: 12 }}>✓</Text>}
                  </View>
                  <Text style={{ color: "#fff", fontSize: 13, fontWeight: "800", textTransform: "uppercase" }}>Treinou hoje?</Text>
                </TouchableOpacity>

                <TextInput value={note} onChangeText={setNote} placeholder="Observação..." placeholderTextColor="#71717a" multiline numberOfLines={3} style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 20, minHeight: 60 }} />

                <TouchableOpacity onPress={handleSave} style={{ backgroundColor: "#ea580c", borderRadius: 14, padding: 16, alignItems: "center" }}>
                  <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>{saved ? "✓ Check-in salvo!" : "Salvar check-in"}</Text>
                </TouchableOpacity>
              </View>
            </>
          )}
        </View>
      </ScrollView>
    </>
  );
}
