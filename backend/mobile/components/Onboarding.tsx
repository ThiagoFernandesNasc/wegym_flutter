import { useState, useEffect } from "react";
import { View, Text, TouchableOpacity, Modal, Dimensions } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";

const STORAGE_KEY = "wegym_tutorial_completed";

const ATHLETE_STEPS = [
  { icon: "🏋️", title: "Bem-vindo ao WEGYM", desc: "Sua plataforma inteligente de treinos. Academia, corrida, ciclismo, natação e muito mais." },
  { icon: "💪", title: "Treinos Inteligentes", desc: "Escolha entre várias modalidades, siga planos semanais e registre cada sessão." },
  { icon: "⚡", title: "IA & GPS", desc: "Use o assistente IA para gerar treinos personalizados. Ative GPS para corridas ao ar livre." },
  { icon: "📊", title: "Estatísticas", desc: "Acompanhe seu progresso com gráficos de volume, frequência cardíaca e calorias." },
  { icon: "👤", title: "Perfil & PRO", desc: "Conecte smartwatches via Bluetooth e desbloqueie recursos premium com WEGYM PRO." },
];

const PERSONAL_STEPS = [
  { icon: "👨‍🏫", title: "Dashboard Personal", desc: "Gerencie alunos, planos de treino e horários em um só lugar." },
  { icon: "👥", title: "Gerenciar Alunos", desc: "Cadastre novos alunos, visualize perfis e acompanhe o progresso individual." },
  { icon: "🤖", title: "Planos & IA", desc: "Crie planos de treino personalizados. Use o Copilot IA para gerar fichas automaticamente." },
  { icon: "📈", title: "Evolução", desc: "Registre medidas, peso e observações para acompanhar o progresso dos seus alunos." },
];

export function OnboardingModal({ role, onComplete }: { role: "atleta" | "personal"; onComplete: () => void }) {
  const [step, setStep] = useState(0);
  const steps = role === "personal" ? PERSONAL_STEPS : ATHLETE_STEPS;

  const handleComplete = async () => {
    await AsyncStorage.setItem(STORAGE_KEY, "true");
    onComplete();
  };

  const s = steps[step];

  return (
    <Modal visible transparent animationType="fade">
      <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.9)", justifyContent: "center", padding: 32 }}>
        <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 32, padding: 32, alignItems: "center" }}>
          <Text style={{ fontSize: 56, marginBottom: 16 }}>{s.icon}</Text>
          <Text style={{ fontSize: 22, fontWeight: "900", fontStyle: "italic", color: "#fff", textAlign: "center", marginBottom: 8 }}>{s.title}</Text>
          <Text style={{ fontSize: 13, color: "#a1a1aa", textAlign: "center", lineHeight: 20, marginBottom: 24 }}>{s.desc}</Text>

          <View style={{ flexDirection: "row", gap: 6, marginBottom: 24 }}>
            {steps.map((_, i) => (
              <View key={i} style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: i === step ? "#ea580c" : "#27272a" }} />
            ))}
          </View>

          <View style={{ flexDirection: "row", gap: 12, width: "100%" }}>
            <TouchableOpacity onPress={handleComplete} style={{ flex: 1, backgroundColor: "#27272a", borderRadius: 14, padding: 14, alignItems: "center" }}>
              <Text style={{ color: "#71717a", fontSize: 12, fontWeight: "800" }}>Pular</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={() => step < steps.length - 1 ? setStep(step + 1) : handleComplete()} style={{ flex: 1, backgroundColor: "#ea580c", borderRadius: 14, padding: 14, alignItems: "center" }}>
              <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>{step < steps.length - 1 ? "Próximo" : "Começar"}</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}

export function useOnboarding(role: "atleta" | "personal") {
  const [show, setShow] = useState(false);
  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((val) => { if (!val) setTimeout(() => setShow(true), 500); });
  }, []);
  return {
    show,
    dismiss: () => setShow(false),
    Onboarding: show ? <OnboardingModal role={role} onComplete={() => setShow(false)} /> : null,
  };
}
