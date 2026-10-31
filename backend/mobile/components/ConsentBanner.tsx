import { useState, useEffect } from "react";
import { View, Text, TouchableOpacity } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { acceptConsent } from "@/api/privacy";

const CONSENT_KEY = "wegym_consent_accepted";

export function ConsentBanner() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(CONSENT_KEY).then((val) => {
      if (!val) setVisible(true);
    });
  }, []);

  const handleAccept = async () => {
    try {
      await Promise.all([
        acceptConsent("terms"),
        acceptConsent("privacy"),
        acceptConsent("data"),
      ]);
    } catch {}
    await AsyncStorage.setItem(CONSENT_KEY, "true");
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <View style={{ position: "absolute", bottom: 0, left: 0, right: 0, backgroundColor: "#18181b", borderTopWidth: 1, borderTopColor: "#27272a", padding: 16, paddingBottom: 32, zIndex: 1000 }}>
      <Text style={{ fontSize: 12, fontWeight: "800", color: "#fff", marginBottom: 4 }}>Privacidade</Text>
      <Text style={{ fontSize: 11, color: "#a1a1aa", lineHeight: 16, marginBottom: 12 }}>
        Usamos cookies e dados para melhorar sua experiência. Ao continuar, você aceita nossos termos de uso e política de privacidade.
      </Text>
      <View style={{ flexDirection: "row", gap: 10 }}>
        <TouchableOpacity onPress={() => setVisible(false)} style={{ flex: 1, backgroundColor: "#27272a", borderRadius: 12, padding: 12, alignItems: "center" }}>
          <Text style={{ color: "#71717a", fontSize: 11, fontWeight: "800" }}>Recusar</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={handleAccept} style={{ flex: 1, backgroundColor: "#ea580c", borderRadius: 12, padding: 12, alignItems: "center" }}>
          <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Aceitar</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}
