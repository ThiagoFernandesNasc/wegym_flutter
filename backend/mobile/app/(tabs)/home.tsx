import { useCallback, useEffect, useState } from "react";
import { View, Text, ActivityIndicator, ScrollView, TouchableOpacity, Dimensions } from "react-native";
import { router } from "expo-router";
import { api } from "@/api/client";
import { useOnboarding } from "@/components/Onboarding";

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

type Profile = { name: string; avatarPlaceholder: string; experienceLevel: string };
type HomeStats = { totalSessions: number; totalVolume: number; totalDistance: number; totalCalories: number; totalActiveTime: number; };
type ModalityRank = { modality: string; count: number; totalTime: number };
type RecentSession = { id: string; modality: string; durationSec: number; distanceKm: number | null; completedAt: string };

export default function HomeScreen() {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [stats, setStats] = useState<HomeStats | null>(null);
  const [topModalities, setTopModalities] = useState<ModalityRank[]>([]);
  const [recentSessions, setRecentSessions] = useState<RecentSession[]>([]);
  const [loading, setLoading] = useState(true);

  const hour = new Date().getHours();
  const greeting = hour < 6 ? "Boa madrugada" : hour < 12 ? "Bom dia" : hour < 18 ? "Boa tarde" : "Boa noite";

  const { Onboarding } = useOnboarding("atleta");

  const load = useCallback(async () => {
    try {
      const [profileData, statsData, recentData] = await Promise.all([
        api.get<Profile>("/api/user/profile"),
        api.get<HomeStats>("/api/workout-stats?period=week"),
        api.get<{ data: RecentSession[] }>("/api/workout-sessions?limit=5").catch(() => ({ data: [] })),
      ]);
      setProfile(profileData);
      setStats(statsData);
      setRecentSessions(recentData.data);
      const modRank = await api.get<ModalityRank[]>("/api/workout-stats?period=week&rank=true").catch(() => []);
      setTopModalities(modRank);
    } catch { /* silent */ } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const favoriteMod = topModalities.length > 0 ? MODALITIES.find((m) => m.id === topModalities[0].modality) : null;

  const openTraining = (mod: string) => {
    const m = MODALITIES.find((x) => x.id === mod);
    if (!m) return;
    if (m.type === "gym") router.push("/gym");
    else if (m.type === "gps") router.push(`/gps/${m.id}`);
    else router.push(`/training/${m.id}`);
  };

  if (loading && !stats) {
    return <View style={{ flex: 1, backgroundColor: "#09090b", justifyContent: "center", alignItems: "center" }}><ActivityIndicator size="large" color="#ea580c" /></View>;
  }

  return (
    <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }} contentContainerStyle={{ padding: 20, paddingTop: 60, paddingBottom: 40 }}>
      <View style={{ flexDirection: "row", alignItems: "center", gap: 12, marginBottom: 4 }}>
        <TouchableOpacity onPress={() => {}} style={{ width: 44, height: 44, borderRadius: 14, backgroundColor: "#ea580c20", alignItems: "center", justifyContent: "center" }}>
          <Text style={{ fontSize: 20, fontWeight: "900", color: "#ea580c" }}>{profile?.name?.charAt(0)?.toUpperCase() || "A"}</Text>
        </TouchableOpacity>
        <View>
          <Text style={{ fontSize: 20, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{greeting}, {profile?.name || "Atleta"}</Text>
          <Text style={{ fontSize: 11, color: "#71717a" }}>Seu resumo da semana</Text>
        </View>
      </View>
      {Onboarding}

      <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10, marginTop: 20, marginBottom: 20 }}>
        {[
          { label: "Treinos", value: String(stats?.totalSessions ?? 0), unit: "sessões" },
          { label: "Tempo", value: formatDuration(stats?.totalVolume ?? 0), unit: "" },
          { label: "Distância", value: (stats?.totalDistance ?? 0).toFixed(1), unit: "km" },
          { label: "Calorias", value: String(Math.round(stats?.totalCalories ?? 0)), unit: "kcal" },
        ].map((card) => (
          <View key={card.label} style={{ flex: 1, minWidth: "45%", backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 14 }}>
            <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 4 }}>{card.label}</Text>
            <Text style={{ fontSize: 26, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{card.value}</Text>
            {card.unit ? <Text style={{ fontSize: 10, color: "#a1a1aa", marginTop: 2 }}>{card.unit}</Text> : null}
          </View>
        ))}
      </View>

      {topModalities.length > 0 && (
        <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
          <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Modalidades favoritas</Text>
          {topModalities.slice(0, 3).map((m, i) => {
            const mod = MODALITIES.find((x) => x.id === m.modality);
            const maxVal = topModalities[0]?.count || 1;
            return (
              <TouchableOpacity key={m.modality} onPress={() => openTraining(m.modality)} style={{ flexDirection: "row", alignItems: "center", gap: 10, paddingVertical: 8, borderBottomWidth: i < 2 ? 1 : 0, borderBottomColor: "#27272a" }}>
                <Text style={{ fontSize: 18 }}>{mod?.icon || "💪"}</Text>
                <View style={{ flex: 1 }}>
                  <View style={{ flexDirection: "row", justifyContent: "space-between", marginBottom: 4 }}>
                    <Text style={{ fontSize: 12, fontWeight: "800", color: "#fff", textTransform: "capitalize" }}>{mod?.label || m.modality}</Text>
                    <Text style={{ fontSize: 10, color: "#71717a" }}>{m.count} treinos</Text>
                  </View>
                  <View style={{ height: 6, backgroundColor: "#27272a", borderRadius: 3 }}>
                    <View style={{ width: `${(m.count / maxVal) * 100}%`, height: "100%", backgroundColor: i === 0 ? "#ea580c" : "#52525b", borderRadius: 3 }} />
                  </View>
                </View>
                {i === 0 && <Text style={{ fontSize: 9, fontWeight: "900", color: "#ea580c" }}>TOP</Text>}
              </TouchableOpacity>
            );
          })}
        </View>
      )}

      {favoriteMod && (
        <TouchableOpacity onPress={() => openTraining(favoriteMod.id)} style={{ backgroundColor: "linear-gradient(135deg, #ea580c, #c2410c)", borderRadius: 20, padding: 20, marginBottom: 16 }}>
          <Text style={{ fontSize: 10, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#fdba74", marginBottom: 4 }}>Seu favorito</Text>
          <Text style={{ fontSize: 20, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{favoriteMod.icon} {favoriteMod.label}</Text>
          <Text style={{ fontSize: 12, color: "#fdba74", marginTop: 4 }}>{topModalities[0].count} treinos · {formatDuration(topModalities[0].totalTime)} total</Text>
          <View style={{ backgroundColor: "rgba(255,255,255,0.2)", borderRadius: 14, padding: 10, marginTop: 12, alignItems: "center" }}>
            <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>TREINAR AGORA</Text>
          </View>
        </TouchableOpacity>
      )}

      <View style={{ marginBottom: 20 }}>
        <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 10 }}>Início rápido</Text>
        <View style={{ flexDirection: "row", gap: 8 }}>
          {MODALITIES.slice(0, 4).map((mod) => (
            <TouchableOpacity key={mod.id} onPress={() => openTraining(mod.id)} style={{ flex: 1, backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 12, alignItems: "center" }}>
              <Text style={{ fontSize: 22, marginBottom: 4 }}>{mod.icon}</Text>
              <Text style={{ fontSize: 9, fontWeight: "800", textTransform: "uppercase", color: "#fff" }}>{mod.label}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>

      {recentSessions.length > 0 && (
        <>
          <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 10 }}>Atividade recente</Text>
          {recentSessions.map((s) => {
            const mod = MODALITIES.find((m) => m.id === s.modality);
            return (
              <TouchableOpacity key={s.id} onPress={() => openTraining(s.modality)} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 14, marginBottom: 8, flexDirection: "row", alignItems: "center", gap: 12 }}>
                <Text style={{ fontSize: 22 }}>{mod?.icon || "💪"}</Text>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 13, fontWeight: "800", fontStyle: "italic", color: "#fff", textTransform: "capitalize" }}>{s.modality}</Text>
                  <Text style={{ fontSize: 10, color: "#71717a", marginTop: 2 }}>
                    {formatRelativeDate(s.completedAt)} · {formatDuration(s.durationSec)}
                  </Text>
                </View>
                {s.distanceKm != null && <Text style={{ fontSize: 12, color: "#ea580c", fontWeight: "700" }}>{s.distanceKm.toFixed(2)} km</Text>}
                <Text style={{ color: "#52525b", fontSize: 16 }}>›</Text>
              </TouchableOpacity>
            );
          })}
        </>
      )}
    </ScrollView>
  );
}

function formatDuration(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return h > 0 ? `${h}h${m}min` : `${m}min`;
}

function formatRelativeDate(iso: string): string {
  const d = new Date(iso);
  const now = new Date();
  const diff = now.getTime() - d.getTime();
  const days = Math.floor(diff / 86400000);
  if (days === 0) return "Hoje";
  if (days === 1) return "Ontem";
  return d.toLocaleDateString("pt-BR", { day: "2-digit", month: "short" });
}
