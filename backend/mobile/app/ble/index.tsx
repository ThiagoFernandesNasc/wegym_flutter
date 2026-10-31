import { useState, useEffect, useRef } from "react";
import { View, Text, TouchableOpacity, ActivityIndicator, ScrollView } from "react-native";
import { Stack, router } from "expo-router";
import { BLEManager, type BLEState, type HRData } from "@/services/ble";

export default function BLEScreen() {
  const [bleState, setBleState] = useState<BLEState>("idle");
  const [hr, setHr] = useState<HRData | null>(null);
  const [history, setHistory] = useState<number[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [deviceName, setDeviceName] = useState<string | null>(null);
  const [battery, setBattery] = useState<number | null>(null);
  const managerRef = useRef<BLEManager | null>(null);

  useEffect(() => {
    return () => { managerRef.current?.destroy(); };
  }, []);

  useEffect(() => {
    if (hr && hr.bpm > 0) {
      setHistory((prev) => [...prev.slice(-59), hr.bpm]);
    }
  }, [hr]);

  const handleState = (s: BLEState) => {
    setBleState(s);
    if (s === "connected") setError(null);
    if (s === "disconnected" || s === "idle") {
      setDeviceName(null);
      setBattery(null);
    }
  };
  const handleHR = (d: HRData) => setHr(d);
  const handleError = (e: string) => { setError(e); setBleState("idle"); };
  const handleDevice = (name: string) => setDeviceName(name);
  const handleBattery = (level: number) => setBattery(level);

  const connect = () => {
    setError(null);
    setHr(null);
    setHistory([]);
    const manager = new BLEManager({
      onHR: handleHR, onState: handleState, onError: handleError,
      onDevice: handleDevice, onBattery: handleBattery,
    });
    managerRef.current = manager;
    manager.scan();
  };

  const disconnect = () => {
    managerRef.current?.disconnect();
    setBleState("idle");
    setHr(null);
  };

  const maxBpm = Math.max(...history, 0);
  const minBpm = Math.min(...history.filter(Boolean), 0);
  const avgBpm = history.length > 0 ? Math.round(history.reduce((a, b) => a + b, 0) / history.length) : 0;

  const statusColor: Record<string, string> = {
    idle: "#71717a", scanning: "#facc15", connecting: "#facc15",
    connected: "#22c55e", disconnected: "#dc2626", unsupported: "#dc2626",
  };

  const statusLabel: Record<string, string> = {
    idle: "Desconectado", scanning: "Escaneando...", connecting: "Conectando...",
    connected: "Conectado", disconnected: "Desconectado", unsupported: "Não suportado",
  };

  return (
    <>
      <Stack.Screen options={{ title: "Monitor Cardíaco", headerShown: true,
        headerStyle: { backgroundColor: "#09090b" }, headerTintColor: "#fff",
        headerTitleStyle: { fontWeight: "900" } }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }} contentContainerStyle={{ padding: 20, paddingBottom: 60 }}>
        <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 24, alignItems: "center", marginBottom: 16 }}>
          <View style={{ width: 120, height: 120, borderRadius: 60, backgroundColor: "#27272a", justifyContent: "center", alignItems: "center", marginBottom: 16 }}>
            <Text style={{ fontSize: 48 }}>❤️</Text>
          </View>
          {bleState === "connected" && hr ? (
            <>
              <Text style={{ fontSize: 64, fontWeight: "900", fontStyle: "italic", color: "#ea580c", fontVariant: ["tabular-nums"] }}>{hr.bpm}</Text>
              <Text style={{ fontSize: 12, color: "#71717a", textTransform: "uppercase", letterSpacing: 2, marginTop: 4 }}>Batimentos por minuto</Text>
            </>
          ) : (
            <Text style={{ fontSize: 20, fontWeight: "800", color: "#a1a1aa" }}>--</Text>
          )}
          <View style={{ flexDirection: "row", alignItems: "center", gap: 8, marginTop: 12 }}>
            <View style={{ width: 10, height: 10, borderRadius: 5, backgroundColor: statusColor[bleState] }} />
            <Text style={{ fontSize: 11, color: statusColor[bleState], fontWeight: "700" }}>{statusLabel[bleState]}</Text>
          </View>
        </View>

        {error && (
          <View style={{ backgroundColor: "#dc262610", borderWidth: 1, borderColor: "#dc262620", borderRadius: 16, padding: 14, marginBottom: 16 }}>
            <Text style={{ color: "#dc2626", fontSize: 11, textAlign: "center" }}>{error}</Text>
          </View>
        )}

        {deviceName && (
          <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
            <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 8 }}>Dispositivo</Text>
            <Text style={{ color: "#fff", fontSize: 15, fontWeight: "700" }}>{deviceName}</Text>
            {battery != null && <Text style={{ color: "#a1a1aa", fontSize: 11, marginTop: 4 }}>Bateria: {battery}%</Text>}
          </View>
        )}

        {bleState === "connected" && hr && history.length > 1 && (
          <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
            <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Gráfico de BPM</Text>
            <View style={{ flexDirection: "row", alignItems: "flex-end", height: 100, gap: 2 }}>
              {history.map((bpm, i) => {
                const barH = Math.max(4, (bpm / 220) * 100);
                return <View key={i} style={{ flex: 1, height: barH, backgroundColor: bpm > 140 ? "#dc2626" : bpm > 100 ? "#ea580c" : "#22c55e", borderRadius: 2, opacity: 0.8 }} />;
              })}
            </View>
            <View style={{ flexDirection: "row", justifyContent: "space-between", marginTop: 10 }}>
              <View style={{ alignItems: "center" }}>
                <Text style={{ fontSize: 9, color: "#71717a", textTransform: "uppercase" }}>Mín</Text>
                <Text style={{ fontSize: 16, fontWeight: "800", color: "#22c55e" }}>{minBpm}</Text>
              </View>
              <View style={{ alignItems: "center" }}>
                <Text style={{ fontSize: 9, color: "#71717a", textTransform: "uppercase" }}>Méd</Text>
                <Text style={{ fontSize: 16, fontWeight: "800", color: "#ea580c" }}>{avgBpm}</Text>
              </View>
              <View style={{ alignItems: "center" }}>
                <Text style={{ fontSize: 9, color: "#71717a", textTransform: "uppercase" }}>Máx</Text>
                <Text style={{ fontSize: 16, fontWeight: "800", color: "#dc2626" }}>{maxBpm}</Text>
              </View>
            </View>
          </View>
        )}

        {bleState === "connected" ? (
          <TouchableOpacity onPress={disconnect} style={{ backgroundColor: "#dc2626", borderRadius: 16, padding: 16, alignItems: "center", marginBottom: 12 }}>
            <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>Desconectar</Text>
          </TouchableOpacity>
        ) : bleState === "scanning" || bleState === "connecting" ? (
          <View style={{ alignItems: "center", paddingVertical: 20 }}>
            <ActivityIndicator size="large" color="#ea580c" />
            <Text style={{ color: "#a1a1aa", fontSize: 12, marginTop: 10 }}>Procurando dispositivos Bluetooth...</Text>
            <TouchableOpacity onPress={disconnect} style={{ marginTop: 16, padding: 12 }}>
              <Text style={{ color: "#71717a", fontSize: 11, fontWeight: "700" }}>Cancelar</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <TouchableOpacity onPress={connect} style={{ backgroundColor: "#ea580c", borderRadius: 16, padding: 16, alignItems: "center", marginBottom: 12 }}>
            <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>🔍 Escanear dispositivos</Text>
          </TouchableOpacity>
        )}

        <TouchableOpacity onPress={() => router.back()} style={{ alignItems: "center", marginTop: 8 }}>
          <Text style={{ color: "#71717a", fontSize: 11, fontWeight: "700" }}>Voltar</Text>
        </TouchableOpacity>
      </ScrollView>
    </>
  );
}
