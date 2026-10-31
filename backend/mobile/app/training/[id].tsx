import { useState } from "react";
import { View, Text, TouchableOpacity, Alert, TextInput } from "react-native";
import { useLocalSearchParams, router } from "expo-router";
import { createWorkout } from "@/api/workouts";

const MODALITY_LABELS: Record<string, string> = {
  natacao: "Natação",
  cardio: "Cardio",
  aerobico: "Aeróbico",
  combat: "Combate",
  crossfit: "Cross Training",
  yoga: "Yoga & Pilates",
  basquete: "Basquete",
  futebol: "Futebol",
  tenis: "Tênis",
  escalada: "Escalada",
  skate: "Skate",
  funcional: "Funcional",
  hiit: "HIIT",
  danca: "Dança",
  remo: "Remo",
  outros: "Outros",
};

const POOL_LENGTHS = [25, 33, 50];

export default function TrainingDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [duration, setDuration] = useState(0);
  const [active, setActive] = useState(false);
  const [intervalId, setIntervalId] = useState<ReturnType<typeof setInterval> | null>(null);
  const [poolLength, setPoolLength] = useState(25);
  const [laps, setLaps] = useState(0);
  const [customPool, setCustomPool] = useState("");

  const label = MODALITY_LABELS[id ?? ""] ?? id;
  const isSwimming = id === "natacao";
  const totalDistance = isSwimming ? laps * (customPool ? Number(customPool) : poolLength) : 0;

  const startTimer = () => {
    setActive(true);
    setDuration(0);
    const id_ = setInterval(() => setDuration((prev) => prev + 1), 1000);
    setIntervalId(id_);
  };

  const stopTimer = () => {
    if (intervalId) clearInterval(intervalId);
    setIntervalId(null);
    setActive(false);
  };

  const incrementLap = () => setLaps((l) => l + 1);
  const decrementLap = () => setLaps((l) => Math.max(0, l - 1));

  const finishWorkout = async () => {
    stopTimer();
    try {
      await createWorkout({
        modality: id ?? "outro",
        durationSec: duration,
        distanceKm: isSwimming ? totalDistance / 1000 : undefined,
      });
      Alert.alert("Treino salvo!", `Duração: ${formatTime(duration)}${isSwimming ? ` · ${laps} piscinas (${totalDistance}m)` : ""}`, [
        { text: "OK", onPress: () => router.back() },
      ]);
    } catch {
      Alert.alert("Erro", "Não foi possível salvar o treino");
    }
  };

  return (
    <View style={{ flex: 1, backgroundColor: "#09090b", padding: 24, paddingTop: 60 }}>
      <TouchableOpacity onPress={() => router.back()} style={{ marginBottom: 24 }}>
        <Text style={{ color: "#ea580c", fontSize: 14, fontWeight: "800" }}>{"< Voltar"}</Text>
      </TouchableOpacity>

      <Text style={{ fontSize: 28, fontWeight: "900", fontStyle: "italic", color: "#fff", textTransform: "capitalize", marginBottom: 16 }}>
        {label}
      </Text>

      {/* Swimming lap tracker */}
      {isSwimming && (
        <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
          <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Piscina</Text>
          <View style={{ flexDirection: "row", gap: 8, marginBottom: 12 }}>
            {POOL_LENGTHS.map((pl) => (
              <TouchableOpacity key={pl} onPress={() => { setPoolLength(pl); setCustomPool(""); }} style={{ flex: 1, padding: 10, borderRadius: 10, backgroundColor: poolLength === pl && !customPool ? "#06b6d4" : "#27272a", alignItems: "center" }}>
                <Text style={{ color: "#fff", fontSize: 10, fontWeight: "800" }}>{pl}m</Text>
              </TouchableOpacity>
            ))}
          </View>
          {/* Custom pool length */}
          <TextInput value={customPool} onChangeText={setCustomPool} placeholder="Tamanho personalizado (m)" placeholderTextColor="#52525b" keyboardType="numeric" style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 10, fontSize: 12, color: "#fff", textAlign: "center", marginBottom: 12 }} />

          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 24, marginBottom: 8 }}>
            <TouchableOpacity onPress={decrementLap} style={{ width: 48, height: 48, borderRadius: 24, backgroundColor: "#27272a", alignItems: "center", justifyContent: "center" }}>
              <Text style={{ color: "#fff", fontSize: 22 }}>-</Text>
            </TouchableOpacity>
            <View style={{ alignItems: "center" }}>
              <Text style={{ fontSize: 40, fontWeight: "900", fontStyle: "italic", color: "#06b6d4", fontVariant: ["tabular-nums"] }}>{laps}</Text>
              <Text style={{ fontSize: 9, color: "#71717a", textTransform: "uppercase" }}>piscinas</Text>
            </View>
            <TouchableOpacity onPress={incrementLap} style={{ width: 48, height: 48, borderRadius: 24, backgroundColor: "#06b6d4", alignItems: "center", justifyContent: "center" }}>
              <Text style={{ color: "#fff", fontSize: 22 }}>+</Text>
            </TouchableOpacity>
          </View>

          <Text style={{ textAlign: "center", fontSize: 13, color: "#a1a1aa" }}>
            Total: {totalDistance}m
          </Text>
        </View>
      )}

      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <Text style={{ fontSize: 64, fontWeight: "900", fontStyle: "italic", color: "#fff", fontVariant: ["tabular-nums"] }}>
          {formatTime(duration)}
        </Text>
        <Text style={{ fontSize: 13, color: "#71717a", marginTop: 8 }}>tempo de treino</Text>
      </View>

      <View style={{ gap: 12 }}>
        {!active ? (
          <TouchableOpacity onPress={startTimer} style={{ backgroundColor: "#22c55e", borderRadius: 20, padding: 20, alignItems: "center" }}>
            <Text style={{ color: "#fff", fontSize: 15, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase" }}>
              Iniciar Treino
            </Text>
          </TouchableOpacity>
        ) : (
          <>
            <TouchableOpacity onPress={finishWorkout} style={{ backgroundColor: "#ea580c", borderRadius: 20, padding: 20, alignItems: "center" }}>
              <Text style={{ color: "#fff", fontSize: 15, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase" }}>
                Finalizar Treino
              </Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={stopTimer} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, alignItems: "center" }}>
              <Text style={{ color: "#dc2626", fontSize: 13, fontWeight: "800" }}>Pausar</Text>
            </TouchableOpacity>
          </>
        )}
      </View>
    </View>
  );
}

function formatTime(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  return `${m}:${String(s).padStart(2, "0")}`;
}
