import { useEffect, useState, useCallback } from "react";
import { View, Text, TouchableOpacity, ScrollView, ActivityIndicator, RefreshControl, TextInput, Alert } from "react-native";
import { router } from "expo-router";
import { getFriends, sendFriendRequest, respondToFriend, type Friend } from "@/api/friends";

export default function FriendsScreen() {
  const [friends, setFriends] = useState<Friend[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [addEmail, setAddEmail] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const [pendingRequests, setPendingRequests] = useState<Friend[]>([]);

  const loadFriends = useCallback(async () => {
    try {
      const res = await getFriends();
      setFriends(res);
    } catch { /* silent */ } finally { setLoading(false); setRefreshing(false); }
  }, []);

  useEffect(() => { loadFriends(); }, [loadFriends]);

  const handleAddFriend = async () => {
    if (!addEmail.trim()) return;
    try {
      await sendFriendRequest(addEmail.trim());
      Alert.alert("Solicitação enviada", `Solicitação de amizade enviada para ${addEmail.trim()}`);
      setAddEmail("");
      setShowAdd(false);
    } catch { Alert.alert("Erro", "Não foi possível enviar solicitação"); }
  };

  const handleRespond = async (userId: string, accept: boolean) => {
    await respondToFriend(userId, accept);
    loadFriends();
  };

  return (
    <View style={{ flex: 1, backgroundColor: "#09090b" }}>
      <ScrollView contentContainerStyle={{ padding: 20, paddingTop: 60 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={() => { setRefreshing(true); loadFriends(); }} tintColor="#ea580c" />}>
        <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
          <TouchableOpacity onPress={() => router.back()}>
            <Text style={{ color: "#ea580c", fontSize: 14, fontWeight: "800" }}>{"< Voltar"}</Text>
          </TouchableOpacity>
          <TouchableOpacity onPress={() => setShowAdd(!showAdd)} style={{ backgroundColor: "#ea580c", borderRadius: 12, paddingHorizontal: 14, paddingVertical: 8 }}>
            <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>+ Adicionar</Text>
          </TouchableOpacity>
        </View>
        <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 4 }}>Amigos</Text>
        <Text style={{ fontSize: 12, color: "#a1a1aa", marginBottom: 20 }}>Conecte-se com outros atletas</Text>

        {showAdd && (
          <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
            <Text style={{ fontSize: 11, fontWeight: "900", color: "#fff", marginBottom: 10 }}>Adicionar por email</Text>
            <TextInput value={addEmail} onChangeText={setAddEmail} placeholder="Email do amigo" placeholderTextColor="#71717a" autoCapitalize="none" keyboardType="email-address" style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 12 }} />
            <TouchableOpacity onPress={handleAddFriend} disabled={!addEmail.trim()} style={{ backgroundColor: addEmail.trim() ? "#ea580c" : "#27272a", borderRadius: 14, padding: 12, alignItems: "center" }}>
              <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Enviar convite</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Pending requests */}
        {pendingRequests.length > 0 && (
          <View style={{ marginBottom: 16 }}>
            <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#ea580c", marginBottom: 8 }}>Solicitações pendentes</Text>
            {pendingRequests.map((f) => (
              <View key={f.id} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 14, marginBottom: 8, flexDirection: "row", alignItems: "center", gap: 12 }}>
                <View style={{ width: 44, height: 44, borderRadius: 14, backgroundColor: "#ea580c20", alignItems: "center", justifyContent: "center" }}>
                  <Text style={{ color: "#ea580c", fontSize: 18, fontWeight: "900" }}>{f.displayName?.charAt(0) || "?"}</Text>
                </View>
                <Text style={{ flex: 1, fontSize: 13, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{f.displayName}</Text>
                <View style={{ flexDirection: "row", gap: 6 }}>
                  <TouchableOpacity onPress={() => handleRespond(f.id, true)} style={{ backgroundColor: "#22c55e", borderRadius: 10, padding: 8 }}><Text style={{ color: "#fff", fontSize: 10, fontWeight: "900" }}>✓</Text></TouchableOpacity>
                  <TouchableOpacity onPress={() => handleRespond(f.id, false)} style={{ backgroundColor: "#ef4444", borderRadius: 10, padding: 8 }}><Text style={{ color: "#fff", fontSize: 10, fontWeight: "900" }}>✕</Text></TouchableOpacity>
                </View>
              </View>
            ))}
          </View>
        )}

        {loading ? <ActivityIndicator size="large" color="#ea580c" style={{ marginTop: 40 }} /> : friends.length === 0 && pendingRequests.length === 0 ? (
          <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 32, alignItems: "center", marginTop: 20 }}>
            <Text style={{ fontSize: 40, marginBottom: 12 }}>👥</Text>
            <Text style={{ color: "#71717a", fontSize: 14, textAlign: "center", marginBottom: 4 }}>Nenhum amigo adicionado</Text>
            <Text style={{ color: "#52525b", fontSize: 11, textAlign: "center" }}>Compartilhe treinos e veja o progresso dos seus amigos</Text>
          </View>
        ) : friends.map((f) => (
          <View key={f.id} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 14, marginBottom: 8, flexDirection: "row", alignItems: "center", gap: 12 }}>
            <View style={{ width: 44, height: 44, borderRadius: 14, backgroundColor: "#ea580c20", alignItems: "center", justifyContent: "center" }}>
              <Text style={{ color: "#ea580c", fontSize: 18, fontWeight: "900" }}>{f.displayName?.charAt(0) || "?"}</Text>
            </View>
            <Text style={{ flex: 1, fontSize: 13, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{f.displayName}</Text>
          </View>
        ))}
      </ScrollView>
    </View>
  );
}
