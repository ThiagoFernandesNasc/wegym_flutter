import { useCallback, useState, useMemo } from "react";
import { View, Text, TouchableOpacity, ScrollView, Alert, TextInput, Modal } from "react-native";
import { useLocalSearchParams, router, Stack } from "expo-router";
import { useGpsTracker } from "@/hooks/use-gps-tracker";
import { createGpsSession } from "@/api/gps-sessions";
import RouteMap from "@/components/RouteMap";
import GpsSessionResult from "@/components/GpsSessionResult";

const MODE_CONFIG: Record<string, { label: string; icon: string; color: string }> = {
  corrida: { label: "Corrida", icon: "🏃", color: "#22c55e" },
  ciclismo: { label: "Ciclismo", icon: "🚴", color: "#3b82f6" },
  caminhada: { label: "Caminhada", icon: "🚶", color: "#a855f7" },
  hiking: { label: "Trilha", icon: "⛰️", color: "#22c55e" },
  running: { label: "Corrida", icon: "🏃", color: "#22c55e" },
  cycling: { label: "Ciclismo", icon: "🚴", color: "#3b82f6" },
  walking: { label: "Caminhada", icon: "🚶", color: "#a855f7" },
};

const PACE: Record<string, { minSecPerKm: number; avgSecPerKm: number; maxSecPerKm: number }> = {
  corrida: { minSecPerKm: 270, avgSecPerKm: 345, maxSecPerKm: 420 },
  running: { minSecPerKm: 270, avgSecPerKm: 345, maxSecPerKm: 420 },
  caminhada: { minSecPerKm: 480, avgSecPerKm: 600, maxSecPerKm: 720 },
  walking: { minSecPerKm: 480, avgSecPerKm: 600, maxSecPerKm: 720 },
  hiking: { minSecPerKm: 360, avgSecPerKm: 480, maxSecPerKm: 600 },
  ciclismo: { minSecPerKm: 112, avgSecPerKm: 144, maxSecPerKm: 200 },
  cycling: { minSecPerKm: 112, avgSecPerKm: 144, maxSecPerKm: 200 },
};

function formatDuration(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}:${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
  return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
}

function formatDurHMS(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}h${m.toString().padStart(2, "0")}min`;
  return `${m}min${s.toString().padStart(2, "0")}s`;
}

function formatPace(secPerKm: number): string {
  if (secPerKm <= 0) return "--:--";
  const min = Math.floor(secPerKm / 60);
  const sec = Math.round(secPerKm % 60);
  return `${min}:${sec.toString().padStart(2, "0")}`;
}

export default function GpsTrackingScreen() {
  const { mode } = useLocalSearchParams<{ mode: string }>();
  const cfg = MODE_CONFIG[mode ?? ""] ?? { label: "Atividade", icon: "📍", color: "#ea580c" };

  const [phase, setPhase] = useState<"config" | "tracking" | "result">("config");
  const [targetKm, setTargetKm] = useState(5);
  const [selectedTarget, setSelectedTarget] = useState<"min" | "avg" | "max" | null>(null);
  const [showResult, setShowResult] = useState(false);
  const [saving, setSaving] = useState(false);

  const {
    state, coords, distance, duration, currentSpeed,
    avgPaceSecPerKm, steps, avgSpeedKmh,
    startLat, startLng, endLat, endLng,
    startTracking, pauseTracking, resumeTracking, stopTracking, reset,
  } = useGpsTracker();

  const achievedKm = distance > 0 ? distance / 1000 : 0;
  const paceStr = avgPaceSecPerKm > 0 ? formatPace(avgPaceSecPerKm) : "--:--";

  const targetTimes = useMemo(() => {
    const pace = PACE[mode ?? ""];
    if (!pace || targetKm <= 0) return null;
    return {
      minSec: Math.round(targetKm * pace.minSecPerKm),
      avgSec: Math.round(targetKm * pace.avgSecPerKm),
      maxSec: Math.round(targetKm * pace.maxSecPerKm),
    };
  }, [mode, targetKm]);

  const targetPaceSec = useMemo(() => {
    if (!selectedTarget || !targetTimes || targetKm <= 0) return null;
    return Math.round(targetTimes[`${selectedTarget}Sec`] / targetKm);
  }, [selectedTarget, targetTimes, targetKm]);

  const snapshot = useMemo(() => {
    if (phase !== "result" && !showResult) return null;
    return {
      distanceKm: achievedKm,
      avgPaceSecPerKm,
      steps,
      durationSec: duration,
      coordinates: coords,
    };
  }, [phase, showResult, achievedKm, avgPaceSecPerKm, steps, duration, coords]);

  const handleStart = async () => {
    const ok = await startTracking();
    if (ok) setPhase("tracking");
  };

  const handleFinish = useCallback(() => {
    stopTracking();
    setPhase("result");
    setShowResult(true);
  }, [stopTracking]);

  const handleSave = useCallback(async () => {
    if (!snapshot) return;
    setSaving(true);
    try {
      await createGpsSession({
        modality: mode ?? "corrida",
        distanceKm: snapshot.distanceKm,
        durationSec: snapshot.durationSec,
        avgPaceSecPerKm: snapshot.avgPaceSecPerKm,
        steps: snapshot.steps,
        coordinates: snapshot.coordinates,
      });
      setShowResult(false);
      setPhase("config");
      reset();
      Alert.alert("Salvo", "Treino salvo no histórico!");
    } catch {
      Alert.alert("Erro", "Não foi possível salvar o treino");
    }
    setSaving(false);
  }, [snapshot, mode, reset]);

  const handleDiscard = useCallback(() => {
    setShowResult(false);
    setPhase("config");
    reset();
  }, [reset]);

  const mapCoords = coords.map((c) => ({ latitude: c.latitude, longitude: c.longitude }));

  const handleBackToConfig = () => {
    setPhase("config");
    reset();
  };

  return (
    <View style={{ flex: 1, backgroundColor: "#09090b" }}>
      <Stack.Screen options={{ headerShown: false }} />

      {showResult && snapshot && (
        <Modal visible={showResult} transparent animationType="fade" onRequestClose={handleDiscard}>
          <GpsSessionResult
            snapshot={snapshot}
            targetTimes={targetTimes}
            targetKm={targetKm}
            selectedTarget={selectedTarget}
            onSave={handleSave}
            onDiscard={handleDiscard}
            modalityLabel={cfg.label}
          />
        </Modal>
      )}

      {/* ---- CONFIG PHASE ---- */}
      {phase === "config" && (
        <ScrollView contentContainerStyle={{ padding: 24, paddingTop: 60 }}>
          <TouchableOpacity onPress={() => router.back()} style={{ marginBottom: 24 }}>
            <Text style={{ color: "#ea580c", fontSize: 14, fontWeight: "800" }}>{"< Voltar"}</Text>
          </TouchableOpacity>

          <View style={{ alignItems: "center", marginBottom: 32 }}>
            <Text style={{ fontSize: 48, marginBottom: 8 }}>{cfg.icon}</Text>
            <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{cfg.label}</Text>
          </View>

          <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 16 }}>
            <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>
              Quantos km você deseja percorrer?
            </Text>
            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
              {[1, 3, 5, 10, 15, 21.1, 42.2].map((km) => (
                <TouchableOpacity
                  key={km}
                  onPress={() => { setTargetKm(km); setSelectedTarget(null); }}
                  style={{ backgroundColor: targetKm === km ? "#ea580c" : "#27272a", borderRadius: 14, paddingHorizontal: 20, paddingVertical: 12 }}
                >
                  <Text style={{ color: "#fff", fontSize: 11, fontWeight: "800" }}>{km} km</Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>

          {targetTimes && targetKm > 0 && (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 16 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>
                Tempo estimado para {targetKm} km
              </Text>
              <View style={{ gap: 8 }}>
                {(["min", "avg", "max"] as const).map((key) => {
                  const sec = targetTimes[`${key}Sec`];
                  const labels: Record<string, { label: string; color: string }> = {
                    min: { label: "Mínimo", color: "#22c55e" },
                    avg: { label: "Médio", color: "#a1a1aa" },
                    max: { label: "Máximo", color: "#facc15" },
                  };
                  const cfg2 = labels[key];
                  return (
                    <View key={key} style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
                      <Text style={{ fontSize: 11, fontWeight: "700", color: cfg2.color }}>{cfg2.label}</Text>
                      <Text style={{ fontSize: 13, fontFamily: "monospace", fontWeight: "700", color: "#fff" }}>
                        {formatDurHMS(sec)}
                      </Text>
                    </View>
                  );
                })}
              </View>
            </View>
          )}

          {targetTimes && targetKm > 0 && (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 24 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>
                Selecionar ritmo alvo
              </Text>
              <View style={{ flexDirection: "row", gap: 8 }}>
                {(["min", "avg", "max"] as const).map((key) => {
                  const sec = targetTimes[`${key}Sec`];
                  const labels: Record<string, { label: string; color: string }> = {
                    min: { label: "Mínimo", color: "#22c55e" },
                    avg: { label: "Médio", color: "#a1a1aa" },
                    max: { label: "Máximo", color: "#facc15" },
                  };
                  const cfg2 = labels[key];
                  const isActive = selectedTarget === key;
                  return (
                    <TouchableOpacity
                      key={key}
                      onPress={() => setSelectedTarget(key)}
                      style={{
                        flex: 1,
                        paddingVertical: 12,
                        borderRadius: 14,
                        alignItems: "center",
                        backgroundColor: isActive ? "#ea580c" : "#09090b",
                        borderWidth: 1,
                        borderColor: isActive ? "#ea580c" : "#27272a",
                      }}
                    >
                      <Text style={{ fontSize: 9, fontWeight: "800", textTransform: "uppercase", color: isActive ? "#fff" : cfg2.color }}>
                        {cfg2.label}
                      </Text>
                      <Text style={{ fontSize: 11, fontFamily: "monospace", fontWeight: "700", color: isActive ? "#fdba74" : "#fff", marginTop: 2 }}>
                        {formatPace(sec / targetKm)}/km
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </View>
          )}

          <TouchableOpacity
            onPress={handleStart}
            style={{ backgroundColor: cfg.color, borderRadius: 24, padding: 20, alignItems: "center" }}
          >
            <Text style={{ color: "#fff", fontSize: 15, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase" }}>
              🛰️ Iniciar {cfg.label}
            </Text>
          </TouchableOpacity>
        </ScrollView>
      )}

      {/* ---- TRACKING PHASE ---- */}
      {phase === "tracking" && (
        <View style={{ flex: 1 }}>
          <View style={{ paddingTop: 60, paddingHorizontal: 20, paddingBottom: 12 }}>
            <TouchableOpacity onPress={handleBackToConfig}>
              <Text style={{ color: "#ea580c", fontSize: 14, fontWeight: "800" }}>{"< Voltar"}</Text>
            </TouchableOpacity>
          </View>

          <View style={{ flex: 1, marginHorizontal: 12, borderRadius: 24, overflow: "hidden" }}>
            {mapCoords.length > 1 ? (
              <RouteMap coordinates={mapCoords} height={9999} interactive />
            ) : (
              <View style={{ flex: 1, backgroundColor: "#18181b", justifyContent: "center", alignItems: "center" }}>
                <Text style={{ fontSize: 48, marginBottom: 12 }}>{cfg.icon}</Text>
                <Text style={{ color: "#71717a", fontSize: 14, textAlign: "center", paddingHorizontal: 20 }}>
                  Aguardando sinal GPS...
                </Text>
              </View>
            )}
          </View>

          <View style={{ paddingHorizontal: 20, paddingTop: 16, paddingBottom: 24 }}>
            <View style={{ backgroundColor: "#18181b", borderRadius: 24, borderWidth: 1, borderColor: "#27272a", padding: 20, marginBottom: 16 }}>
              <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a" }}>
                  Rastreamento GPS
                </Text>
                <View style={{ flexDirection: "row", alignItems: "center", gap: 4 }}>
                  <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: "#22c55e" }} />
                  <Text style={{ fontSize: 9, fontWeight: "700", textTransform: "uppercase", color: "#22c55e" }}>
                    GPS ativo
                  </Text>
                </View>
              </View>

              {targetKm > 0 && (
                <View style={{ marginBottom: 12 }}>
                  <View style={{ flexDirection: "row", justifyContent: "space-between", marginBottom: 4 }}>
                    <Text style={{ fontSize: 9, fontWeight: "700", color: "#71717a" }}>{achievedKm.toFixed(2)} km</Text>
                    <Text style={{ fontSize: 9, fontWeight: "700", color: "#71717a" }}>{targetKm} km</Text>
                  </View>
                  <View style={{ height: 6, backgroundColor: "#27272a", borderRadius: 3, overflow: "hidden" }}>
                    <View style={{ height: "100%", width: `${Math.min((achievedKm / targetKm) * 100, 100)}%`, backgroundColor: "#ea580c", borderRadius: 3 }} />
                  </View>
                </View>
              )}

              <View style={{ flexDirection: "row", gap: 8 }}>
                <View style={{ flex: 1, backgroundColor: "#09090b", borderRadius: 12, padding: 12, alignItems: "center" }}>
                  <Text style={{ fontSize: 8, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 2 }}>Distância</Text>
                  <Text style={{ fontSize: 16, fontWeight: "900", color: "#fff", fontFamily: "monospace" }}>
                    {achievedKm.toFixed(2)}
                    <Text style={{ fontSize: 9, color: "#ea580c" }}> km</Text>
                  </Text>
                </View>
                <View style={{ flex: 1, backgroundColor: "#09090b", borderRadius: 12, padding: 12, alignItems: "center" }}>
                  <Text style={{ fontSize: 8, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 2 }}>Ritmo</Text>
                  <Text style={{ fontSize: 16, fontWeight: "900", color: "#fff", fontFamily: "monospace" }}>
                    {paceStr}
                  </Text>
                </View>
                <View style={{ flex: 1, backgroundColor: "#09090b", borderRadius: 12, padding: 12, alignItems: "center" }}>
                  <Text style={{ fontSize: 8, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 2 }}>Passos</Text>
                  <Text style={{ fontSize: 16, fontWeight: "900", color: "#fff" }}>
                    {steps.toLocaleString()}
                  </Text>
                </View>
              </View>

              {selectedTarget && targetPaceSec != null && targetTimes && (
                <View style={{ backgroundColor: "#09090b", borderRadius: 12, padding: 12, marginTop: 12, flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
                  <Text style={{ fontSize: 9, fontWeight: "700", textTransform: "uppercase", color: "#71717a" }}>
                    Ritmo alvo ({selectedTarget === "min" ? "Mínimo" : selectedTarget === "avg" ? "Médio" : "Máximo"})
                  </Text>
                  <View style={{ flexDirection: "row", alignItems: "center", gap: 4 }}>
                    <Text style={{ fontSize: 9 }}>
                      {avgPaceSecPerKm > 0 && avgPaceSecPerKm <= targetPaceSec ? "✅" : "⚠️"}
                    </Text>
                    <Text style={{
                      fontSize: 12,
                      fontFamily: "monospace",
                      fontWeight: "700",
                      color: avgPaceSecPerKm > 0 && avgPaceSecPerKm <= targetPaceSec ? "#22c55e" : "#dc2626",
                    }}>
                      {formatPace(targetPaceSec)}/km
                    </Text>
                  </View>
                </View>
              )}
            </View>

            <View style={{ backgroundColor: "#18181b", borderRadius: 24, borderWidth: 1, borderColor: "#27272a", padding: 20, marginBottom: 16 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 4 }}>
                Tempo de sessão
              </Text>
              <Text style={{ fontSize: 40, fontWeight: "900", color: "#fff", fontFamily: "monospace", letterSpacing: -1 }}>
                {formatDuration(duration)}
              </Text>
            </View>

            <View style={{ flexDirection: "row", gap: 12 }}>
              {state === "tracking" && (
                <TouchableOpacity
                  onPress={pauseTracking}
                  style={{ flex: 1, backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, alignItems: "center" }}
                >
                  <Text style={{ color: "#facc15", fontSize: 13, fontWeight: "800", textTransform: "uppercase" }}>Pausar</Text>
                </TouchableOpacity>
              )}
              {state === "paused" && (
                <TouchableOpacity
                  onPress={resumeTracking}
                  style={{ flex: 1, backgroundColor: cfg.color, borderRadius: 20, padding: 16, alignItems: "center" }}
                >
                  <Text style={{ color: "#fff", fontSize: 13, fontWeight: "800", textTransform: "uppercase" }}>Continuar</Text>
                </TouchableOpacity>
              )}
              <TouchableOpacity
                onPress={handleFinish}
                disabled={saving}
                style={{ flex: 1, backgroundColor: "#dc2626", borderRadius: 20, padding: 16, alignItems: "center" }}
              >
                <Text style={{ color: "#fff", fontSize: 13, fontWeight: "800", textTransform: "uppercase" }}>
                  {saving ? "Salvando..." : "Finalizar"}
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      )}
    </View>
  );
}
