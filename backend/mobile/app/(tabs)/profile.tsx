import { useEffect, useState } from "react";
import { View, Text, ActivityIndicator, ScrollView, TouchableOpacity, Alert, Switch, TextInput, Image } from "react-native";
import { router } from "expo-router";
import { getProfile, logout } from "@/api/auth";
import { api } from "@/api/client";
import { exportUserData, requestDataDeletion } from "@/api/privacy";
import { getMySubscription, type Subscription } from "@/api/subscriptions";
import { updateProfile } from "@/api/profile";
import { registerForPushNotifications, scheduleWorkoutReminder, cancelAllNotifications } from "@/services/notifications";
import * as ImagePicker from "expo-image-picker";

type Profile = {
  id: string;
  email: string;
  role: "atleta" | "personal";
  createdAt?: string;
  athlete?: {
    name: string;
    weightKg: number;
    heightCm: number;
    experienceLevel: string;
    city?: string;
    state?: string;
  };
  personal?: {
    name: string;
    cref: string;
  };
};

export default function ProfileScreen() {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [subscription, setSubscription] = useState<Subscription | null>(null);
  const [loading, setLoading] = useState(true);
  const [reminders, setReminders] = useState(false);

  // Edit state
  const [editing, setEditing] = useState(false);
  const [editWeight, setEditWeight] = useState("");
  const [editHeight, setEditHeight] = useState("");
  const [editExperience, setEditExperience] = useState("");
  const [editGoal, setEditGoal] = useState("");
  const [editName, setEditName] = useState("");
  const [editEmail, setEditEmail] = useState("");

  const [deleteConfirm, setDeleteConfirm] = useState("");
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);

  const handlePickAvatar = async () => {
    const { status } = await ImagePicker.requestMediaLibraryPermissionsAsync();
    if (status !== "granted") { Alert.alert("Permissão necessária", "Precisamos de acesso à sua galeria para alterar a foto."); return; }
    const result = await ImagePicker.launchImageLibraryAsync({ mediaTypes: ImagePicker.MediaTypeOptions.Images, allowsEditing: true, aspect: [1, 1], quality: 0.8 });
    if (!result.canceled) {
      const uri = result.assets[0].uri;
      setAvatarUrl(uri);
      try {
        const formData = new FormData();
        formData.append("avatar", { uri, type: "image/jpeg", name: "avatar.jpg" } as unknown as Blob);
        await api.patch("/api/user/profile", { avatarUrl: uri });
        Alert.alert("Foto atualizada", "Sua foto de perfil foi alterada.");
      } catch { Alert.alert("Erro", "Não foi possível salvar a foto"); }
    }
  };

  const inputStyle = { backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 10, fontSize: 13, color: "#fff", textAlign: "center" as const };

  useEffect(() => { loadProfile(); }, []);

  const loadProfile = async () => {
    try {
      const [data, sub] = await Promise.all([
        getProfile().catch(() => null),
        getMySubscription().catch(() => null),
      ]);
      setProfile(data as unknown as Profile);
      setSubscription(sub);
    } catch {} finally { setLoading(false); }
  };

  const startEditing = () => {
    if (!profile?.athlete) return;
    setEditWeight(String(profile.athlete.weightKg));
    setEditHeight(String(profile.athlete.heightCm));
    setEditExperience(profile.athlete.experienceLevel);
    setEditName(profile.athlete.name);
    setEditEmail(profile.email);
    setEditing(true);
  };

  const saveEditing = async () => {
    try {
      await updateProfile({
        name: editName !== profile?.athlete?.name ? editName : undefined,
        email: editEmail !== profile?.email ? editEmail : undefined,
        weightKg: Number(editWeight), heightCm: Number(editHeight),
        experienceLevel: editExperience, goal: editGoal || undefined,
      });
      setEditing(false);
      loadProfile();
    } catch { Alert.alert("Erro", "Não foi possível salvar"); }
  };

  const toggleReminders = async (val: boolean) => {
    setReminders(val);
    if (val) {
      await registerForPushNotifications();
      await scheduleWorkoutReminder(7, 0);
      Alert.alert("Lembrete ativado", "Você receberá uma notificação todos os dias às 7h");
    } else { await cancelAllNotifications(); }
  };

  const handleExport = async () => {
    try {
      const res = await exportUserData();
      Alert.alert("Dados exportados", "Seus dados serão enviados para seu email em instantes.");
    } catch { Alert.alert("Erro", "Falha ao exportar dados"); }
  };

  const handleDeleteData = () => {
    if (deleteConfirm === "EXCLUIR") {
      Alert.alert("Excluir dados", "Confirmação final?", [
        { text: "Cancelar", style: "cancel" },
        { text: "EXCLUIR", style: "destructive", onPress: async () => {
          try { await requestDataDeletion(); Alert.alert("Solicitação enviada", "Seus dados serão excluídos em até 30 dias."); setDeleteConfirm(""); } catch { Alert.alert("Erro", "Falha ao solicitar exclusão"); }
        }},
      ]);
    } else {
      Alert.alert("Confirmação", "Digite EXCLUIR no campo abaixo e toque no botão novamente.");
    }
  };

  const handleLogout = () => {
    Alert.alert("Sair", "Tem certeza que deseja sair?", [
      { text: "Cancelar", style: "cancel" },
      { text: "Sair", style: "destructive", onPress: async () => { await logout(); router.replace("/login"); }},
    ]);
  };

  if (loading) {
    return <View style={{ flex: 1, backgroundColor: "#09090b", justifyContent: "center", alignItems: "center" }}><ActivityIndicator size="large" color="#ea580c" /></View>;
  }

  const name = profile?.athlete?.name ?? profile?.personal?.name ?? "Usuário";
  const isAtleta = profile?.role === "atleta";
  const EXP_LEVELS = ["iniciante", "intermediario", "avancado"];
  const GOALS = ["emagrecer", "hipertrofia", "definicao", "condicionamento", "forca"];
  const isPro = subscription?.status === "active" || subscription?.status === "trial";

  return (
    <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }} contentContainerStyle={{ padding: 24, paddingTop: 60 }}>
      <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", letterSpacing: -0.5, marginBottom: 24 }}>
        Perfil
      </Text>

      {/* Identity Card */}
      <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 24, marginBottom: 16, alignItems: "center" }}>
        <TouchableOpacity onPress={handlePickAvatar} style={{ width: 80, height: 80, borderRadius: 20, backgroundColor: "#27272a", justifyContent: "center", alignItems: "center", marginBottom: 12, overflow: "hidden" }}>
          {avatarUrl ? (
            <Image source={{ uri: avatarUrl }} style={{ width: 80, height: 80 }} />
          ) : (
            <Text style={{ fontSize: 32, fontWeight: "900", color: "#ea580c" }}>
              {name.charAt(0).toUpperCase()}
            </Text>
          )}
        </TouchableOpacity>

        {editing ? (
          <View style={{ width: "100%", gap: 8, alignItems: "center" }}>
            <TextInput value={editName} onChangeText={setEditName} placeholderTextColor="#71717a" style={{ ...inputStyle, width: "80%", textAlign: "center" }} />
            <TextInput value={editEmail} onChangeText={setEditEmail} placeholderTextColor="#71717a" autoCapitalize="none" keyboardType="email-address" style={{ ...inputStyle, width: "80%", textAlign: "center" }} />
          </View>
        ) : (
          <>
            <Text style={{ fontSize: 20, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{name}</Text>
            <Text style={{ fontSize: 12, color: "#a1a1aa", marginTop: 4 }}>{profile?.email}</Text>
          </>
        )}

        {isAtleta && profile?.athlete?.city && (
          <Text style={{ fontSize: 10, color: "#71717a", marginTop: 2 }}>{profile.athlete.city}{profile.athlete.state ? `, ${profile.athlete.state}` : ""}</Text>
        )}

        <View style={{ flexDirection: "row", gap: 8, marginTop: 12, flexWrap: "wrap", justifyContent: "center" }}>
          <View style={{ backgroundColor: "#ea580c20", borderRadius: 20, paddingHorizontal: 12, paddingVertical: 4 }}>
            <Text style={{ fontSize: 10, fontWeight: "800", textTransform: "uppercase", color: "#ea580c" }}>
              {isAtleta ? "Atleta" : "Personal"}
            </Text>
          </View>
          {profile?.createdAt && (
            <View style={{ backgroundColor: "#27272a", borderRadius: 20, paddingHorizontal: 12, paddingVertical: 4 }}>
              <Text style={{ fontSize: 9, fontWeight: "700", color: "#71717a" }}>
                🗓️ {new Date(profile.createdAt).toLocaleDateString("pt-BR", { month: "short", year: "numeric" })}
              </Text>
            </View>
          )}
          {/* Plan status badge */}
          <View style={{ backgroundColor: isPro ? "#22c55e20" : "#27272a", borderRadius: 20, paddingHorizontal: 12, paddingVertical: 4 }}>
            <Text style={{ fontSize: 9, fontWeight: "800", textTransform: "uppercase", color: isPro ? "#22c55e" : "#71717a" }}>
              {isPro ? "WEGYM PRO" : "Free"}
            </Text>
          </View>
          {/* CREF badge for personal */}
          {!isAtleta && profile?.personal?.cref && (
            <View style={{ backgroundColor: "#3b82f620", borderRadius: 20, paddingHorizontal: 12, paddingVertical: 4 }}>
              <Text style={{ fontSize: 9, fontWeight: "800", textTransform: "uppercase", color: "#3b82f6" }}>
                CREF {profile.personal.cref}
              </Text>
            </View>
          )}
        </View>
      </View>

      {/* Personal Dashboard Link */}
      {!isAtleta && (
        <TouchableOpacity onPress={() => router.push("/personal")} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 16, flexDirection: "row", alignItems: "center", gap: 12 }}>
          <Text style={{ fontSize: 24 }}>👨‍🏫</Text>
          <View style={{ flex: 1 }}>
            <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Dashboard Personal</Text>
            <Text style={{ fontSize: 10, color: "#71717a" }}>Gerencie alunos, planos e evolução</Text>
          </View>
          <Text style={{ color: "#ea580c", fontSize: 16 }}>›</Text>
        </TouchableOpacity>
      )}

      {/* PRO upgrade prompt (if free) */}
      {!isPro && (
        <TouchableOpacity onPress={() => router.push("/pro")} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#ea580c40", borderRadius: 24, padding: 20, marginBottom: 16, flexDirection: "row", alignItems: "center", gap: 12 }}>
          <Text style={{ fontSize: 24 }}>👑</Text>
          <View style={{ flex: 1 }}>
            <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#ea580c" }}>WEGYM PRO</Text>
            <Text style={{ fontSize: 10, color: "#71717a" }}>Desbloqueie recursos premium</Text>
          </View>
          <Text style={{ color: "#ea580c", fontSize: 16 }}>›</Text>
        </TouchableOpacity>
      )}

      {/* Physical Data */}
      {isAtleta && profile?.athlete && (
        <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 16 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
            <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1.5, color: "#71717a" }}>
              Dados físicos
            </Text>
            <TouchableOpacity onPress={editing ? saveEditing : startEditing}>
              <Text style={{ color: editing ? "#22c55e" : "#ea580c", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>
                {editing ? "Salvar" : "Editar"}
              </Text>
            </TouchableOpacity>
          </View>
          {editing ? (
            <View>
              {editing && (
                <View style={{ marginBottom: 12 }}>
                  <Text style={{ fontSize: 9, color: "#71717a", marginBottom: 4, textTransform: "uppercase" }}>Nome</Text>
                  <TextInput value={editName} onChangeText={setEditName} style={inputStyle} />
                  <Text style={{ fontSize: 9, color: "#71717a", marginBottom: 4, textTransform: "uppercase", marginTop: 8 }}>Email</Text>
                  <TextInput value={editEmail} onChangeText={setEditEmail} autoCapitalize="none" keyboardType="email-address" style={inputStyle} />
                </View>
              )}
              <View style={{ flexDirection: "row", gap: 10, marginBottom: 12 }}>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 9, color: "#71717a", marginBottom: 4, textTransform: "uppercase" }}>Peso (kg)</Text>
                  <TextInput value={editWeight} onChangeText={setEditWeight} keyboardType="numeric" style={inputStyle} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 9, color: "#71717a", marginBottom: 4, textTransform: "uppercase" }}>Altura (cm)</Text>
                  <TextInput value={editHeight} onChangeText={setEditHeight} keyboardType="numeric" style={inputStyle} />
                </View>
              </View>
              <Text style={{ fontSize: 9, color: "#71717a", marginBottom: 6, textTransform: "uppercase" }}>Nível</Text>
              <View style={{ flexDirection: "row", gap: 6, marginBottom: 12 }}>
                {EXP_LEVELS.map((l) => (
                  <TouchableOpacity key={l} onPress={() => setEditExperience(l)}
                    style={{ flex: 1, padding: 8, borderRadius: 8, backgroundColor: editExperience === l ? "#ea580c" : "#27272a", alignItems: "center" }}>
                    <Text style={{ fontSize: 9, fontWeight: "800", color: editExperience === l ? "#fff" : "#71717a" }}>{l}</Text>
                  </TouchableOpacity>
                ))}
              </View>
              <Text style={{ fontSize: 9, color: "#71717a", marginBottom: 6, textTransform: "uppercase" }}>Objetivo</Text>
              <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6, marginBottom: 12 }}>
                {GOALS.map((g) => (
                  <TouchableOpacity key={g} onPress={() => setEditGoal(g)}
                    style={{ paddingHorizontal: 14, paddingVertical: 6, borderRadius: 20, backgroundColor: editGoal === g ? "#ea580c" : "#27272a" }}>
                    <Text style={{ fontSize: 9, fontWeight: "800", color: editGoal === g ? "#fff" : "#71717a" }}>{g}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          ) : (
            <View>
              <View style={{ flexDirection: "row", justifyContent: "space-around" }}>
                <View style={{ alignItems: "center" }}>
                  <Text style={{ fontSize: 10, color: "#71717a", fontWeight: "700", textTransform: "uppercase" }}>Peso</Text>
                  <Text style={{ fontSize: 22, fontWeight: "900", fontStyle: "italic", color: "#fff", marginTop: 4 }}>
                    {profile.athlete.weightKg} kg
                  </Text>
                </View>
                <View style={{ alignItems: "center" }}>
                  <Text style={{ fontSize: 10, color: "#71717a", fontWeight: "700", textTransform: "uppercase" }}>Altura</Text>
                  <Text style={{ fontSize: 22, fontWeight: "900", fontStyle: "italic", color: "#fff", marginTop: 4 }}>
                    {profile.athlete.heightCm} cm
                  </Text>
                </View>
                <View style={{ alignItems: "center" }}>
                  <Text style={{ fontSize: 10, color: "#71717a", fontWeight: "700", textTransform: "uppercase" }}>Nível</Text>
                  <Text style={{ fontSize: 14, fontWeight: "900", fontStyle: "italic", color: "#ea580c", marginTop: 4 }}>
                    {profile.athlete.experienceLevel}
                  </Text>
                </View>
              </View>
              {(() => {
                const w = profile.athlete.weightKg;
                const h = profile.athlete.heightCm / 100;
                const imc = h > 0 ? w / (h * h) : 0;
                const category = imc < 18.5 ? "Abaixo do peso" : imc < 25 ? "Normal" : imc < 30 ? "Sobrepeso" : "Obesidade";
                const catColor = imc < 18.5 ? "#facc15" : imc < 25 ? "#22c55e" : imc < 30 ? "#ea580c" : "#dc2626";
                return (
                  <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, marginTop: 10 }}>
                    <View style={{ backgroundColor: catColor + "20", borderRadius: 20, paddingHorizontal: 12, paddingVertical: 4 }}>
                      <Text style={{ fontSize: 10, fontWeight: "800", color: catColor }}>IMC {imc.toFixed(1)}</Text>
                    </View>
                    <Text style={{ fontSize: 9, fontWeight: "700", color: catColor }}>{category}</Text>
                  </View>
                );
              })()}
            </View>
          )}
        </View>
      )}

      {/* Resources */}
      <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 16 }}>
        <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1.5, color: "#71717a", marginBottom: 12 }}>
          Recursos
        </Text>
        {[
          { href: "/goals", icon: "🎯", label: "Metas", desc: "Objetivos SMART" },
          { href: "/checkin", icon: "📋", label: "Check-in", desc: "Registro diário" },
          { href: "/feed", icon: "💬", label: "Feed", desc: "Compartilhe treinos" },
          { href: "/chat", icon: "✉️", label: "Chat", desc: "Fale com personal" },
          { href: "/programs", icon: "📖", label: "Programas", desc: "Treinos pré-montados" },
          { href: "/nutrition", icon: "🍎", label: "Nutrição", desc: "Diário alimentar" },
          { href: "/achievements", icon: "🏆", label: "Conquistas", desc: "Badges e medalhas" },
          { href: "/challenges", icon: "⚔️", label: "Desafios", desc: "Compita com amigos" },
          { href: "/appointments", icon: "📅", label: "Agenda", desc: "Agende sessões" },
          { href: "/measurements", icon: "📈", label: "Evolução", desc: "Gráficos de progresso" },
        ].map((r) => (
          <TouchableOpacity key={r.href} onPress={() => router.push(r.href)} style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
              <Text style={{ fontSize: 18 }}>{r.icon}</Text>
              <View>
                <Text style={{ fontSize: 13, fontWeight: "700", color: "#fff" }}>{r.label}</Text>
                <Text style={{ fontSize: 10, color: "#71717a" }}>{r.desc}</Text>
              </View>
            </View>
            <Text style={{ color: "#ea580c", fontSize: 16 }}>›</Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Devices & Smartwatch */}
      <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 16 }}>
        <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1.5, color: "#71717a", marginBottom: 12 }}>
          Dispositivos e Smartwatch
        </Text>
        <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 12 }}>
          {["⌚ Apple Watch", "❤️ Google Fit", "⌚ Garmin", "⌚ Polar", "📡 HR Band"].map((d) => (
            <View key={d} style={{ backgroundColor: "#09090b", borderRadius: 20, paddingHorizontal: 12, paddingVertical: 6, borderWidth: 1, borderColor: "#27272a" }}>
              <Text style={{ color: "#52525b", fontSize: 9, fontWeight: "700" }}>{d}</Text>
            </View>
          ))}
        </View>
        <TouchableOpacity onPress={() => router.push("/ble")} style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 8 }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <Text style={{ fontSize: 18 }}>❤️</Text>
            <View><Text style={{ fontSize: 13, fontWeight: "700", color: "#fff" }}>Monitor Cardíaco</Text><Text style={{ fontSize: 10, color: "#71717a" }}>Conectar via Bluetooth</Text></View>
          </View>
          <Text style={{ color: "#ea580c", fontSize: 16 }}>›</Text>
        </TouchableOpacity>
      </View>

      {/* Privacy (LGPD) */}
      <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 16 }}>
        <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1.5, color: "#71717a", marginBottom: 12 }}>
          Privacidade (LGPD)
        </Text>
        <TouchableOpacity onPress={() => router.push("/privacy")} style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <Text style={{ fontSize: 18 }}>📜</Text>
            <View><Text style={{ fontSize: 13, fontWeight: "700", color: "#fff" }}>Política de Privacidade</Text><Text style={{ fontSize: 10, color: "#71717a" }}>Termos e condições</Text></View>
          </View>
          <Text style={{ color: "#ea580c", fontSize: 16 }}>›</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={handleExport} style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 10, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <Text style={{ fontSize: 18 }}>📤</Text>
            <View><Text style={{ fontSize: 13, fontWeight: "700", color: "#fff" }}>Exportar dados</Text><Text style={{ fontSize: 10, color: "#71717a" }}>Receba seus dados por email</Text></View>
          </View>
          <Text style={{ color: "#ea580c", fontSize: 16 }}>›</Text>
        </TouchableOpacity>
        <TextInput value={deleteConfirm} onChangeText={setDeleteConfirm} placeholder='Digite EXCLUIR para confirmar' placeholderTextColor="#52525b" style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#dc262620", borderRadius: 10, padding: 10, fontSize: 11, color: "#dc2626", textAlign: "center", marginBottom: 8 }} />
        <TouchableOpacity onPress={handleDeleteData} style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 10 }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <Text style={{ fontSize: 18 }}>🗑️</Text>
            <View><Text style={{ fontSize: 13, fontWeight: "700", color: deleteConfirm === "EXCLUIR" ? "#dc2626" : "#71717a" }}>Excluir dados</Text><Text style={{ fontSize: 10, color: "#71717a" }}>Solicitar remoção completa</Text></View>
          </View>
          <Text style={{ color: deleteConfirm === "EXCLUIR" ? "#dc2626" : "#71717a", fontSize: 16 }}>›</Text>
        </TouchableOpacity>
      </View>

      {/* Settings */}
      <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 24, padding: 20, marginBottom: 16 }}>
        <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1.5, color: "#71717a", marginBottom: 12 }}>
          Configurações
        </Text>
        <TouchableOpacity onPress={() => router.push("/integrations")} style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <Text style={{ fontSize: 20 }}>🔗</Text>
            <View><Text style={{ fontSize: 13, fontWeight: "700", color: "#fff" }}>Integrações</Text><Text style={{ fontSize: 10, color: "#71717a" }}>Strava, Google Fit, Health</Text></View>
          </View>
          <Text style={{ color: "#ea580c", fontSize: 16 }}>›</Text>
        </TouchableOpacity>
        <TouchableOpacity onPress={() => router.push("/pro")} style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <Text style={{ fontSize: 20 }}>👑</Text>
            <View><Text style={{ fontSize: 13, fontWeight: "700", color: "#fff" }}>WEGYM PRO</Text><Text style={{ fontSize: 10, color: "#71717a" }}>Desbloqueie recursos premium</Text></View>
          </View>
          <Text style={{ color: "#ea580c", fontSize: 16 }}>›</Text>
        </TouchableOpacity>
        <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <Text style={{ fontSize: 20 }}>🔔</Text>
            <View>
              <Text style={{ fontSize: 13, fontWeight: "700", color: "#fff" }}>Lembrete diário</Text>
              <Text style={{ fontSize: 10, color: "#71717a" }}>Notificação às 7h</Text>
            </View>
          </View>
          <Switch value={reminders} onValueChange={toggleReminders} trackColor={{ false: "#27272a", true: "#ea580c60" }} thumbColor={reminders ? "#ea580c" : "#71717a"} />
        </View>
      </View>

      <TouchableOpacity onPress={handleLogout} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#dc262620", borderRadius: 16, padding: 16, alignItems: "center", marginTop: 8 }}>
        <Text style={{ color: "#dc2626", fontSize: 13, fontWeight: "800" }}>Sair da conta</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}
