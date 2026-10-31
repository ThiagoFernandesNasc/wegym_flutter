import { useCallback, useEffect, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, Alert, ActivityIndicator, Modal } from "react-native";
import { router, Stack } from "expo-router";
import { getGoals, createGoal, updateGoal, type Goal } from "@/api/goals";

const CATEGORIES = ["workout", "weight", "nutrition", "cardio", "custom"] as const;
const CAT_LABELS: Record<string, string> = { workout: "Treinos", weight: "Peso", nutrition: "Nutrição", cardio: "Cardio", custom: "Personalizado" };

export default function GoalsScreen() {
  const [goals, setGoals] = useState<Goal[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [title, setTitle] = useState("");
  const [category, setCategory] = useState("workout");
  const [metric, setMetric] = useState("sessions");
  const [targetValue, setTargetValue] = useState("10");
  const [endDate, setEndDate] = useState("");

  const load = useCallback(async () => {
    try { setGoals(await getGoals()); } catch { /* silent */ } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const handleCreate = async () => {
    if (!title.trim()) { Alert.alert("Atenção", "Título é obrigatório"); return; }
    await createGoal({ title, category, metric, targetValue: Number(targetValue), endDate: new Date(endDate).toISOString() });
    setShowForm(false); setTitle(""); setCategory("workout"); setMetric("sessions"); setTargetValue("10"); setEndDate(""); load();
  };

  const handleComplete = async (id: string, target: number) => {
    await updateGoal(id, { currentValue: target });
    load();
  };

  return (
    <>
      <Stack.Screen options={{ title: "Metas" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
            <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Metas</Text>
            <TouchableOpacity onPress={() => setShowForm(true)} style={{ backgroundColor: "#ea580c", borderRadius: 14, paddingHorizontal: 16, paddingVertical: 10 }}>
              <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>Nova Meta</Text>
            </TouchableOpacity>
          </View>

          <Modal visible={showForm} animationType="slide" transparent>
            <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.7)", justifyContent: "flex-end" }}>
              <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24 }}>
                <TextInput value={title} onChangeText={setTitle} placeholder="Título da meta" placeholderTextColor="#71717a" style={inputStyle} />
                <View style={{ flexDirection: "row", gap: 8, marginBottom: 12, flexWrap: "wrap" }}>
                  {CATEGORIES.map((c) => (
                    <TouchableOpacity key={c} onPress={() => setCategory(c)} style={{ backgroundColor: category === c ? "#ea580c" : "#27272a", borderRadius: 12, paddingHorizontal: 14, paddingVertical: 8 }}>
                      <Text style={{ color: "#fff", fontSize: 10, fontWeight: "800", textTransform: "uppercase" }}>{CAT_LABELS[c]}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
                <TextInput value={metric} onChangeText={setMetric} placeholder="Métrica (kg, km...)" placeholderTextColor="#71717a" style={inputStyle} />
                <TextInput value={targetValue} onChangeText={setTargetValue} placeholder="Valor alvo" placeholderTextColor="#71717a" keyboardType="numeric" style={inputStyle} />
                <TextInput value={endDate} onChangeText={setEndDate} placeholder="Data limite (AAAA-MM-DD)" placeholderTextColor="#71717a" style={inputStyle} />
                <View style={{ flexDirection: "row", gap: 12 }}>
                  <TouchableOpacity onPress={() => setShowForm(false)} style={{ flex: 1, backgroundColor: "#27272a", borderRadius: 14, padding: 14, alignItems: "center" }}>
                    <Text style={{ color: "#a1a1aa", fontSize: 12, fontWeight: "800", textTransform: "uppercase" }}>Cancelar</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={handleCreate} style={{ flex: 1, backgroundColor: "#ea580c", borderRadius: 14, padding: 14, alignItems: "center" }}>
                    <Text style={{ color: "#fff", fontSize: 12, fontWeight: "800", textTransform: "uppercase" }}>Salvar</Text>
                  </TouchableOpacity>
                </View>
              </View>
            </View>
          </Modal>

          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : goals.length === 0 ? (
            <View style={{ alignItems: "center", paddingTop: 60 }}>
              <Text style={{ fontSize: 48, marginBottom: 12 }}>🎯</Text>
              <Text style={{ color: "#71717a", fontSize: 14 }}>Nenhuma meta ainda</Text>
            </View>
          ) : goals.map((goal) => {
            const pct = Math.min(100, Math.round((goal.currentValue / goal.targetValue) * 100));
            return (
              <View key={goal.id} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: goal.status === "completed" ? "#10b981" : "#27272a", borderRadius: 20, padding: 16, marginBottom: 12 }}>
                <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                  <View style={{ flex: 1 }}>
                    <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{goal.title}</Text>
                    <Text style={{ fontSize: 10, color: "#71717a", marginTop: 4 }}>{goal.currentValue} / {goal.targetValue} {goal.metric}</Text>
                  </View>
                  <Text style={{ fontSize: 10, fontWeight: "800", color: goal.status === "completed" ? "#10b981" : "#3b82f6", textTransform: "uppercase" }}>{goal.status}</Text>
                </View>
                <View style={{ height: 6, backgroundColor: "#27272a", borderRadius: 3, marginTop: 12, overflow: "hidden" }}>
                  <View style={{ width: `${pct}%`, height: "100%", backgroundColor: goal.status === "completed" ? "#10b981" : "#ea580c", borderRadius: 3 }} />
                </View>
                {goal.status === "active" && (
                  <TouchableOpacity onPress={() => handleComplete(goal.id, goal.targetValue)} style={{ marginTop: 12 }}>
                    <Text style={{ color: "#10b981", fontSize: 10, fontWeight: "800", textTransform: "uppercase" }}>✓ Concluir</Text>
                  </TouchableOpacity>
                )}
              </View>
            );
          })}
        </View>
      </ScrollView>
    </>
  );
}

const inputStyle = { backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 12 };
