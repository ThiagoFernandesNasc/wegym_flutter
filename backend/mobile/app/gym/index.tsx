import { useState, useEffect, useRef, useMemo } from "react";
import { View, Text, TouchableOpacity, TextInput, ScrollView, Alert, Image, Modal } from "react-native";
import { router, Stack } from "expo-router";
import { createWorkout } from "@/api/workouts";
import { ExerciseItem } from "@/components/ExerciseItem";
import { AIChatModal } from "@/components/AIChat";
import { getExerciseGifUrl } from "@/data/exercise-gifs";
import { ALL_AVAILABLE_EXERCISES, MUSCLE_GROUPS, type Exercise } from "@/data/exercises";
import { BLEManager, type HRData, type BLEState } from "@/services/ble";

type WorkoutExercise = {
  id: string;
  name: string;
  sets: number;
  reps: string;
  load: string;
  muscle: string;
  completed: boolean;
};

export default function GymWorkoutScreen() {
  const [exercises, setExercises] = useState<WorkoutExercise[]>([]);
  const [searchText, setSearchText] = useState("");
  const [timer, setTimer] = useState(0);
  const [active, setActive] = useState(false);
  const [intervalId, setIntervalId] = useState<ReturnType<typeof setInterval> | null>(null);
  const [saving, setSaving] = useState(false);
  const [restTimer, setRestTimer] = useState(0);
  const [restActive, setRestActive] = useState(false);
  const [showAIChat, setShowAIChat] = useState(false);
  const [bleHR, setBleHR] = useState<HRData | null>(null);
  const [bleState, setBleState] = useState<BLEState>("idle");
  const bleRef = useRef<BLEManager | null>(null);

  // AI Generator state
  const [showAIGen, setShowAIGen] = useState(false);
  const [aiStep, setAiStep] = useState<"goal" | "result">("goal");
  const [aiGoal, setAiGoal] = useState<"bulk" | "cut">("bulk");
  const [aiLoading, setAiLoading] = useState(false);
  const [aiMessage, setAiMessage] = useState("");

  // Exercise browser state
  const [showBrowser, setShowBrowser] = useState(false);
  const [browserSearch, setBrowserSearch] = useState("");
  const [selectedMuscle, setSelectedMuscle] = useState<string | null>(null);

  useEffect(() => {
    const mgr = new BLEManager({
      onHR: (d) => setBleHR(d),
      onState: (s) => setBleState(s),
      onError: () => {},
    });
    bleRef.current = mgr;
    return () => mgr.destroy();
  }, []);

  const completedCount = exercises.filter((e) => e.completed).length;
  const totalCount = exercises.length;
  const progressPct = totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

  const addExercise = (ex: Exercise) => {
    setExercises((prev) => [
      ...prev,
      { id: Date.now().toString() + Math.random(), name: ex.name, sets: Number(ex.sets) || 3, reps: ex.reps, load: "20", muscle: ex.muscle, completed: false },
    ]);
  };

  const updateExercise = (id: string, field: "sets" | "reps" | "load", value: string) => {
    setExercises((prev) =>
      prev.map((e) => (e.id === id ? { ...e, [field]: field === "sets" ? Number(value) || 0 : value } : e)),
    );
  };

  const removeExercise = (id: string) => setExercises((prev) => prev.filter((e) => e.id !== id));

  const toggleExercise = (id: string) => {
    setExercises((prev) => prev.map((e) => e.id === id ? { ...e, completed: !e.completed } : e));
    startRestTimer();
  };

  const clearExercises = () => {
    Alert.alert("Limpar lista", "Remover todos os exercícios?", [
      { text: "Cancelar", style: "cancel" },
      { text: "Limpar", style: "destructive", onPress: () => setExercises([]) },
    ]);
  };

  const startTimer = () => {
    setActive(true);
    setTimer(0);
    const id = setInterval(() => setTimer((t) => t + 1), 1000);
    setIntervalId(id);
  };

  const stopTimer = () => {
    if (intervalId) clearInterval(intervalId);
    setIntervalId(null);
    setActive(false);
    setRestActive(false);
  };

  const startRestTimer = () => {
    setRestTimer(60);
    setRestActive(true);
    if (intervalId) { clearInterval(intervalId); setIntervalId(null); }
    const id = setInterval(() => {
      setRestTimer((t) => {
        if (t <= 1) { setRestActive(false); return 0; }
        return t - 1;
      });
    }, 1000);
    setIntervalId(id);
  };

  const skipRest = () => {
    setRestActive(false);
    setRestTimer(0);
    if (!active) startTimer();
  };

  // AI Generator: match web's approach (filter exercises by muscle groups)
  const generateAIWorkout = (goal: "bulk" | "cut") => {
    setAiLoading(true);
    setAiGoal(goal);
    setAiStep("result");

    // Simulate AI delay like web does with setTimeout
    setTimeout(() => {
      const dayTargets = [
        { muscles: ["Peito", "Ombros", "Tríceps"] },
        { muscles: ["Costas", "Bíceps"] },
        { muscles: ["Pernas", "Panturrilha", "Glúteos"] },
        { muscles: ["Core"] },
        { muscles: ["Peito", "Costas", "Ombros"] },
        { muscles: ["Pernas", "Glúteos"] },
      ];

      const allExercises: WorkoutExercise[] = [];
      dayTargets.forEach((target) => {
        const filtered = ALL_AVAILABLE_EXERCISES.filter((ex) =>
          target.muscles.some((m) => ex.muscle === m)
        );
        const picked = filtered.slice(0, 4);
        picked.forEach((ex) => {
          allExercises.push({
            id: Date.now().toString() + Math.random(),
            name: ex.name,
            sets: goal === "bulk" ? 4 : 3,
            reps: goal === "bulk" ? "8-12" : "15-20",
            load: "20",
            muscle: ex.muscle,
            completed: false,
          });
        });
      });

      setExercises(allExercises);
      setAiMessage(goal === "bulk"
        ? "🔥 Treino Bulk gerado! Foco em hipertrofia (4x8-12)"
        : "💧 Treino Cut gerado! Foco em definição (3x15-20)");
      setAiLoading(false);
    }, 1000);
  };

  const filteredBrowserExercises = useMemo(() => {
    let list = ALL_AVAILABLE_EXERCISES;
    if (selectedMuscle) list = list.filter((e) => e.muscle === selectedMuscle);
    if (browserSearch.trim()) {
      const q = browserSearch.toLowerCase();
      list = list.filter((e) => e.name.toLowerCase().includes(q) || e.muscle.toLowerCase().includes(q));
    }
    return list;
  }, [selectedMuscle, browserSearch]);

  // Quick search suggestions from full list
  const filteredSuggestions = useMemo(() => {
    if (!searchText.trim()) return [];
    const q = searchText.toLowerCase();
    return ALL_AVAILABLE_EXERCISES.filter(
      (e) => e.name.toLowerCase().includes(q) && !exercises.some((ex) => ex.name === e.name)
    ).slice(0, 8);
  }, [searchText, exercises]);

  const handleSave = async () => {
    if (exercises.length === 0) {
      Alert.alert("Atenção", "Adicione pelo menos um exercício");
      return;
    }
    stopTimer();
    setSaving(true);
    try {
      await createWorkout({ modality: "musculacao", durationSec: timer });
      Alert.alert("Treino salvo!", `${exercises.length} exercícios registrados · ${formatTime(timer)}`, [
        { text: "OK", onPress: () => router.back() },
      ]);
    } catch { Alert.alert("Erro", "Não foi possível salvar o treino"); } finally { setSaving(false); }
  };

  return (
    <View style={{ flex: 1, backgroundColor: "#09090b" }}>
      <Stack.Screen options={{ headerShown: false }} />
      <ScrollView contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
        {/* Header */}
        <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 24 }}>
          <TouchableOpacity onPress={() => router.back()}>
            <Text style={{ color: "#ea580c", fontSize: 14, fontWeight: "800" }}>{"< Voltar"}</Text>
          </TouchableOpacity>
          <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>
            {restActive ? formatTime(restTimer) : formatTime(timer)}
          </Text>
          <View style={{ flexDirection: "row", gap: 8 }}>
            {!active && !restActive ? (
              <TouchableOpacity onPress={startTimer} style={{ backgroundColor: "#22c55e", borderRadius: 12, paddingHorizontal: 16, paddingVertical: 8 }}>
                <Text style={{ color: "#fff", fontSize: 11, fontWeight: "800" }}>INICIAR</Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity onPress={stopTimer} style={{ backgroundColor: "#dc2626", borderRadius: 12, paddingHorizontal: 16, paddingVertical: 8 }}>
                <Text style={{ color: "#fff", fontSize: 11, fontWeight: "800" }}>PAUSAR</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* BLE Heart Rate Strip */}
        {bleState === "connected" && bleHR && (
          <View style={{ backgroundColor: "#dc262610", borderWidth: 1, borderColor: "#dc262620", borderRadius: 14, padding: 10, marginBottom: 12, flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8 }}>
            <Text style={{ fontSize: 20 }}>❤️</Text>
            <Text style={{ fontSize: 22, fontWeight: "900", fontStyle: "italic", color: "#dc2626", fontVariant: ["tabular-nums"] }}>{bleHR.bpm}</Text>
            <Text style={{ fontSize: 9, color: "#71717a", textTransform: "uppercase" }}>BPM</Text>
            <TouchableOpacity onPress={() => bleRef.current?.disconnect()} style={{ backgroundColor: "#27272a", borderRadius: 8, paddingHorizontal: 10, paddingVertical: 4 }}>
              <Text style={{ color: "#71717a", fontSize: 9, fontWeight: "800" }}>✕</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Progress Bar */}
        {totalCount > 0 && (
          <View style={{ marginBottom: 16 }}>
            <View style={{ flexDirection: "row", justifyContent: "space-between", marginBottom: 4 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a" }}>
                Exercícios {completedCount}/{totalCount}
              </Text>
              <Text style={{ fontSize: 9, fontWeight: "900", color: "#ea580c" }}>{Math.round(progressPct)}%</Text>
            </View>
            <View style={{ height: 8, backgroundColor: "#27272a", borderRadius: 4, overflow: "hidden" }}>
              <View style={{ width: `${progressPct}%`, height: "100%", backgroundColor: "#ea580c", borderRadius: 4 }} />
            </View>
          </View>
        )}

        {/* AI Generator Button */}
        <View style={{ flexDirection: "row", gap: 8, marginBottom: 16 }}>
          <TouchableOpacity onPress={() => { setShowAIGen(true); setAiStep("goal"); }} style={{ flex: 1, backgroundColor: "#18181b", borderWidth: 1, borderColor: "#ea580c40", borderRadius: 14, padding: 14, alignItems: "center" }}>
            <Text style={{ fontSize: 10, fontWeight: "900", textTransform: "uppercase", color: "#ea580c" }}>🤖 Gerar treino IA</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => setShowBrowser(true)} style={{ flex: 1, backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 14, padding: 14, alignItems: "center" }}>
            <Text style={{ fontSize: 10, fontWeight: "900", textTransform: "uppercase", color: "#a1a1aa" }}>📋 Adicionar exercícios</Text>
          </TouchableOpacity>
          {exercises.length > 0 && (
            <TouchableOpacity onPress={clearExercises} style={{ backgroundColor: "#dc262610", borderRadius: 14, padding: 14, justifyContent: "center", borderWidth: 1, borderColor: "#dc262620" }}>
              <Text style={{ color: "#ef4444", fontSize: 14 }}>🗑️</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Rest timer overlay */}
        {restActive && (
          <View style={{ backgroundColor: "#facc1520", borderWidth: 1, borderColor: "#facc15", borderRadius: 14, padding: 12, alignItems: "center", marginBottom: 12, flexDirection: "row", justifyContent: "center", gap: 12 }}>
            <Text style={{ color: "#facc15", fontSize: 11, fontWeight: "900" }}>Descanso {formatTime(restTimer)}</Text>
            <TouchableOpacity onPress={skipRest} style={{ backgroundColor: "#27272a", borderRadius: 8, paddingHorizontal: 12, paddingVertical: 6 }}>
              <Text style={{ color: "#fff", fontSize: 10, fontWeight: "800" }}>Pular</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Exercise list */}
        {exercises.map((ex) => (
          <ExerciseItem
            key={ex.id}
            name={ex.name}
            sets={String(ex.sets)}
            reps={ex.reps}
            load={ex.load}
            muscle={ex.muscle}
            completed={ex.completed}
            onToggle={() => toggleExercise(ex.id)}
            onUpdateSets={(v) => updateExercise(ex.id, "sets", v)}
            onUpdateReps={(v) => updateExercise(ex.id, "reps", v)}
            onUpdateLoad={(v) => updateExercise(ex.id, "load", v)}
            onRemove={() => removeExercise(ex.id)}
          />
        ))}

        {exercises.length === 0 && (
          <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 24, alignItems: "center", marginBottom: 12 }}>
            <Text style={{ fontSize: 36, marginBottom: 8 }}>💪</Text>
            <Text style={{ fontSize: 12, color: "#71717a" }}>Nenhum exercício adicionado</Text>
            <Text style={{ fontSize: 10, color: "#52525b", marginTop: 4, textAlign: "center" }}>Use o gerador IA ou navegue pelos 87 exercícios disponíveis</Text>
          </View>
        )}

        {/* Search + quick add */}
        <View style={{ marginTop: 12, marginBottom: 24 }}>
          <TextInput
            placeholder="Buscar exercício (87 disponíveis)..."
            placeholderTextColor="#71717a"
            value={searchText}
            onChangeText={setSearchText}
            style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 16, fontSize: 15, color: "#fff" }}
          />
          {filteredSuggestions.length > 0 && searchText.length > 0 && (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 12, marginTop: 4, overflow: "hidden" }}>
              {filteredSuggestions.map((s) => {
                const gifUrl = getExerciseGifUrl(s.name);
                return (
                  <TouchableOpacity key={s.id} onPress={() => { addExercise(s); setSearchText(""); }} style={{ padding: 12, borderBottomWidth: 1, borderBottomColor: "#27272a", flexDirection: "row", alignItems: "center", gap: 10 }}>
                    {gifUrl && <Image source={{ uri: gifUrl }} style={{ width: 32, height: 32, borderRadius: 8 }} />}
                    <View style={{ flex: 1 }}>
                      <Text style={{ color: "#a1a1aa", fontSize: 13 }}>{s.name}</Text>
                      <Text style={{ color: "#52525b", fontSize: 9, textTransform: "uppercase" }}>{s.muscle}</Text>
                    </View>
                    <Text style={{ color: "#ea580c", fontSize: 12 }}>+</Text>
                  </TouchableOpacity>
                );
              })}
            </View>
          )}
        </View>

        {/* Save button */}
        {exercises.length > 0 && (
          <TouchableOpacity onPress={handleSave} disabled={saving} style={{ backgroundColor: "#ea580c", borderRadius: 20, padding: 20, alignItems: "center", marginBottom: 40 }}>
            <Text style={{ color: "#fff", fontSize: 15, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase" }}>
              {saving ? "Salvando..." : "Finalizar Treino"}
            </Text>
          </TouchableOpacity>
        )}
      </ScrollView>

      {/* AI Chat FAB */}
      <TouchableOpacity onPress={() => setShowAIChat(true)} style={{ position: "absolute", bottom: 24, right: 20, backgroundColor: "#ea580c", borderRadius: 28, width: 56, height: 56, alignItems: "center", justifyContent: "center", shadowColor: "#ea580c", shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.4, shadowRadius: 8, elevation: 8 }}>
        <Text style={{ color: "#fff", fontSize: 22 }}>🤖</Text>
      </TouchableOpacity>

      <AIChatModal visible={showAIChat} onClose={() => setShowAIChat(false)} />

      {/* AI Generator Modal */}
      <Modal visible={showAIGen} animationType="slide" transparent>
        <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.85)", justifyContent: "flex-end" }}>
          <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24, minHeight: 300 }}>
            <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
              <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>🤖 WEGYM AI</Text>
              <TouchableOpacity onPress={() => { setShowAIGen(false); setAiStep("goal"); }}><Text style={{ color: "#71717a", fontSize: 18 }}>✕</Text></TouchableOpacity>
            </View>

            {aiStep === "goal" && (
              <>
                <Text style={{ color: "#a1a1aa", fontSize: 12, marginBottom: 20, textAlign: "center" }}>
                  Escolha seu objetivo para gerar um treino completo para a semana
                </Text>
                <TouchableOpacity onPress={() => generateAIWorkout("bulk")} disabled={aiLoading} style={{ backgroundColor: "#dc2626", borderRadius: 16, padding: 20, alignItems: "center", marginBottom: 12 }}>
                  <Text style={{ fontSize: 28, marginBottom: 4 }}>🏋️</Text>
                  <Text style={{ color: "#fff", fontSize: 16, fontWeight: "900", fontStyle: "italic" }}>Bulk</Text>
                  <Text style={{ color: "#fca5a5", fontSize: 10, marginTop: 4 }}>Hipertrofia · 4 séries · 8-12 reps</Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={() => generateAIWorkout("cut")} disabled={aiLoading} style={{ backgroundColor: "#22c55e", borderRadius: 16, padding: 20, alignItems: "center" }}>
                  <Text style={{ fontSize: 28, marginBottom: 4 }}>💧</Text>
                  <Text style={{ color: "#fff", fontSize: 16, fontWeight: "900", fontStyle: "italic" }}>Cut</Text>
                  <Text style={{ color: "#bbf7d0", fontSize: 10, marginTop: 4 }}>Definição · 3 séries · 15-20 reps</Text>
                </TouchableOpacity>
              </>
            )}

            {aiStep === "result" && (
              <View style={{ alignItems: "center", paddingVertical: 24 }}>
                {aiLoading ? (
                  <>
                    <Text style={{ fontSize: 40, marginBottom: 12 }}>🤖</Text>
                    <Text style={{ color: "#71717a", fontSize: 13 }}>Gerando treino ideal...</Text>
                  </>
                ) : (
                  <>
                    <Text style={{ fontSize: 40, marginBottom: 12 }}>{aiGoal === "bulk" ? "🏋️" : "💧"}</Text>
                    <Text style={{ color: "#22c55e", fontSize: 14, fontWeight: "900", textAlign: "center", marginBottom: 8 }}>{aiMessage}</Text>
                    <Text style={{ color: "#71717a", fontSize: 11, textAlign: "center", marginBottom: 20 }}>
                      {exercises.length} exercícios adicionados
                    </Text>
                    <TouchableOpacity onPress={() => { setShowAIGen(false); setAiStep("goal"); }} style={{ backgroundColor: "#ea580c", borderRadius: 14, paddingHorizontal: 32, paddingVertical: 14 }}>
                      <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>OK</Text>
                    </TouchableOpacity>
                  </>
                )}
              </View>
            )}
          </View>
        </View>
      </Modal>

      {/* Exercise Browser Modal */}
      <Modal visible={showBrowser} animationType="slide" transparent>
        <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.9)", justifyContent: "flex-end" }}>
          <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 24, borderTopRightRadius: 24, maxHeight: "85%", padding: 20 }}>
            <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
              <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>📋 Exercícios</Text>
              <TouchableOpacity onPress={() => { setShowBrowser(false); setBrowserSearch(""); setSelectedMuscle(null); }}><Text style={{ color: "#71717a", fontSize: 18 }}>✕</Text></TouchableOpacity>
            </View>

            {/* Search */}
            <TextInput value={browserSearch} onChangeText={setBrowserSearch} placeholder="Buscar exercício..." placeholderTextColor="#71717a" style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 12, fontSize: 13, color: "#fff", marginBottom: 10 }} />

            {/* Muscle group filter chips */}
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 10 }}>
              <View style={{ flexDirection: "row", gap: 6 }}>
                <TouchableOpacity onPress={() => setSelectedMuscle(null)} style={{ paddingHorizontal: 14, paddingVertical: 6, borderRadius: 20, backgroundColor: !selectedMuscle ? "#ea580c" : "#27272a" }}>
                  <Text style={{ color: !selectedMuscle ? "#fff" : "#71717a", fontSize: 9, fontWeight: "800", textTransform: "uppercase" }}>Todos</Text>
                </TouchableOpacity>
                {MUSCLE_GROUPS.map((m) => (
                  <TouchableOpacity key={m} onPress={() => setSelectedMuscle(m)} style={{ paddingHorizontal: 14, paddingVertical: 6, borderRadius: 20, backgroundColor: selectedMuscle === m ? "#ea580c" : "#27272a" }}>
                    <Text style={{ color: selectedMuscle === m ? "#fff" : "#71717a", fontSize: 9, fontWeight: "800", textTransform: "uppercase" }}>{m}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </ScrollView>

            {/* Exercise list */}
            <ScrollView style={{ maxHeight: 400 }}>
              {filteredBrowserExercises.length === 0 ? (
                <Text style={{ color: "#71717a", fontSize: 12, textAlign: "center", marginTop: 20 }}>Nenhum exercício encontrado</Text>
              ) : filteredBrowserExercises.map((ex) => {
                const gifUrl = getExerciseGifUrl(ex.name);
                const alreadyAdded = exercises.some((e) => e.name === ex.name);
                return (
                  <TouchableOpacity key={ex.id} onPress={() => { if (!alreadyAdded) { addExercise(ex); } }} disabled={alreadyAdded} style={{ backgroundColor: alreadyAdded ? "#22c55e10" : "#09090b", borderWidth: 1, borderColor: alreadyAdded ? "#22c55e30" : "#27272a", borderRadius: 16, padding: 14, marginBottom: 6, flexDirection: "row", alignItems: "center", gap: 10 }}>
                    {gifUrl && <Image source={{ uri: gifUrl }} style={{ width: 40, height: 40, borderRadius: 10 }} />}
                    <View style={{ flex: 1 }}>
                      <Text style={{ fontSize: 12, fontWeight: "900", fontStyle: "italic", color: alreadyAdded ? "#22c55e" : "#fff" }}>{ex.name}</Text>
                      <View style={{ flexDirection: "row", gap: 8, marginTop: 2 }}>
                        <Text style={{ color: "#ea580c", fontSize: 9, fontWeight: "800", textTransform: "uppercase" }}>{ex.muscle}</Text>
                        <Text style={{ color: "#52525b", fontSize: 9 }}>{ex.sets}x{ex.reps}</Text>
                      </View>
                    </View>
                    {alreadyAdded ? (
                      <Text style={{ color: "#22c55e", fontSize: 10, fontWeight: "900" }}>✓</Text>
                    ) : (
                      <Text style={{ color: "#ea580c", fontSize: 16 }}>+</Text>
                    )}
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
        </View>
      </Modal>
    </View>
  );
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}
