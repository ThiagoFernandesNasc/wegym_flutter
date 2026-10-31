import { useState } from "react";
import { View, Text, TouchableOpacity, ScrollView } from "react-native";
import { router, Stack } from "expo-router";

export default function ProScreen() {
  const [isYearly, setIsYearly] = useState(false);

  const plans = [
    { icon: "📍", title: "Elite", features: ["Geolocalização", "Teste grátis", "Pagamento flexível", "Análise de vídeo"] },
    { icon: "📊", title: "Recovery", features: ["Monitoramento de sono", "Rotinas de mobilidade", "Recuperação", "Wellness score"] },
    { icon: "👛", title: "Wallet", features: ["Cashback", "Acesso VIP", "Zero taxas", "Seguro incluído"] },
  ];

  const monthlyPrice = 49.90;
  const yearlyPrice = 399.90;

  return (
    <>
      <Stack.Screen options={{ title: "WEGYM PRO" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          <View style={{ alignItems: "center", marginBottom: 24 }}>
            <Text style={{ fontSize: 28, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>WEGYM</Text>
            <Text style={{ fontSize: 36, fontWeight: "900", fontStyle: "italic", color: "#ea580c" }}>PRO</Text>
            <Text style={{ fontSize: 12, color: "#71717a", marginTop: 8, textAlign: "center" }}>Desbloqueie o potencial máximo</Text>
          </View>

          <View style={{ flexDirection: "row", gap: 8, marginBottom: 20 }}>
            <TouchableOpacity onPress={() => setIsYearly(false)} style={{ flex: 1, padding: 14, borderRadius: 14, backgroundColor: !isYearly ? "#ea580c" : "#18181b", alignItems: "center" }}>
              <Text style={{ fontSize: 13, fontWeight: "900", color: !isYearly ? "#fff" : "#71717a" }}>Mensal</Text>
              <Text style={{ fontSize: 10, color: !isYearly ? "#fdba74" : "#52525b", marginTop: 2 }}>R$ {monthlyPrice.toFixed(2)}</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={() => setIsYearly(true)} style={{ flex: 1, padding: 14, borderRadius: 14, backgroundColor: isYearly ? "#ea580c" : "#18181b", alignItems: "center" }}>
              <Text style={{ fontSize: 13, fontWeight: "900", color: isYearly ? "#fff" : "#71717a" }}>Anual</Text>
              <Text style={{ fontSize: 10, color: isYearly ? "#fdba74" : "#52525b", marginTop: 2 }}>R$ {yearlyPrice.toFixed(2)}</Text>
            </TouchableOpacity>
          </View>

          {plans.map((plan) => (
            <View key={plan.title} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 20, marginBottom: 12 }}>
              <Text style={{ fontSize: 18, marginBottom: 8 }}>{plan.icon}</Text>
              <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 12 }}>{plan.title}</Text>
              {plan.features.map((f, i) => (
                <View key={i} style={{ flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 6 }}>
                  <Text style={{ color: "#10b981", fontSize: 12 }}>✓</Text>
                  <Text style={{ color: "#a1a1aa", fontSize: 12 }}>{f}</Text>
                </View>
              ))}
            </View>
          ))}

          <TouchableOpacity onPress={() => router.push("/payment")} style={{ backgroundColor: "#ea580c", borderRadius: 20, padding: 18, alignItems: "center", marginTop: 8 }}>
            <Text style={{ color: "#fff", fontSize: 14, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase" }}>
              Assinar Agora — R$ {(isYearly ? yearlyPrice : monthlyPrice).toFixed(2)}
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </>
  );
}
