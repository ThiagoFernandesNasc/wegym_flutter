import { useCallback, useEffect, useState } from "react";
import { View, Text, TouchableOpacity, ScrollView, ActivityIndicator, Alert } from "react-native";
import { Stack } from "expo-router";
import { getAppointments, cancelAppointment, type Appointment } from "@/api/appointments";
import { getAvailableSlots, bookSlot, type TimeSlot } from "@/api/slots";

const STATUS_STYLES: Record<string, { color: string; bg: string }> = {
  pending: { color: "#eab308", bg: "#eab30820" },
  confirmed: { color: "#10b981", bg: "#10b98120" },
  completed: { color: "#71717a", bg: "#71717a20" },
  cancelled: { color: "#e11d48", bg: "#e11d4820" },
};

export default function AppointmentsScreen() {
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [showBook, setShowBook] = useState(false);
  const [slots, setSlots] = useState<TimeSlot[]>([]);
  const [slotDate, setSlotDate] = useState(new Date().toISOString().slice(0, 10));
  const [slotsLoading, setSlotsLoading] = useState(false);

  const load = useCallback(async () => {
    try { setAppointments(await getAppointments()); } catch { /* silent */ } finally { setLoading(false); }
  }, []);

  useEffect(() => { load(); }, [load]);

  const loadSlots = async () => {
    setSlotsLoading(true);
    try { setSlots(await getAvailableSlots("", slotDate)); } catch { /* silent */ } finally { setSlotsLoading(false); }
  };

  const handleCancel = (id: string) => {
    Alert.alert("Cancelar", "Tem certeza?", [
      { text: "Não", style: "cancel" },
      { text: "Sim", style: "destructive", onPress: async () => { await cancelAppointment(id); load(); } },
    ]);
  };

  const handleBook = async (slotId: string) => {
    try { await bookSlot(slotId); setShowBook(false); load(); } catch { Alert.alert("Erro", "Falha ao agendar"); }
  };

  return (
    <>
      <Stack.Screen options={{ title: "Agendamentos" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
            <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Agendamentos</Text>
            <TouchableOpacity onPress={() => { setShowBook(!showBook); if (!showBook) loadSlots(); }} style={{ backgroundColor: "#ea580c", borderRadius: 12, paddingHorizontal: 14, paddingVertical: 8 }}>
              <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>{showBook ? "Fechar" : "+ Novo"}</Text>
            </TouchableOpacity>
          </View>

          {showBook && (
            <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Novo agendamento</Text>
              <TouchableOpacity onPress={loadSlots} style={{ marginBottom: 12 }}>
                <Text style={{ color: "#ea580c", fontSize: 11, fontWeight: "700" }}>🔄 Buscar horários disponíveis</Text>
              </TouchableOpacity>
              {slotsLoading ? <ActivityIndicator size="small" color="#ea580c" /> : slots.length === 0 ? (
                <Text style={{ color: "#52525b", fontSize: 12, textAlign: "center", paddingVertical: 12 }}>Nenhum horário disponível</Text>
              ) : slots.filter((s) => s.available).map((slot) => (
                <TouchableOpacity key={slot.id} onPress={() => handleBook(slot.id)} style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
                  <Text style={{ color: "#fff", fontSize: 13, fontWeight: "700" }}>{slot.startTime.slice(0, 5)} - {slot.endTime.slice(0, 5)}</Text>
                  <Text style={{ color: "#22c55e", fontSize: 10, fontWeight: "800" }}>Agendar</Text>
                </TouchableOpacity>
              ))}
            </View>
          )}

          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : appointments.length === 0 ? (
            <View style={{ alignItems: "center", paddingTop: 60 }}>
              <Text style={{ fontSize: 48, marginBottom: 12 }}>📅</Text>
              <Text style={{ color: "#71717a", fontSize: 14 }}>Nenhum agendamento</Text>
            </View>
          ) : appointments.map((a) => {
            const s = STATUS_STYLES[a.status] || { color: "#71717a", bg: "#71717a20" };
            return (
              <View key={a.id} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 12 }}>
                <View style={{ flexDirection: "row", justifyContent: "space-between" }}>
                  <View style={{ flexDirection: "row", gap: 12, flex: 1 }}>
                    <View style={{ width: 40, height: 40, borderRadius: 14, backgroundColor: "#ea580c20", alignItems: "center", justifyContent: "center" }}>
                      <Text style={{ fontSize: 18 }}>📅</Text>
                    </View>
                    <View>
                      <Text style={{ fontSize: 13, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{a.athlete?.displayName || a.personal?.displayName}</Text>
                      <Text style={{ fontSize: 11, color: "#a1a1aa", marginTop: 2 }}>
                        {new Date(a.date).toLocaleDateString("pt-BR")} às {new Date(a.date).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}
                      </Text>
                      <Text style={{ fontSize: 9, fontWeight: "800", textTransform: "uppercase", color: s.color, backgroundColor: s.bg, paddingHorizontal: 8, paddingVertical: 2, borderRadius: 8, alignSelf: "flex-start", marginTop: 6, overflow: "hidden" }}>{a.status}</Text>
                    </View>
                  </View>
                  {a.status === "pending" && (
                    <TouchableOpacity onPress={() => handleCancel(a.id)}>
                      <Text style={{ color: "#e11d48", fontSize: 10, fontWeight: "800", textTransform: "uppercase" }}>Cancelar</Text>
                    </TouchableOpacity>
                  )}
                </View>
              </View>
            );
          })}
        </View>
      </ScrollView>
    </>
  );
}
