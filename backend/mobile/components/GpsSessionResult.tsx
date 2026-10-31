import { View, Text, TouchableOpacity, ScrollView, Share } from "react-native";
import RouteMap from "./RouteMap";

interface GpsSnapshot {
  distanceKm: number;
  avgPaceSecPerKm: number;
  steps: number;
  durationSec: number;
  coordinates: { latitude: number; longitude: number }[];
}

interface TargetTimes {
  minSec: number;
  avgSec: number;
  maxSec: number;
}

interface GpsSessionResultProps {
  snapshot: GpsSnapshot;
  targetTimes: TargetTimes | null;
  targetKm: number;
  selectedTarget: "min" | "avg" | "max" | null;
  onSave: () => void;
  onDiscard: () => void;
  modalityLabel?: string;
}

function formatPace(secPerKm: number): string {
  if (secPerKm <= 0) return "—";
  const min = Math.floor(secPerKm / 60);
  const sec = Math.round(secPerKm % 60);
  return `${min}:${sec.toString().padStart(2, "0")}`;
}

function formatDuration(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}:${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

export default function GpsSessionResult({
  snapshot, targetTimes, selectedTarget, onSave, onDiscard, modalityLabel,
}: GpsSessionResultProps) {
  const withinMax = targetTimes ? snapshot.durationSec <= targetTimes.maxSec : false;
  const withinAvg = targetTimes ? snapshot.durationSec <= targetTimes.avgSec : false;
  const withinMin = targetTimes ? snapshot.durationSec <= targetTimes.minSec : false;

  let achievement: { label: string; emoji: string; color: string } | null = null;
  if (withinMin && targetTimes) {
    achievement = { label: "Desempenho de elite!", emoji: "🏆", color: "#facc15" };
  } else if (withinAvg && targetTimes) {
    achievement = { label: "Ótimo desempenho!", emoji: "💪", color: "#22c55e" };
  } else if (withinMax && targetTimes) {
    achievement = { label: "Bom treino!", emoji: "👏", color: "#ea580c" };
  }

  const TARGET_LABELS: Record<string, { label: string; color: string }> = {
    min: { label: "Mínimo", color: "#22c55e" },
    avg: { label: "Médio", color: "#a1a1aa" },
    max: { label: "Máximo", color: "#facc15" },
  };

  const handleShare = async () => {
    try {
      await Share.share({
        message: `${modalityLabel ?? "Treino"} WEGYM: ${snapshot.distanceKm.toFixed(2)} km em ${formatDuration(snapshot.durationSec)} • Ritmo ${formatPace(snapshot.avgPaceSecPerKm)}/km`,
      });
    } catch {}
  };

  return (
    <View style={{ flex: 1, backgroundColor: "#09090be6", justifyContent: "center", padding: 16 }}>
      <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 40, overflow: "hidden", maxHeight: "95%" }}>
        <ScrollView contentContainerStyle={{ paddingBottom: 20 }}>
          <View style={{ padding: 24, paddingBottom: 12, alignItems: "center" }}>
            {achievement ? (
              <>
                <Text style={{ fontSize: 40, marginBottom: 4, textAlign: "center" }}>{achievement.emoji}</Text>
                <Text style={{ fontSize: 18, fontWeight: "900", fontStyle: "italic", color: achievement.color, textAlign: "center" }}>
                  {achievement.label}
                </Text>
              </>
            ) : (
              <Text style={{ fontSize: 18, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>
                Resultado da Sessão
              </Text>
            )}
          </View>

          <View style={{ paddingHorizontal: 24, paddingBottom: 12 }}>
            <RouteMap coordinates={snapshot.coordinates} height={180} />
          </View>

          <View style={{ paddingHorizontal: 24 }}>
            <View style={{ flexDirection: "row", gap: 8, marginBottom: 12 }}>
              {[
                { label: "Distância", value: `${snapshot.distanceKm.toFixed(2)} km` },
                { label: "Ritmo", value: formatPace(snapshot.avgPaceSecPerKm) },
                { label: "Passos", value: snapshot.steps.toLocaleString() },
                { label: "Duração", value: formatDuration(snapshot.durationSec) },
              ].map((s, i) => (
                <View key={i} style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 10, alignItems: "center" }}>
                  <Text style={{ fontSize: 8, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 2 }}>{s.label}</Text>
                  <Text style={{ fontSize: 13, fontWeight: "900", fontStyle: "italic", color: "#fff", textAlign: "center" }}>{s.value}</Text>
                </View>
              ))}
            </View>

            {targetTimes && (
              <View style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 16, marginBottom: 12 }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 8 }}>Alvo</Text>
                {(["min", "avg", "max"] as const).map((key) => {
                  const sec = targetTimes[`${key}Sec`];
                  const isSelected = key === selectedTarget;
                  const cfg = TARGET_LABELS[key];
                  return (
                    <View key={key} style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", paddingVertical: 4, ...(isSelected ? { backgroundColor: "#ea580c10", borderRadius: 8, paddingHorizontal: 8, marginHorizontal: -8 } : {}) }}>
                      <Text style={{ fontSize: 10, fontWeight: "700", color: cfg.color }}>
                        {isSelected ? "▶ " : ""}{cfg.label}
                      </Text>
                      <Text style={{ fontSize: 12, fontWeight: isSelected ? "900" : "400", color: isSelected ? "#fff" : "#d4d4d8", fontFamily: "monospace" }}>
                        {formatDuration(sec)}
                      </Text>
                    </View>
                  );
                })}
                <View style={{ borderTopWidth: 1, borderTopColor: "#27272a", paddingTop: 6, marginTop: 6 }}>
                  <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
                    <Text style={{ fontSize: 10, fontWeight: "700", color: "#ea580c" }}>Seu tempo</Text>
                    <Text style={{ fontSize: 12, fontWeight: "900", color: "#fff", fontFamily: "monospace" }}>
                      {formatDuration(snapshot.durationSec)}
                    </Text>
                  </View>
                </View>
              </View>
            )}
          </View>

          <View style={{ paddingHorizontal: 24, paddingTop: 4, gap: 8 }}>
            <TouchableOpacity
              onPress={handleShare}
              style={{ backgroundColor: "#fff", borderRadius: 14, padding: 14, alignItems: "center" }}
            >
              <Text style={{ fontSize: 12, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase", color: "#000" }}>
                📤 Compartilhar
              </Text>
            </TouchableOpacity>
            <View style={{ flexDirection: "row", gap: 8 }}>
              <TouchableOpacity
                onPress={onDiscard}
                style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#27272a", borderRadius: 14, padding: 14, alignItems: "center" }}
              >
                <Text style={{ fontSize: 11, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase", color: "#71717a" }}>
                  Descartar
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={onSave}
                style={{ flex: 1, backgroundColor: "#ea580c", borderRadius: 14, padding: 14, alignItems: "center" }}
              >
                <Text style={{ fontSize: 11, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase", color: "#fff" }}>
                  Salvar
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </ScrollView>
      </View>
    </View>
  );
}
