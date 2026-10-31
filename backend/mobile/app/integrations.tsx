import { useEffect, useState } from "react";
import { View, Text, TouchableOpacity, ScrollView, ActivityIndicator, Alert } from "react-native";
import { router, Stack } from "expo-router";
import { getIntegrations, syncProvider, disconnectProvider } from "@/api/integrations";
import type { Integration } from "@/api/integrations";
import { appleHealth } from "@/services/apple-health";
import { healthConnect } from "@/services/health-connect";
import { Platform } from "react-native";

type ProviderInfo = {
  id: string;
  name: string;
  icon: string;
  description: string;
  color: string;
};

const PROVIDERS: ProviderInfo[] = [
  { id: "strava", name: "Strava", icon: "🎽", description: "Importe corridas, pedaladas e natação", color: "#ea580c" },
  { id: "google_fit", name: "Google Fit", icon: "❤️", description: "Sincronize dados de saúde do Google", color: "#3b82f6" },
];

export default function IntegrationsScreen() {
  const [integrations, setIntegrations] = useState<Integration[]>([]);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState<string | null>(null);
  const [healthReady, setHealthReady] = useState<Record<string, boolean>>({});

  useEffect(() => {
    loadAll();
  }, []);

  const loadAll = async () => {
    try {
      const [ints] = await Promise.all([getIntegrations()]);
      setIntegrations(ints);

      if (Platform.OS === "ios") {
        appleHealth.isAvailable().then((avail) => setHealthReady((p) => ({ ...p, apple_health: avail })));
      }
      if (Platform.OS === "android") {
        const avail = await healthConnect.isAvailable();
        setHealthReady((p) => ({ ...p, health_connect: avail }));
      }
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  };

  const handleSync = async (provider: string) => {
    setSyncing(provider);
    try {
      const res = await syncProvider(provider as "strava" | "google_fit");
      Alert.alert("Sincronizado!", `${res.imported} atividades importadas.`);
      await loadAll();
    } catch {
      Alert.alert("Erro", "Falha ao sincronizar");
    } finally {
      setSyncing(null);
    }
  };

  const handleDisconnect = (provider: string) => {
    Alert.alert("Desconectar", "Tem certeza?", [
      { text: "Cancelar", style: "cancel" },
      { text: "Desconectar", style: "destructive", onPress: async () => {
        try {
          await disconnectProvider(provider as "strava" | "google_fit");
          setIntegrations((prev) => prev.filter((i) => i.provider !== provider));
        } catch {
          Alert.alert("Erro", "Falha ao desconectar");
        }
      }},
    ]);
  };

  return (
    <View style={{ flex: 1, backgroundColor: "#09090b" }}>
      <Stack.Screen options={{ headerShown: false }} />
      <ScrollView contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
        <TouchableOpacity onPress={() => router.back()} style={{ marginBottom: 20 }}>
          <Text style={{ color: "#ea580c", fontSize: 14, fontWeight: "800" }}>{"< Voltar"}</Text>
        </TouchableOpacity>

        <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 4 }}>
          Integrações
        </Text>
        <Text style={{ fontSize: 12, color: "#a1a1aa", marginBottom: 24 }}>
          Conecte seus apps favoritos
        </Text>

        {/* Health platform integration */}
        {Platform.OS === "ios" && (
          <NativeIntegrationCard
            name="Apple Health"
            icon="🍎"
            description="Sincronizar treinos, batimentos e passos"
            color="#dc2626"
            available={healthReady.apple_health ?? false}
            onConnect={async () => {
              try {
                await appleHealth.requestPermissions();
                Alert.alert("Conectado!", "Apple Health vinculado com sucesso");
                setHealthReady((p) => ({ ...p, apple_health: true }));
              } catch {
                Alert.alert("Erro", "Falha ao conectar Apple Health");
              }
            }}
          />
        )}

        {Platform.OS === "android" && (
          <NativeIntegrationCard
            name="Health Connect"
            icon="📱"
            description="Sincronizar treinos, batimentos e passos"
            color="#22c55e"
            available={healthReady.health_connect ?? false}
            onConnect={async () => {
              try {
                await healthConnect.requestPermissions();
                Alert.alert("Conectado!", "Health Connect vinculado com sucesso");
                setHealthReady((p) => ({ ...p, health_connect: true }));
              } catch {
                Alert.alert("Erro", "Falha ao conectar Health Connect");
              }
            }}
          />
        )}

        {loading ? (
          <ActivityIndicator size="large" color="#ea580c" style={{ marginTop: 40 }} />
        ) : (
          PROVIDERS.map((p) => {
            const int = integrations.find((i) => i.provider === p.id);
            const connected = !!int;

            return (
              <View key={p.id} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: connected ? "#22c55e30" : "#27272a", borderRadius: 20, padding: 16, marginBottom: 12 }}>
                <View style={{ flexDirection: "row", alignItems: "center", gap: 14 }}>
                  <View style={{ width: 48, height: 48, borderRadius: 16, backgroundColor: p.color + "20", justifyContent: "center", alignItems: "center" }}>
                    <Text style={{ fontSize: 24 }}>{p.icon}</Text>
                  </View>
                  <View style={{ flex: 1 }}>
                    <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
                      <Text style={{ fontSize: 14, fontWeight: "800", fontStyle: "italic", color: "#fff" }}>{p.name}</Text>
                      {connected && <Text style={{ fontSize: 10, color: "#22c55e", fontWeight: "700" }}>CONECTADO</Text>}
                    </View>
                    <Text style={{ fontSize: 10, color: "#71717a", marginTop: 2 }}>{p.description}</Text>
                    {connected && int?.lastSyncAt && (
                      <Text style={{ fontSize: 9, color: "#52525b", marginTop: 4 }}>
                        Última sincronização: {new Date(int.lastSyncAt).toLocaleDateString("pt-BR")}
                      </Text>
                    )}
                  </View>
                  {connected ? (
                    <View style={{ flexDirection: "row", gap: 8 }}>
                      <TouchableOpacity onPress={() => handleSync(p.id)} disabled={syncing === p.id} style={{ padding: 10, borderRadius: 12, backgroundColor: "#27272a" }}>
                        {syncing === p.id ? <ActivityIndicator size="small" color="#ea580c" /> : <Text style={{ fontSize: 16 }}>🔄</Text>}
                      </TouchableOpacity>
                      <TouchableOpacity onPress={() => handleDisconnect(p.id)} style={{ padding: 10, borderRadius: 12, backgroundColor: "#dc262620" }}>
                        <Text style={{ fontSize: 16 }}>🔗</Text>
                      </TouchableOpacity>
                    </View>
                  ) : (
                    <TouchableOpacity
                      onPress={() => {
                        // Open OAuth URL (in-app browser)
                        Alert.alert("Conectar", `Para conectar o ${p.name}, acesse o perfil no site do WEGYM.`);
                      }}
                      style={{ backgroundColor: p.color, borderRadius: 14, paddingHorizontal: 16, paddingVertical: 10 }}
                    >
                      <Text style={{ color: "#fff", fontSize: 11, fontWeight: "800", textTransform: "uppercase" }}>Conectar</Text>
                    </TouchableOpacity>
                  )}
                </View>
              </View>
            );
          })
        )}
      </ScrollView>
    </View>
  );
}

function NativeIntegrationCard({
  name, icon, description, color, available, onConnect,
}: {
  name: string; icon: string; description: string; color: string; available: boolean; onConnect: () => void;
}) {
  return (
    <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: color + "30", borderRadius: 20, padding: 16, marginBottom: 12 }}>
      <View style={{ flexDirection: "row", alignItems: "center", gap: 14 }}>
        <View style={{ width: 48, height: 48, borderRadius: 16, backgroundColor: color + "20", justifyContent: "center", alignItems: "center" }}>
          <Text style={{ fontSize: 24 }}>{icon}</Text>
        </View>
        <View style={{ flex: 1 }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
            <Text style={{ fontSize: 14, fontWeight: "800", fontStyle: "italic", color: "#fff" }}>{name}</Text>
            <View style={{ backgroundColor: available ? "#22c55e20" : "#71717a20", borderRadius: 10, paddingHorizontal: 8, paddingVertical: 2 }}>
              <Text style={{ fontSize: 8, fontWeight: "800", color: available ? "#22c55e" : "#71717a" }}>
                {available ? "DISPONÍVEL" : "INDISPONÍVEL"}
              </Text>
            </View>
          </View>
          <Text style={{ fontSize: 10, color: "#71717a", marginTop: 2 }}>{description}</Text>
        </View>
        {available && (
          <TouchableOpacity onPress={onConnect} style={{ backgroundColor: color, borderRadius: 14, paddingHorizontal: 16, paddingVertical: 10 }}>
            <Text style={{ color: "#fff", fontSize: 11, fontWeight: "800", textTransform: "uppercase" }}>Vincular</Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
  );
}
