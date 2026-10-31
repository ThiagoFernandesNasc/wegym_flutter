import { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, Alert, KeyboardAvoidingView, Platform } from "react-native";
import { router, Stack } from "expo-router";
import { processPayment } from "@/api/payment";

const PLANS: Record<string, { amount: number; description: string }> = {
  mensal: { amount: 49.90, description: "wegym-pro-mensal" },
  anual: { amount: 399.90, description: "wegym-pro-anual" },
};

export default function PaymentScreen() {
  const [planType, setPlanType] = useState<"mensal" | "anual">("mensal");
  const [cardNumber, setCardNumber] = useState("");
  const [cardName, setCardName] = useState("");
  const [cardExpiry, setCardExpiry] = useState("");
  const [cardCvv, setCardCvv] = useState("");
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<"idle" | "configuring" | "processing" | "success" | "error">("idle");
  const [errorMsg, setErrorMsg] = useState("");

  const plan = PLANS[planType];

  const handlePay = async () => {
    if (!cardNumber || !cardName || !cardExpiry || !cardCvv) {
      Alert.alert("Atenção", "Preencha todos os dados do cartão");
      return;
    }
    setStatus("configuring");
    setLoading(true);

    await new Promise((r) => setTimeout(r, 500));
    setStatus("processing");

    try {
      await processPayment({
        planType,
        amount: plan.amount,
        token: cardNumber.replace(/\s/g, ""),
      });
      setStatus("success");
      setTimeout(() => router.replace("/pro"), 2000);
    } catch (err) {
      setStatus("error");
      setErrorMsg(err instanceof Error ? err.message : "Falha no pagamento");
    } finally {
      setLoading(false);
    }
  };

  const formatCard = (t: string) => {
    const digits = t.replace(/\D/g, "").slice(0, 16);
    return digits.replace(/(\d{4})(?=\d)/g, "$1 ");
  };

  const inputStyle = {
    backgroundColor: "#18181b",
    borderWidth: 1,
    borderColor: "#27272a",
    borderRadius: 14,
    padding: 14,
    fontSize: 14,
    color: "#fff",
    marginBottom: 12,
  };

  return (
    <>
      <Stack.Screen options={{ title: "Pagamento" }} />
      <KeyboardAvoidingView style={{ flex: 1, backgroundColor: "#09090b" }} behavior={Platform.OS === "ios" ? "padding" : undefined}>
        <ScrollView contentContainerStyle={{ padding: 20, paddingTop: 60 }}>
          {/* HEADER */}
          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 32 }}>
            <TouchableOpacity onPress={() => router.back()} style={{ backgroundColor: "#18181b", borderRadius: 12, padding: 8 }}>
              <Text style={{ color: "#fff", fontSize: 16 }}>←</Text>
            </TouchableOpacity>
            <View style={{ alignItems: "center" }}>
              <Text style={{ fontSize: 18, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Checkout</Text>
              <Text style={{ fontSize: 8, color: "#71717a", fontWeight: "700", textTransform: "uppercase", letterSpacing: 3, marginTop: 2 }}>WEGYM Elite</Text>
            </View>
            <Text style={{ fontSize: 20, color: "#ea580c" }}>🛡️</Text>
          </View>

          {/* PLAN SUMMARY */}
          <View style={{ backgroundColor: "linear-gradient(180deg, #18181b, #09090b)", borderWidth: 1, borderColor: "#27272a", borderRadius: 35, padding: 24, marginBottom: 24, flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
            <View>
              <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 2, color: "#ea580c", marginBottom: 4 }}>
                Plano Selecionado
              </Text>
              <Text style={{ fontSize: 20, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>WEGYM PRO</Text>
              <Text style={{ fontSize: 9, color: "#71717a", fontWeight: "700", textTransform: "uppercase", marginTop: 2 }}>
                {planType === "anual" ? "Anual" : "Mensal"}
              </Text>
            </View>
            <View style={{ alignItems: "flex-end" }}>
              <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>
                R$ {plan.amount.toFixed(2).replace(".", ",")}
              </Text>
              <Text style={{ fontSize: 8, color: "#71717a", fontWeight: "700", textTransform: "uppercase", marginTop: 2 }}>
                Pagamento único
              </Text>
            </View>
          </View>

          {/* PLAN TYPE TOGGLE */}
          <View style={{ flexDirection: "row", gap: 8, marginBottom: 20 }}>
            <TouchableOpacity
              onPress={() => { setPlanType("mensal"); setStatus("idle"); }}
              style={{ flex: 1, padding: 14, borderRadius: 14, backgroundColor: planType === "mensal" ? "#ea580c" : "#18181b", alignItems: "center", borderWidth: 1, borderColor: planType === "mensal" ? "#ea580c" : "#27272a" }}
            >
              <Text style={{ fontSize: 12, fontWeight: "800", textTransform: "uppercase", color: planType === "mensal" ? "#fff" : "#71717a" }}>Mensal</Text>
              <Text style={{ fontSize: 9, color: planType === "mensal" ? "#fdba74" : "#52525b", marginTop: 2 }}>R$ {PLANS.mensal.amount.toFixed(2)}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => { setPlanType("anual"); setStatus("idle"); }}
              style={{ flex: 1, padding: 14, borderRadius: 14, backgroundColor: planType === "anual" ? "#ea580c" : "#18181b", alignItems: "center", borderWidth: 1, borderColor: planType === "anual" ? "#ea580c" : "#27272a" }}
            >
              <Text style={{ fontSize: 12, fontWeight: "800", textTransform: "uppercase", color: planType === "anual" ? "#fff" : "#71717a" }}>Anual</Text>
              <Text style={{ fontSize: 9, color: planType === "anual" ? "#fdba74" : "#52525b", marginTop: 2 }}>R$ {PLANS.anual.amount.toFixed(2)}</Text>
            </TouchableOpacity>
          </View>

          {/* PAYMENT FORM / STATUS */}
          <View style={{ backgroundColor: "#18181b50", borderWidth: 1, borderColor: "#27272a", borderRadius: 35, padding: 24, minHeight: 320, justifyContent: "center" }}>
            {status === "success" ? (
              <View style={{ alignItems: "center", paddingVertical: 40 }}>
                <Text style={{ fontSize: 56, marginBottom: 12 }}>✅</Text>
                <Text style={{ color: "#22c55e", fontSize: 16, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase", marginBottom: 4 }}>
                  Pagamento aprovado!
                </Text>
                <Text style={{ color: "#71717a", fontSize: 10 }}>Redirecionando...</Text>
              </View>
            ) : status === "error" ? (
              <View style={{ alignItems: "center", paddingVertical: 40 }}>
                <Text style={{ fontSize: 56, marginBottom: 12 }}>❌</Text>
                <Text style={{ color: "#ef4444", fontSize: 16, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase", marginBottom: 4 }}>
                  Pagamento recusado
                </Text>
                <Text style={{ color: "#71717a", fontSize: 10, marginBottom: 16, textAlign: "center" }}>{errorMsg}</Text>
                <TouchableOpacity
                  onPress={() => setStatus("idle")}
                  style={{ backgroundColor: "#ea580c", borderRadius: 12, padding: 12, paddingHorizontal: 24 }}
                >
                  <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Tentar novamente</Text>
                </TouchableOpacity>
              </View>
            ) : status === "configuring" || status === "processing" ? (
              <View style={{ alignItems: "center", paddingVertical: 60 }}>
                <ActivityIndicator size="large" color="#ea580c" />
                <Text style={{ color: "#71717a", fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 2, marginTop: 16 }}>
                  {status === "configuring" ? "Configurando Gateway..." : "Processando pagamento..."}
                </Text>
                <Text style={{ color: "#3f3f46", fontSize: 8, fontWeight: "700", textTransform: "uppercase", marginTop: 4 }}>
                  Ambiente Criptografado de Ponta a Ponta
                </Text>
              </View>
            ) : (
              <>
                <TextInput
                  value={cardNumber}
                  onChangeText={(t) => setCardNumber(formatCard(t))}
                  placeholder="Número do cartão"
                  placeholderTextColor="#71717a"
                  keyboardType="numeric"
                  style={inputStyle}
                />
                <TextInput
                  value={cardName}
                  onChangeText={setCardName}
                  placeholder="Nome no cartão"
                  placeholderTextColor="#71717a"
                  style={inputStyle}
                />
                <View style={{ flexDirection: "row", gap: 12 }}>
                  <TextInput
                    value={cardExpiry}
                    onChangeText={setCardExpiry}
                    placeholder="MM/AA"
                    placeholderTextColor="#71717a"
                    keyboardType="numeric"
                    style={{ ...inputStyle, flex: 1 }}
                  />
                  <TextInput
                    value={cardCvv}
                    onChangeText={setCardCvv}
                    placeholder="CVV"
                    placeholderTextColor="#71717a"
                    keyboardType="numeric"
                    style={{ ...inputStyle, flex: 1 }}
                  />
                </View>
                <TouchableOpacity
                  onPress={handlePay}
                  disabled={loading}
                  style={{ backgroundColor: "#ea580c", borderRadius: 16, padding: 16, alignItems: "center", marginTop: 4 }}
                >
                  <Text style={{ color: "#fff", fontSize: 13, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase" }}>
                    Pagar R$ {plan.amount.toFixed(2).replace(".", ",")}
                  </Text>
                </TouchableOpacity>
              </>
            )}
          </View>

          {/* POWERED BY */}
          <View style={{ alignItems: "center", marginTop: 32, gap: 8 }}>
            <Text style={{ fontSize: 8, fontWeight: "900", textTransform: "uppercase", letterSpacing: 3, color: "#3f3f46", opacity: 0.5 }}>
              Powered by Mercado Pago
            </Text>
            <View style={{ flexDirection: "row", gap: 8, opacity: 0.2 }}>
              {[1, 2, 3].map((i) => (
                <View key={i} style={{ width: 32, height: 20, backgroundColor: "#27272a", borderRadius: 4 }} />
              ))}
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </>
  );
}
