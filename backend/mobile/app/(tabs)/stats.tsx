import { useEffect, useState } from "react";
import { View, Text, ActivityIndicator, ScrollView, TouchableOpacity, Dimensions } from "react-native";
import { getStats, getChartData, type WorkoutStats, type ChartDataPoint } from "@/api/workout-stats";

const PERIODS = [
  { key: "week" as const, label: "Semana" },
  { key: "month" as const, label: "Mês" },
  { key: "year" as const, label: "Ano" },
];

const screenWidth = Dimensions.get("window").width;

export default function StatsScreen() {
  const [period, setPeriod] = useState<"week" | "month" | "year">("week");
  const [stats, setStats] = useState<WorkoutStats | null>(null);
  const [chartData, setChartData] = useState<ChartDataPoint[]>([]);
  const [loadedPeriod, setLoadedPeriod] = useState<"week" | "month" | "year" | null>(null);

  useEffect(() => {
    let cancelled = false;
    Promise.all([getStats(period), getChartData(period)])
      .then(([s, c]) => {
        if (cancelled) return;
        setStats(s);
        setChartData(c);
        setLoadedPeriod(period);
      })
      .catch(() => {})
      .finally(() => {
        if (!cancelled) setLoadedPeriod(period);
      });
    return () => { cancelled = true; };
  }, [period]);

  const loading = loadedPeriod !== period;

  const cards = [
    { label: "Sessões", value: String(stats?.totalSessions ?? 0), color: "#ea580c" },
    { label: "Volume", value: formatDuration(stats?.totalVolume ?? 0), color: "#3b82f6" },
    { label: "Calorias", value: String(Math.round(stats?.totalCalories ?? 0)), color: "#22c55e" },
    { label: "Distância", value: stats ? `${stats.totalDistance.toFixed(1)} km` : "0 km", color: "#a855f7" },
    { label: "Tempo ativo", value: formatDuration(stats?.totalActiveTime ?? 0), color: "#f97316" },
    { label: "FC Média", value: stats?.avgHeartRate ? `${Math.round(stats.avgHeartRate)} BPM` : "—", color: "#dc2626" },
  ];

  const maxChartVal = chartData.length > 0 ? Math.max(...chartData.map((d) => d.value)) : 1;
  const barWidth = Math.max(8, (screenWidth - 80) / Math.max(chartData.length, 7));

  return (
    <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }} contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
      <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 20 }}>Estatísticas</Text>

      <View style={{ flexDirection: "row", gap: 8, marginBottom: 24 }}>
        {PERIODS.map((p) => (
          <TouchableOpacity key={p.key} onPress={() => setPeriod(p.key)} style={{ flex: 1, padding: 12, borderRadius: 12, backgroundColor: period === p.key ? "#ea580c" : "#18181b", alignItems: "center" }}>
            <Text style={{ fontSize: 11, fontWeight: "800", textTransform: "uppercase", color: period === p.key ? "#fff" : "#71717a" }}>{p.label}</Text>
          </TouchableOpacity>
        ))}
      </View>

      {loading ? <ActivityIndicator size="large" color="#ea580c" style={{ marginTop: 40 }} /> : (
        <>
          <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10, marginBottom: 24 }}>
            {cards.map((card) => (
              <View key={card.label} style={{ flex: 1, minWidth: "45%", backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 14 }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 4 }}>{card.label}</Text>
                <Text style={{ fontSize: 22, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{card.value}</Text>
              </View>
            ))}
          </View>

          {chartData.length > 1 ? (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 16 }}>Volume de treino</Text>
              <View style={{ flexDirection: "row", alignItems: "flex-end", height: 140, gap: 2 }}>
                {chartData.map((d, i) => {
                  const h = (d.value / maxChartVal) * 100;
                  return (
                    <View key={i} style={{ flex: 1, alignItems: "center" }}>
                      <View style={{ width: "70%", backgroundColor: i === chartData.length - 1 ? "#ea580c" : "#ea580c20", borderRadius: 3, height: `${Math.max(4, h)}%` }}>
                        <View style={{ width: "100%", height: `${Math.max(8, h)}%`, backgroundColor: i === chartData.length - 1 ? "#ea580c" : "#52525b", borderRadius: 3 }} />
                      </View>
                      <Text style={{ fontSize: 7, color: "#52525b", marginTop: 4 }}>{d.period.slice(-2)}</Text>
                    </View>
                  );
                })}
              </View>
              <Text style={{ fontSize: 10, color: "#71717a", textAlign: "center", marginTop: 8 }}>{stats?.totalSessions ?? 0} sessões no período</Text>
            </View>
          ) : (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 32, alignItems: "center" }}>
              <Text style={{ fontSize: 36, marginBottom: 8 }}>📊</Text>
              <Text style={{ color: "#71717a", fontSize: 13 }}>Nenhum dado no período</Text>
            </View>
          )}
        </>
      )}
    </ScrollView>
  );
}

function formatDuration(sec: number): string {
  const h = Math.floor(sec / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return h > 0 ? `${h}h ${m}min` : `${m}min`;
}
