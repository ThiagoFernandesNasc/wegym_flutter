import { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, Alert, ActivityIndicator, KeyboardAvoidingView, Platform, ScrollView } from "react-native";
import { router } from "expo-router";
import { login } from "@/api/auth";
import { acceptConsent } from "@/api/privacy";
import { OnboardingModal } from "@/components/Onboarding";

export default function LoginScreen() {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [userType, setUserType] = useState<"atleta" | "personal">("atleta");
  const [step, setStep] = useState(1);

  const [name, setName] = useState("");
  const [cpf, setCpf] = useState("");
  const [cep, setCep] = useState("");
  const [city, setCity] = useState(""); const [state, setState] = useState("");
  const [age, setAge] = useState(""); const [gender, setGender] = useState("");
  const [height, setHeight] = useState(""); const [weight, setWeight] = useState("");
  const [experience, setExperience] = useState("");
  const [cref, setCref] = useState(""); const [crefVerified, setCrefVerified] = useState(false);
  const [injury, setInjury] = useState(""); const [healthIssues, setHealthIssues] = useState("");
  const [medications, setMedications] = useState("");
  const [consentTerms, setConsentTerms] = useState(false);
  const [consentPrivacy, setConsentPrivacy] = useState(false);
  const [consentData, setConsentData] = useState(false);
  const [showOnboarding, setShowOnboarding] = useState(false);

  const handleLogin = async () => {
    if (!email || !password) { Alert.alert("Atenção", "Preencha email e senha"); return; }
    setLoading(true);
    try {
      const user = await login(email, password);
      router.replace(user.role === "personal" ? "/personal" : "/(tabs)/home");
    } catch (err) {
      Alert.alert("Erro", err instanceof Error ? err.message : "Falha ao conectar");
    } finally { setLoading(false); }
  };

  const handleRegister = async () => {
    if (password !== confirmPassword) { Alert.alert("Erro", "Senhas não conferem"); return; }
    if (!consentTerms || !consentPrivacy || !consentData) { Alert.alert("Atenção", "Você precisa aceitar todos os termos de consentimento LGPD"); return; }
    setLoading(true);
    try {
      await fetch(`${process.env.EXPO_PUBLIC_API_URL}/api/auth/register`, {
        method: "POST", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password, userType, name, cpf, cep, city, state, age: Number(age), gender, height: Number(height), weight: Number(weight), experienceLevel: experience, cref: userType === "personal" ? cref : undefined, injury, healthIssues, medications }),
      });
      try { await Promise.all([acceptConsent("terms"), acceptConsent("privacy"), acceptConsent("data")]); } catch {}
      setShowOnboarding(true);
    } catch { Alert.alert("Erro", "Falha ao criar conta"); } finally { setLoading(false); }
  };

  const fetchCep = async () => {
    if (cep.length < 8) return;
    try {
      const r = await fetch(`https://viacep.com.br/ws/${cep}/json/`);
      const d = await r.json();
      if (!d.erro) { setCity(d.localidade); setState(d.uf); }
    } catch { /* silent */ }
  };

  const verifyCref = async () => {
    try {
      const r = await fetch(`${process.env.EXPO_PUBLIC_API_URL}/api/cref/validate`, {
        method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ cref }) });
      if (r.ok) { setCrefVerified(true); Alert.alert("CREF verificado!"); }
      else Alert.alert("Erro", "CREF inválido");
    } catch { Alert.alert("Erro", "Falha ao verificar CREF"); }
  };

  const inputStyle = { backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 10 };

  if (isLogin) {
    return (
      <KeyboardAvoidingView style={{ flex: 1, backgroundColor: "#09090b", justifyContent: "center", padding: 24 }} behavior={Platform.OS === "ios" ? "padding" : "height"}>
        <Text style={{ fontSize: 40, fontWeight: "900", fontStyle: "italic", color: "#fff", textAlign: "center", letterSpacing: -1, marginBottom: 8 }}>WEGYM</Text>
        <Text style={{ fontSize: 13, color: "#a1a1aa", textAlign: "center", marginBottom: 40 }}>Pronto para o treino de hoje?</Text>
        <TextInput placeholder="seu@email.com" placeholderTextColor="#71717a" value={email} onChangeText={setEmail} autoCapitalize="none" keyboardType="email-address" style={inputStyle} />
        <TextInput placeholder="Senha" placeholderTextColor="#71717a" value={password} onChangeText={setPassword} secureTextEntry style={inputStyle} />
        <TouchableOpacity onPress={handleLogin} disabled={loading} style={{ backgroundColor: "#ea580c", borderRadius: 16, padding: 16, alignItems: "center", opacity: loading ? 0.6 : 1, marginBottom: 12 }}>
          {loading ? <ActivityIndicator color="#fff" /> : <Text style={{ color: "#fff", fontSize: 13, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase", letterSpacing: 1 }}>Entrar</Text>}
        </TouchableOpacity>
        <TouchableOpacity onPress={() => setIsLogin(false)} style={{ alignItems: "center", marginTop: 8 }}>
          <Text style={{ color: "#ea580c", fontSize: 12, fontWeight: "700" }}>Criar conta</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={() => router.push("/reset-password")} style={{ alignItems: "center", marginTop: 4 }}>
          <Text style={{ color: "#71717a", fontSize: 11, fontWeight: "600" }}>Esqueceu a senha?</Text>
        </TouchableOpacity>
      </KeyboardAvoidingView>
    );
  }

  return (
    <KeyboardAvoidingView style={{ flex: 1, backgroundColor: "#09090b" }} behavior={Platform.OS === "ios" ? "padding" : "height"}>
      <ScrollView contentContainerStyle={{ padding: 24 }}>
        <Text style={{ fontSize: 28, fontWeight: "900", fontStyle: "italic", color: "#fff", textAlign: "center", marginBottom: 20 }}>Criar conta</Text>

        <View style={{ flexDirection: "row", gap: 8, marginBottom: 20 }}>
          <TouchableOpacity onPress={() => { setUserType("atleta"); setStep(1); }} style={{ flex: 1, padding: 12, borderRadius: 12, backgroundColor: userType === "atleta" ? "#ea580c" : "#18181b", alignItems: "center" }}>
            <Text style={{ fontSize: 11, fontWeight: "800", textTransform: "uppercase", color: userType === "atleta" ? "#fff" : "#71717a" }}>Atleta</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => { setUserType("personal"); setStep(1); }} style={{ flex: 1, padding: 12, borderRadius: 12, backgroundColor: userType === "personal" ? "#ea580c" : "#18181b", alignItems: "center" }}>
            <Text style={{ fontSize: 11, fontWeight: "800", textTransform: "uppercase", color: userType === "personal" ? "#fff" : "#71717a" }}>Personal</Text>
          </TouchableOpacity>
        </View>

        {userType === "personal" && !crefVerified && (
          <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
            <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 8 }}>Verificar CREF</Text>
            <TextInput value={cref} onChangeText={setCref} placeholder="Número CREF" placeholderTextColor="#71717a" autoCapitalize="characters" style={inputStyle} />
            <TouchableOpacity onPress={verifyCref} style={{ backgroundColor: "#ea580c", borderRadius: 12, padding: 12, alignItems: "center" }}>
              <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Verificar</Text>
            </TouchableOpacity>
          </View>
        )}

        {(userType === "atleta" || crefVerified) && (
          <>
            {step === 1 && (
              <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Dados pessoais</Text>
                <TextInput value={name} onChangeText={setName} placeholder="Nome completo" placeholderTextColor="#71717a" style={inputStyle} />
                <TextInput value={cpf} onChangeText={setCpf} placeholder="CPF" placeholderTextColor="#71717a" style={inputStyle} />
                <TextInput value={email} onChangeText={setEmail} placeholder="Email" placeholderTextColor="#71717a" autoCapitalize="none" keyboardType="email-address" style={inputStyle} />
                <TextInput value={cep} onChangeText={setCep} onBlur={fetchCep} placeholder="CEP" placeholderTextColor="#71717a" keyboardType="numeric" style={inputStyle} />
                <TextInput value={city} onChangeText={setCity} placeholder="Cidade" placeholderTextColor="#71717a" style={inputStyle} />
                <TextInput value={state} onChangeText={setState} placeholder="Estado" placeholderTextColor="#71717a" style={inputStyle} />
                <TouchableOpacity onPress={() => setStep(2)} style={{ backgroundColor: "#ea580c", borderRadius: 12, padding: 12, alignItems: "center" }}>
                  <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Próximo</Text>
                </TouchableOpacity>
              </View>
            )}

            {step === 2 && (
              <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Dados físicos</Text>
                <TextInput value={age} onChangeText={setAge} placeholder="Idade" placeholderTextColor="#71717a" keyboardType="numeric" style={inputStyle} />
                <TextInput value={height} onChangeText={setHeight} placeholder="Altura (cm)" placeholderTextColor="#71717a" keyboardType="numeric" style={inputStyle} />
                <TextInput value={weight} onChangeText={setWeight} placeholder="Peso (kg)" placeholderTextColor="#71717a" keyboardType="numeric" style={inputStyle} />
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 8, marginTop: 4 }}>Nível</Text>
                <View style={{ flexDirection: "row", gap: 6, marginBottom: 12 }}>
                  {["iniciante", "intermediario", "avancado"].map((l) => (
                    <TouchableOpacity key={l} onPress={() => setExperience(l)} style={{ flex: 1, padding: 10, borderRadius: 10, backgroundColor: experience === l ? "#ea580c" : "#27272a", alignItems: "center" }}>
                      <Text style={{ fontSize: 10, fontWeight: "800", textTransform: "uppercase", color: experience === l ? "#fff" : "#71717a" }}>{l}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
                <View style={{ flexDirection: "row", gap: 8 }}>
                  <TouchableOpacity onPress={() => setStep(1)} style={{ flex: 1, backgroundColor: "#27272a", borderRadius: 12, padding: 12, alignItems: "center" }}>
                    <Text style={{ color: "#71717a", fontSize: 11, fontWeight: "800" }}>Voltar</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={() => setStep(3)} style={{ flex: 1, backgroundColor: "#ea580c", borderRadius: 12, padding: 12, alignItems: "center" }}>
                    <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Próximo</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}

            {step === 3 && (
              <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Saúde</Text>
                <TextInput value={injury} onChangeText={setInjury} placeholder="Lesões" placeholderTextColor="#71717a" multiline style={{ ...inputStyle, minHeight: 60 }} />
                <TextInput value={healthIssues} onChangeText={setHealthIssues} placeholder="Problemas de saúde" placeholderTextColor="#71717a" multiline style={{ ...inputStyle, minHeight: 60 }} />
                <TextInput value={medications} onChangeText={setMedications} placeholder="Medicamentos" placeholderTextColor="#71717a" style={inputStyle} />
                <View style={{ flexDirection: "row", gap: 8 }}>
                  <TouchableOpacity onPress={() => setStep(2)} style={{ flex: 1, backgroundColor: "#27272a", borderRadius: 12, padding: 12, alignItems: "center" }}>
                    <Text style={{ color: "#71717a", fontSize: 11, fontWeight: "800" }}>Voltar</Text>
                  </TouchableOpacity>
                  <TouchableOpacity onPress={() => setStep(4)} style={{ flex: 1, backgroundColor: "#ea580c", borderRadius: 12, padding: 12, alignItems: "center" }}>
                    <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Próximo</Text>
                  </TouchableOpacity>
                </View>
              </View>
            )}

            {step === 4 && (
              <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Segurança</Text>
                <TextInput value={password} onChangeText={setPassword} placeholder="Senha" placeholderTextColor="#71717a" secureTextEntry style={inputStyle} />
                <TextInput value={confirmPassword} onChangeText={setConfirmPassword} placeholder="Confirmar senha" placeholderTextColor="#71717a" secureTextEntry style={inputStyle} />

                <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginTop: 12, marginBottom: 10 }}>Consentimento LGPD</Text>
                {[
                  { key: "terms", label: "Aceito os Termos de Uso", state: consentTerms, set: setConsentTerms },
                  { key: "privacy", label: "Aceito a Política de Privacidade", state: consentPrivacy, set: setConsentPrivacy },
                  { key: "data", label: "Autorizo o tratamento dos meus dados pessoais", state: consentData, set: setConsentData },
                ].map((c) => (
                  <TouchableOpacity key={c.key} onPress={() => c.set(!c.state)}
                    style={{ flexDirection: "row", alignItems: "center", gap: 8, paddingVertical: 6 }}>
                    <View style={{ width: 18, height: 18, borderRadius: 4, borderWidth: 2, borderColor: c.state ? "#ea580c" : "#3f3f46", backgroundColor: c.state ? "#ea580c" : "transparent", justifyContent: "center", alignItems: "center" }}>
                      {c.state && <Text style={{ color: "#fff", fontSize: 10 }}>✓</Text>}
                    </View>
                    <Text style={{ color: c.state ? "#fff" : "#a1a1aa", fontSize: 11, flex: 1 }}>{c.label}</Text>
                  </TouchableOpacity>
                ))}

                <TouchableOpacity onPress={handleRegister} disabled={loading} style={{ backgroundColor: "#ea580c", borderRadius: 12, padding: 14, alignItems: "center", opacity: loading ? 0.6 : 1, marginTop: 8 }}>
                  {loading ? <ActivityIndicator color="#fff" /> : <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>Criar conta</Text>}
                </TouchableOpacity>
              </View>
            )}
          </>
        )}

        <TouchableOpacity onPress={() => setIsLogin(true)} style={{ alignItems: "center", marginTop: 8, marginBottom: 40 }}>
          <Text style={{ color: "#ea580c", fontSize: 12, fontWeight: "700" }}>Já tem conta? Faça login</Text>
        </TouchableOpacity>
      </ScrollView>
      {showOnboarding && (
        <OnboardingModal role={userType} onComplete={() => router.replace(userType === "personal" ? "/personal" : "/(tabs)/home")} />
      )}
    </KeyboardAvoidingView>
  );
}
