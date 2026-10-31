import { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ActivityIndicator, Alert } from "react-native";
import { router } from "expo-router";

export default function ResetPasswordScreen() {
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [step, setStep] = useState<"email" | "code" | "password">("email");
  const [loading, setLoading] = useState(false);

  const requestCode = async () => {
    if (!email.trim()) { Alert.alert("Atenção", "Informe seu email"); return; }
    setLoading(true);
    try {
      const r = await fetch(`${process.env.EXPO_PUBLIC_API_URL}/api/auth/reset-password`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      if (r.ok) { Alert.alert("Código enviado!", "Verifique seu email"); setStep("code"); }
      else { const d = await r.json(); Alert.alert("Erro", d.error || "Email não encontrado"); }
    } catch { Alert.alert("Erro", "Falha ao conectar"); } finally { setLoading(false); }
  };

  const verifyCode = async () => {
    if (!code.trim()) { Alert.alert("Atenção", "Informe o código"); return; }
    setLoading(true);
    try {
      const r = await fetch(`${process.env.EXPO_PUBLIC_API_URL}/api/auth/verify-reset-code`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, code }),
      });
      if (r.ok) setStep("password");
      else { const d = await r.json(); Alert.alert("Erro", d.error || "Código inválido"); }
    } catch { Alert.alert("Erro", "Falha ao conectar"); } finally { setLoading(false); }
  };

  const resetPassword = async () => {
    if (newPassword !== confirmPassword) { Alert.alert("Erro", "Senhas não conferem"); return; }
    if (newPassword.length < 6) { Alert.alert("Erro", "Mínimo 6 caracteres"); return; }
    setLoading(true);
    try {
      const r = await fetch(`${process.env.EXPO_PUBLIC_API_URL}/api/auth/reset-password/confirm`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, code, password: newPassword }),
      });
      if (r.ok) { Alert.alert("Senha redefinida!", "Faça login com sua nova senha", [{ text: "OK", onPress: () => router.back() }]); }
      else { const d = await r.json(); Alert.alert("Erro", d.error || "Falha ao redefinir"); }
    } catch { Alert.alert("Erro", "Falha ao conectar"); } finally { setLoading(false); }
  };

  const inputStyle = { backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 12 };

  return (
    <View style={{ flex: 1, backgroundColor: "#09090b", padding: 24, paddingTop: 60 }}>
      <TouchableOpacity onPress={() => router.back()} style={{ marginBottom: 24 }}>
        <Text style={{ color: "#ea580c", fontSize: 14, fontWeight: "800" }}>{"< Voltar"}</Text>
      </TouchableOpacity>
      <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 8 }}>Redefinir Senha</Text>
      <Text style={{ fontSize: 12, color: "#a1a1aa", marginBottom: 24 }}>
        {step === "email" ? "Digite seu email para receber o código" : step === "code" ? "Digite o código recebido por email" : "Crie sua nova senha"}
      </Text>

      {step === "email" && (
        <>
          <TextInput value={email} onChangeText={setEmail} placeholder="seu@email.com" placeholderTextColor="#71717a" autoCapitalize="none" keyboardType="email-address" style={inputStyle} />
          <TouchableOpacity onPress={requestCode} disabled={loading} style={{ backgroundColor: "#ea580c", borderRadius: 16, padding: 16, alignItems: "center", opacity: loading ? 0.6 : 1 }}>
            {loading ? <ActivityIndicator color="#fff" /> : <Text style={{ color: "#fff", fontSize: 13, fontWeight: "900", textTransform: "uppercase" }}>Enviar código</Text>}
          </TouchableOpacity>
        </>
      )}

      {step === "code" && (
        <>
          <TextInput value={code} onChangeText={setCode} placeholder="000000" placeholderTextColor="#71717a" keyboardType="number-pad" style={inputStyle} />
          <TouchableOpacity onPress={verifyCode} disabled={loading} style={{ backgroundColor: "#ea580c", borderRadius: 16, padding: 16, alignItems: "center", opacity: loading ? 0.6 : 1 }}>
            {loading ? <ActivityIndicator color="#fff" /> : <Text style={{ color: "#fff", fontSize: 13, fontWeight: "900", textTransform: "uppercase" }}>Verificar código</Text>}
          </TouchableOpacity>
        </>
      )}

      {step === "password" && (
        <>
          <TextInput value={newPassword} onChangeText={setNewPassword} placeholder="Nova senha" placeholderTextColor="#71717a" secureTextEntry style={inputStyle} />
          <TextInput value={confirmPassword} onChangeText={setConfirmPassword} placeholder="Confirmar nova senha" placeholderTextColor="#71717a" secureTextEntry style={inputStyle} />
          <TouchableOpacity onPress={resetPassword} disabled={loading} style={{ backgroundColor: "#ea580c", borderRadius: 16, padding: 16, alignItems: "center", opacity: loading ? 0.6 : 1 }}>
            {loading ? <ActivityIndicator color="#fff" /> : <Text style={{ color: "#fff", fontSize: 13, fontWeight: "900", textTransform: "uppercase" }}>Redefinir</Text>}
          </TouchableOpacity>
        </>
      )}
    </View>
  );
}
