import { useEffect, useState, useCallback } from "react";
import { View, Text, ActivityIndicator, ScrollView, TouchableOpacity, RefreshControl, TextInput } from "react-native";
import { router } from "expo-router";
import { getWorkouts, createWorkout } from "@/api/workouts";
import { getTrainingPlan, type TrainingPlanExercise } from "@/api/training-plans";
import type { WorkoutSession } from "@/api/workouts";
import { getProfile } from "@/api/auth";
import SessionDetailModal from "@/components/SessionDetailModal";

const MODALITIES = [
  { id: "musculacao", label: "Musculação", icon: "🏋️", color: "#ea580c", type: "gym" },
  { id: "corrida", label: "Corrida", icon: "🏃", color: "#22c55e", type: "gps" },
  { id: "ciclismo", label: "Ciclismo", icon: "🚴", color: "#3b82f6", type: "gps" },
  { id: "natacao", label: "Natação", icon: "🏊", color: "#06b6d4", type: "timer" },
  { id: "caminhada", label: "Caminhada", icon: "🚶", color: "#a855f7", type: "gps" },
  { id: "cardio", label: "Cardio", icon: "❤️", color: "#dc2626", type: "timer" },
  { id: "aerobico", label: "Aeróbico", icon: "❤️‍🔥", color: "#dc2626", type: "timer" },
  { id: "combat", label: "Combate", icon: "⚔️", color: "#ef4444", type: "timer" },
  { id: "crossfit", label: "Cross Training", icon: "🔥", color: "#f97316", type: "timer" },
  { id: "yoga", label: "Yoga & Pilates", icon: "🧘", color: "#a855f7", type: "timer" },
  { id: "hiking", label: "Trilha", icon: "⛰️", color: "#22c55e", type: "gps" },
  { id: "basquete", label: "Basquete", icon: "🏀", color: "#ea580c", type: "timer" },
  { id: "futebol", label: "Futebol", icon: "⚽", color: "#22c55e", type: "timer" },
  { id: "tenis", label: "Tênis", icon: "🎾", color: "#3b82f6", type: "timer" },
  { id: "escalada", label: "Escalada", icon: "🧗", color: "#facc15", type: "timer" },
  { id: "skate", label: "Skate", icon: "🛹", color: "#f97316", type: "timer" },
  { id: "funcional", label: "Funcional", icon: "⚡", color: "#8b5cf6", type: "timer" },
  { id: "hiit", label: "HIIT", icon: "💥", color: "#dc2626", type: "timer" },
  { id: "danca", label: "Dança", icon: "💃", color: "#ec4899", type: "timer" },
  { id: "remo", label: "Remo", icon: "🚣", color: "#06b6d4", type: "timer" },
  { id: "outros", label: "Outros", icon: "📋", color: "#71717a", type: "timer" },
];

const DAY_LABELS = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];

export default function TrainingScreen() {
  const [sessions, setSessions] = useState<WorkoutSession[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [planExercises, setPlanExercises] = useState<TrainingPlanExercise[]>([]);
  const [selectedModality, setSelectedModality] = useState<string>("todos");
  const [detailSession, setDetailSession] = useState<WorkoutSession | null>(null);
  const [showDetail, setShowDetail] = useState(false);

  const [timer, setTimer] = useState(0);
  const [timerActive, setTimerActive] = useState(false);
  const [exercises, setExercises] = useState<{ name: string; sets: string; reps: string; load: string }[]>([]);
  const [exName, setExName] = useState(""); const [exSets, setExSets] = useState("4"); const [exReps, setExReps] = useState("10"); const [exLoad, setExLoad] = useState("");

  const loadSessions = useCallback(async () => {
    try {
      const res = await getWorkouts();
      setSessions(res.data);
    } catch { /* silent */ } finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { loadSessions(); }, [loadSessions]);

  const loadPlan = async () => {
    try {
      const profile = await getProfile();
      const role = (profile as { role: string }).role;
      if (role === "atleta") {
        const res = await getTrainingPlan((profile as { id: string }).id);
        setPlanExercises(Array.isArray(res) ? res : (res as { data: TrainingPlanExercise[] }).data ?? []);
      }
    } catch { /* silent */ }
  };

  useEffect(() => { loadPlan(); }, []);

  useEffect(() => {
    let interval: ReturnType<typeof setInterval>;
    if (timerActive) { interval = setInterval(() => setTimer((t) => t + 1), 1000); }
    return () => { if (interval) clearInterval(interval); };
  }, [timerActive]);

  const openTraining = (mod: typeof MODALITIES[number]) => {
    if (mod.type === "gym") router.push("/gym");
    else if (mod.type === "gps") router.push(`/gps/${mod.id}`);
    else router.push(`/training/${mod.id}`);
  };

  const addExercise = () => {
    if (!exName.trim()) return;
    setExercises([...exercises, { name: exName, sets: exSets, reps: exReps, load: exLoad }]);
    setExName(""); setExSets("4"); setExReps("10"); setExLoad("");
  };

  const finishGymWorkout = async () => {
    if (exercises.length === 0) return;
    await createWorkout({ modality: "musculacao", durationSec: timer });
    setExercises([]); setTimer(0); setTimerActive(false);
  };

  const todayIdx = new Date().getDay();

  const todayExercises = planExercises.filter((e) => e.dayOfWeek === todayIdx);

  const filteredSessions = selectedModality === "todos"
    ? sessions
    : sessions.filter((s) => s.modality === selectedModality);

  const openDetail = (s: WorkoutSession) => {
    setDetailSession(s);
    setShowDetail(true);
  };

  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: "#09090b" }}
      contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 100 }}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadSessions(); }} tintColor="#ea580c" />}
    >
      <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 4 }}>Treinos</Text>
      <Text style={{ fontSize: 12, color: "#a1a1aa", marginBottom: 20 }}>Escolha sua modalidade</Text>

      {/* ---- TODAY SNAPSHOT ---- */}
      {todayExercises.length > 0 && (
        <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 12 }}>
            <View style={{ width: 28, height: 28, borderRadius: 14, backgroundColor: "#ea580c20", justifyContent: "center", alignItems: "center" }}>
              <Text style={{ fontSize: 14 }}>📋</Text>
            </View>
            <Text style={{ fontSize: 11, fontWeight: "900", textTransform: "uppercase", color: "#ea580c", flex: 1 }}>Hoje</Text>
            <Text style={{ fontSize: 9, color: "#71717a", fontWeight: "700" }}>{todayExercises.length} exercícios</Text>
          </View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 8 }}>
            <View style={{ flexDirection: "row", gap: 8 }}>
              {todayExercises.slice(0, 5).map((ex) => (
                <View key={ex.id} style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#27272a", borderRadius: 14, padding: 12, minWidth: 120 }}>
                  <Text style={{ fontSize: 12, fontWeight: "700", color: "#fff", marginBottom: 4 }} numberOfLines={1}>
                    {ex.name}
                  </Text>
                  <Text style={{ fontSize: 9, color: "#71717a" }}>{ex.sets}×{ex.reps}</Text>
                  {ex.load ? <Text style={{ fontSize: 9, color: "#ea580c" }}>{ex.load} kg</Text> : null}
                </View>
              ))}
              {todayExercises.length > 5 && (
                <View style={{ justifyContent: "center", paddingHorizontal: 8 }}>
                  <Text style={{ fontSize: 9, color: "#71717a", fontWeight: "700" }}>+{todayExercises.length - 5}</Text>
                </View>
              )}
            </View>
          </ScrollView>
          <TouchableOpacity
            onPress={() => openTraining(MODALITIES[0])}
            style={{ backgroundColor: "#ea580c", borderRadius: 12, padding: 10, alignItems: "center" }}
          >
            <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>Treinar agora</Text>
          </TouchableOpacity>
        </View>
      )}

      {/* ---- MODALITIES GRID ---- */}
      <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10, marginBottom: 24 }}>
        {MODALITIES.map((mod) => (
          <TouchableOpacity
            key={mod.id}
            onPress={() => openTraining(mod)}
            style={{ width: "47%", backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, alignItems: "center" }}
          >
            <Text style={{ fontSize: 30, marginBottom: 6 }}>{mod.icon}</Text>
            <Text style={{ fontSize: 12, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase", color: "#fff" }}>{mod.label}</Text>
            <View style={{ backgroundColor: mod.color + "20", borderRadius: 10, paddingHorizontal: 10, paddingVertical: 2, marginTop: 6 }}>
              <Text style={{ fontSize: 8, fontWeight: "800", textTransform: "uppercase", color: mod.color }}>
                {mod.type === "gps" ? "GPS" : mod.type === "gym" ? "Séries" : "Timer"}
              </Text>
            </View>
          </TouchableOpacity>
        ))}
      </View>

      {/* ---- QUICK GYM WORKOUT ---- */}
      <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
        <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Treino de musculação rápido</Text>
        <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 16, marginBottom: 12 }}>
          <TouchableOpacity onPress={() => setTimerActive(!timerActive)} style={{ backgroundColor: timerActive ? "#ef4444" : "#ea580c", borderRadius: 12, paddingHorizontal: 20, paddingVertical: 10 }}>
            <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900" }}>{timerActive ? "PAUSAR" : "INICIAR"}</Text>
          </TouchableOpacity>
          <Text style={{ fontSize: 28, fontWeight: "900", fontStyle: "italic", color: "#fff", fontVariant: ["tabular-nums"] }}>
            {String(Math.floor(timer / 60)).padStart(2, "0")}:{String(timer % 60).padStart(2, "0")}
          </Text>
          <TouchableOpacity onPress={() => { setTimer(0); setTimerActive(false); }} style={{ backgroundColor: "#27272a", borderRadius: 12, paddingHorizontal: 16, paddingVertical: 10 }}>
            <Text style={{ color: "#71717a", fontSize: 12, fontWeight: "900" }}>RESET</Text>
          </TouchableOpacity>
        </View>

        <View style={{ flexDirection: "row", gap: 6, marginBottom: 8 }}>
          <TextInput value={exName} onChangeText={setExName} placeholder="Exercício" placeholderTextColor="#52525b" style={{ flex: 2, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 8, fontSize: 11, color: "#fff" }} />
          <TextInput value={exSets} onChangeText={setExSets} placeholder="S" keyboardType="numeric" style={{ width: 36, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 8, fontSize: 11, color: "#fff", textAlign: "center" }} />
          <TextInput value={exReps} onChangeText={setExReps} placeholder="R" keyboardType="numeric" style={{ width: 36, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 8, fontSize: 11, color: "#fff", textAlign: "center" }} />
          <TextInput value={exLoad} onChangeText={setExLoad} placeholder="Kg" keyboardType="numeric" style={{ width: 44, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 8, fontSize: 11, color: "#fff", textAlign: "center" }} />
          <TouchableOpacity onPress={addExercise} style={{ backgroundColor: "#ea580c", borderRadius: 10, padding: 8, justifyContent: "center" }}><Text style={{ color: "#fff", fontSize: 16 }}>+</Text></TouchableOpacity>
        </View>
        {exercises.map((ex, i) => (
          <View key={i} style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 6, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
            <Text style={{ color: "#d4d4d8", fontSize: 12 }}>{ex.name}</Text>
            <Text style={{ color: "#71717a", fontSize: 11 }}>{ex.sets}x{ex.reps}{ex.load ? ` ${ex.load}kg` : ""}</Text>
          </View>
        ))}
        {exercises.length > 0 && (
          <TouchableOpacity onPress={finishGymWorkout} style={{ backgroundColor: "#10b981", borderRadius: 12, padding: 12, alignItems: "center", marginTop: 10 }}>
            <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Finalizar treino</Text>
          </TouchableOpacity>
        )}
      </View>

      {/* ---- MODALITY HISTORY FILTER ---- */}
      <View style={{ marginBottom: 16 }}>
        <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 10 }}>
          Histórico nesta modalidade
        </Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 12 }}>
          <View style={{ flexDirection: "row", gap: 6, paddingRight: 20 }}>
            {[{ id: "todos", label: "Todos", icon: "📋", color: "#ea580c" }, ...MODALITIES].map((m) => (
              <TouchableOpacity
                key={m.id}
                onPress={() => setSelectedModality(m.id)}
                style={{ paddingHorizontal: 16, paddingVertical: 8, borderRadius: 20, backgroundColor: selectedModality === m.id ? m.color : "#27272a" }}
              >
                <Text style={{ fontSize: 10, fontWeight: "800", textTransform: "uppercase", color: selectedModality === m.id ? "#fff" : "#71717a" }}>
                  {m.icon} {m.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </ScrollView>
      </View>

      {/* ---- SESSION HISTORY LIST (tappable) ---- */}
      {loading ? (
        <ActivityIndicator size="small" color="#ea580c" style={{ marginTop: 20 }} />
      ) : filteredSessions.length === 0 ? (
        <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 32, alignItems: "center", marginTop: 8 }}>
          <Text style={{ fontSize: 40, marginBottom: 12 }}>💪</Text>
          <Text style={{ color: "#71717a", fontSize: 14, textAlign: "center" }}>Nenhuma sessão ainda</Text>
        </View>
      ) : (
        filteredSessions.slice(0, 20).map((s) => (
          <TouchableOpacity
            key={s.id}
            onPress={() => openDetail(s)}
            style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 14, marginBottom: 8, flexDirection: "row", justifyContent: "space-between" }}
          >
            <View style={{ flex: 1 }}>
              <Text style={{ fontSize: 13, fontWeight: "800", fontStyle: "italic", color: "#fff", textTransform: "capitalize" }}>{s.modality}</Text>
              <Text style={{ fontSize: 10, color: "#a1a1aa", marginTop: 2 }}>
                {formatDate(s.completedAt)} · {formatDuration(s.durationSec)}
              </Text>
            </View>
            <View style={{ alignItems: "flex-end" }}>
              {s.distanceKm != null && <Text style={{ fontSize: 11, color: "#ea580c", fontWeight: "700" }}>{s.distanceKm.toFixed(2)} km</Text>}
              {s.calories != null && <Text style={{ fontSize: 9, color: "#71717a", marginTop: 2 }}>{Math.round(s.calories)} kcal</Text>}
            </View>
          </TouchableOpacity>
        ))
      )}

      {/* ---- SESSION DETAIL MODAL ---- */}
      <SessionDetailModal
        visible={showDetail}
        session={detailSession ? {
          id: detailSession.id,
          at: detailSession.completedAt,
          durationSec: detailSession.durationSec,
          distanceKm: detailSession.distanceKm ?? undefined,
          avgPaceSecPerKm: detailSession.avgPaceSecPerKm ?? undefined,
          steps: detailSession.steps ?? undefined,
          coordinates: (detailSession as unknown as { coordinates?: { latitude: number; longitude: number }[] }).coordinates,
        } : null}
        onClose={() => setShowDetail(false)}
      />
    </ScrollView>
  );
}

function formatDate(iso: string): string {
  try {
    return new Date(iso).toLocaleDateString("pt-BR", { day: "2-digit", month: "short" });
  } catch { return iso; }
}

function formatDuration(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return h > 0 ? `${h}h${String(m).padStart(2, "0")}` : `${m}min`;
}
