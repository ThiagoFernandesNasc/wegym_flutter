import { View, Text, TouchableOpacity, ScrollView, Modal } from "react-native";
import { router } from "expo-router";
import RouteMap from "./RouteMap";

interface SessionEntry {
  id: string;
  at: string;
  durationSec: number;
  distanceKm?: number;
  avgPaceSecPerKm?: number;
  steps?: number;
  coordinates?: { latitude: number; longitude: number }[];
}

interface SessionDetailModalProps {
  visible: boolean;
  session: SessionEntry | null;
  onClose: () => void;
}

function formatDuration(seconds: number): string {
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}:${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

function formatPace(secPerKm: number): string {
  if (secPerKm <= 0) return "—";
  const min = Math.floor(secPerKm / 60);
  const sec = Math.round(secPerKm % 60);
  return `${min}:${sec.toString().padStart(2, "0")}`;
}

export default function SessionDetailModal({ visible, session, onClose }: SessionDetailModalProps) {
  if (!session) return null;

  const hasCoords = session.coordinates && session.coordinates.length >= 2;

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={{ flex: 1, backgroundColor: "#09090be6", justifyContent: "flex-end" }}>
        <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 40, borderTopRightRadius: 40, borderWidth: 1, borderColor: "#27272a", maxHeight: "85%" }}>
          <ScrollView contentContainerStyle={{ padding: 24, paddingBottom: 40 }}>
            <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
              <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>
                Detalhes da Sessão
              </Text>
              <TouchableOpacity onPress={onClose} style={{ backgroundColor: "#27272a", borderRadius: 10, padding: 8 }}>
                <Text style={{ color: "#fff", fontSize: 14, fontWeight: "700" }}>✕</Text>
              </TouchableOpacity>
            </View>

            <View style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 16, marginBottom: 16 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 4 }}>
                {new Date(session.at).toLocaleString("pt-BR", {
                  day: "2-digit", month: "long", year: "numeric",
                  hour: "2-digit", minute: "2-digit",
                })}
              </Text>
              <Text style={{ fontSize: 36, fontWeight: "900", fontStyle: "italic", color: "#fff", fontVariant: ["tabular-nums"] }}>
                {formatDuration(session.durationSec)}
              </Text>
            </View>

            {hasCoords && (
              <View style={{ marginBottom: 16 }}>
                <RouteMap coordinates={session.coordinates!} height={200} />
              </View>
            )}

            <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 16 }}>
              {session.distanceKm != null && (
                <StatBox label="Distância" value={`${session.distanceKm.toFixed(2)} km`} />
              )}
              {session.avgPaceSecPerKm != null && (
                <StatBox label="Ritmo" value={`${formatPace(session.avgPaceSecPerKm)} /km`} />
              )}
              {session.steps != null && (
                <StatBox label="Passos" value={session.steps.toLocaleString()} />
              )}
              <StatBox label="Duração" value={formatDuration(session.durationSec)} />
            </View>

            <TouchableOpacity
              onPress={() => {
                onClose();
              }}
              style={{ backgroundColor: "#ea580c", borderRadius: 16, padding: 16, alignItems: "center", marginBottom: 8 }}
            >
              <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase" }}>
                Repetir este treino
              </Text>
            </TouchableOpacity>
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

function StatBox({ label, value }: { label: string; value: string }) {
  return (
    <View style={{ flex: 1, minWidth: "45%", backgroundColor: "#09090b", borderWidth: 1, borderColor: "#27272a", borderRadius: 14, padding: 12, alignItems: "center" }}>
      <Text style={{ fontSize: 8, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 2 }}>{label}</Text>
      <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#fff", textAlign: "center" }}>{value}</Text>
    </View>
  );
}
