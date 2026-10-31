import { useState, useEffect, useRef } from "react";
import { View, Text, TouchableOpacity, ActivityIndicator } from "react-native";
import { BLEManager, type BLEState, type HRData } from "@/services/ble";

export function BLEConnect() {
  const [bleState, setBleState] = useState<BLEState>("idle");
  const [hr, setHr] = useState<HRData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const managerRef = useRef<BLEManager | null>(null);

  useEffect(() => {
    return () => { managerRef.current?.destroy(); };
  }, []);

  const handleState = (s: BLEState) => setBleState(s);
  const handleHR = (d: HRData) => setHr(d);
  const handleError = (e: string) => { setError(e); setBleState("idle"); };

  const connect = () => {
    setError(null);
    setHr(null);
    const manager = new BLEManager({ onHR: handleHR, onState: handleState, onError: handleError });
    managerRef.current = manager;
    manager.scan();
  };

  const disconnect = () => {
    managerRef.current?.disconnect();
    setBleState("idle");
    setHr(null);
  };

  const statusColor: Record<string, string> = {
    idle: "#71717a", scanning: "#facc15", connecting: "#facc15",
    connected: "#22c55e", disconnected: "#dc2626", unsupported: "#dc2626",
  };

  const statusLabel: Record<string, string> = {
    idle: "Desconectado", scanning: "Escaneando...", connecting: "Conectando...",
    connected: "Conectado", disconnected: "Desconectado", unsupported: "Não suportado",
  };

  return (
    <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
      <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
        <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a" }}>Frequência Cardíaca (BLE)</Text>
        <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
          <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: statusColor[bleState] }} />
          <Text style={{ fontSize: 9, color: statusColor[bleState], fontWeight: "700" }}>{statusLabel[bleState]}</Text>
        </View>
      </View>

      {error && (
        <Text style={{ fontSize: 10, color: "#dc2626", marginBottom: 8 }}>{error}</Text>
      )}

      {bleState === "connected" && hr ? (
        <View style={{ alignItems: "center", paddingVertical: 12 }}>
          <Text style={{ fontSize: 48, fontWeight: "900", fontStyle: "italic", color: "#ea580c", fontVariant: ["tabular-nums"] }}>{hr.bpm}</Text>
          <Text style={{ fontSize: 10, color: "#71717a", textTransform: "uppercase", marginTop: 2 }}>BPM</Text>
          {hr.rr.length > 0 && (
            <Text style={{ fontSize: 9, color: "#52525b", marginTop: 4 }}>RR: {hr.rr.map((v) => `${v}ms`).join(", ")}</Text>
          )}
          <TouchableOpacity onPress={disconnect} style={{ backgroundColor: "#dc2626", borderRadius: 10, paddingHorizontal: 16, paddingVertical: 8, marginTop: 12 }}>
            <Text style={{ color: "#fff", fontSize: 10, fontWeight: "800" }}>Desconectar</Text>
          </TouchableOpacity>
        </View>
      ) : bleState === "scanning" || bleState === "connecting" ? (
        <View style={{ alignItems: "center", paddingVertical: 16 }}>
          <ActivityIndicator size="large" color="#ea580c" />
          <Text style={{ color: "#a1a1aa", fontSize: 11, marginTop: 8 }}>Procurando dispositivos...</Text>
        </View>
      ) : (
        <TouchableOpacity onPress={connect} disabled={bleState !== "idle"} style={{ backgroundColor: bleState === "idle" ? "#ea580c" : "#27272a", borderRadius: 12, padding: 14, alignItems: "center" }}>
          <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Conectar Smartwatch</Text>
        </TouchableOpacity>
      )}

      <Text style={{ fontSize: 8, color: "#52525b", marginTop: 8, textAlign: "center" }}>
        Conecte seu monitor cardíaco Bluetooth para ver os BPM em tempo real
      </Text>
    </View>
  );
}
