import { useCallback, useEffect, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, Modal } from "react-native";
import { Stack } from "expo-router";
import { getMeasurements, getChartData, createMeasurement, type MeasurementEntry, type ChartDataPoint } from "@/api/measurements";

const METRICS = [
  { key: "weight", label: "Peso", icon: "⚖️", color: "#ea580c", unit: "kg" },
  { key: "muscleMass", label: "Massa Muscular", icon: "💪", color: "#10b981", unit: "kg" },
  { key: "bodyFat", label: "Gordura", icon: "📏", color: "#3b82f6", unit: "%" },
];

export default function MeasurementsScreen() {
  const [entries, setEntries] = useState<MeasurementEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [weight, setWeight] = useState("");
  const [muscleMass, setMuscleMass] = useState("");
  const [bodyFat, setBodyFat] = useState("");
  const [note, setNote] = useState("");
  const [chartMetric, setChartMetric] = useState<string | null>(null);
  const [chartData, setChartData] = useState<ChartDataPoint[]>([]);

  const load = useCallback(async () => {
    try { setEntries(await getMeasurements()); } catch { /* silent */ } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const loadChart = async (metric: string) => {
    setChartMetric(metric);
    try { setChartData(await getChartData(metric)); } catch { setChartData([]); }
  };

  const handleSave = async () => {
    if (!weight) return;
    await createMeasurement({ weight: Number(weight), muscleMass: muscleMass ? Number(muscleMass) : undefined, bodyFat: bodyFat ? Number(bodyFat) : undefined, note });
    setShowForm(false); setWeight(""); setMuscleMass(""); setBodyFat(""); setNote(""); load();
  };

  return (
    <>
      <Stack.Screen options={{ title: "Evolução" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
            <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Evolução</Text>
            <TouchableOpacity onPress={() => setShowForm(true)} style={{ backgroundColor: "#ea580c", borderRadius: 14, paddingHorizontal: 16, paddingVertical: 10 }}>
              <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>Nova Medida</Text>
            </TouchableOpacity>
          </View>

          <Modal visible={showForm} animationType="slide" transparent>
            <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.7)", justifyContent: "flex-end" }}>
              <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24 }}>
                <TextInput value={weight} onChangeText={setWeight} placeholder="Peso (kg)" placeholderTextColor="#71717a" keyboardType="decimal-pad" style={inputStyle} />
                <TextInput value={muscleMass} onChangeText={setMuscleMass} placeholder="Massa muscular (kg, opcional)" placeholderTextColor="#71717a" keyboardType="decimal-pad" style={inputStyle} />
                <TextInput value={bodyFat} onChangeText={setBodyFat} placeholder="% gordura (opcional)" placeholderTextColor="#71717a" keyboardType="decimal-pad" style={inputStyle} />
                <TextInput value={note} onChangeText={setNote} placeholder="Observação" placeholderTextColor="#71717a" style={inputStyle} />
                <TouchableOpacity onPress={handleSave} style={{ backgroundColor: "#ea580c", borderRadius: 14, padding: 14, alignItems: "center" }}>
                  <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>Salvar</Text>
                </TouchableOpacity>
              </View>
            </View>
          </Modal>

          <View style={{ flexDirection: "row", gap: 8, marginBottom: 16 }}>
            {METRICS.map((m) => {
              const latest = entries.find((e: any) => e[m.key] != null);
              return (
                <TouchableOpacity key={m.key} onPress={() => loadChart(m.key)} style={{ flex: 1, backgroundColor: "#18181b", borderWidth: 1, borderColor: chartMetric === m.key ? "#ea580c" : "#27272a", borderRadius: 16, padding: 12 }}>
                  <Text style={{ fontSize: 18, marginBottom: 4 }}>{m.icon}</Text>
                  <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", color: "#71717a" }}>{m.label}</Text>
                  <Text style={{ fontSize: 18, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{latest ? `${latest[m.key as keyof MeasurementEntry]} ${m.unit}` : "—"}</Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {chartData.length > 1 && (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 12 }}>Evolução</Text>
              <View style={{ flexDirection: "row", alignItems: "flex-end", height: 120, gap: 2 }}>
                {chartData.map((d, i) => {
                  const values = chartData.map((cd) => cd.value);
                  const min = Math.min(...values);
                  const max = Math.max(...values);
                  const range = max - min || 1;
                  const h = ((d.value - min) / range) * 100;
                  return (
                    <View key={i} style={{ flex: 1, alignItems: "center" }}>
                      <View style={{ width: "100%", backgroundColor: "#ea580c20", borderTopLeftRadius: 2, borderTopRightRadius: 2, height: `${h}%` }}>
                        <View style={{ width: "100%", height: `${Math.max(10, h)}%`, backgroundColor: "#ea580c", borderTopLeftRadius: 2, borderTopRightRadius: 2 }} />
                      </View>
                      <Text style={{ fontSize: 7, color: "#52525b", marginTop: 2 }}>{d.date.slice(5)}</Text>
                    </View>
                  );
                })}
              </View>
            </View>
          )}

          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : entries.map((e) => (
            <View key={e.id} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 14, marginBottom: 8, flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
              <View>
                <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{e.weight} kg</Text>
                <Text style={{ fontSize: 10, color: "#71717a", marginTop: 2 }}>
                  {new Date(e.date).toLocaleDateString("pt-BR")}
                  {e.muscleMass && ` · ${e.muscleMass}kg massa`}
                  {e.bodyFat && ` · ${e.bodyFat}% gordura`}
                </Text>
              </View>
              {e.note && <Text style={{ fontSize: 9, color: "#52525b", maxWidth: 100, textAlign: "right" }}>{e.note}</Text>}
            </View>
          ))}
        </View>
      </ScrollView>
    </>
  );
}

const inputStyle = { backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 12 };
