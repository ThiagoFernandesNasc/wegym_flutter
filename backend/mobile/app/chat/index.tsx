import { useCallback, useEffect, useRef, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, KeyboardAvoidingView, Platform, Modal } from "react-native";
import { Stack } from "expo-router";
import { getConversations, getMessages, sendMessage, type ConversationsData, type Message } from "@/api/messages";

export default function ChatScreen() {
  const [conversations, setConversations] = useState<ConversationsData>({ sent: [], received: [] });
  const [activeUser, setActiveUser] = useState<string | null>(null);
  const [activeName, setActiveName] = useState("");
  const [messages, setMessages] = useState<Message[]>([]);
  const [text, setText] = useState("");
  const [loading, setLoading] = useState(true);
  const scrollRef = useRef<ScrollView>(null);

  // New conversation modal
  const [showNewChat, setShowNewChat] = useState(false);
  const [newChatEmail, setNewChatEmail] = useState("");

  const loadConversations = useCallback(async () => {
    try {
      const data = await getConversations();
      setConversations(data.conversations);
    } catch { /* silent */ } finally { setLoading(false); }
  }, []);

  useEffect(() => { loadConversations(); }, [loadConversations]);

  const loadMessages = async (userId: string, name: string) => {
    setActiveUser(userId);
    setActiveName(name);
    try { setMessages(await getMessages(userId)); } catch { /* silent */ }
  };

  useEffect(() => { setTimeout(() => scrollRef.current?.scrollToEnd({ animated: true }), 100); }, [messages]);

  const handleSend = async () => {
    if (!text.trim() || !activeUser) return;
    await sendMessage(activeUser, text);
    setText("");
    loadMessages(activeUser, activeName);
  };

  const handleStartNewChat = async () => {
    if (!newChatEmail.trim()) return;
    try {
      await sendMessage(newChatEmail.trim(), "Olá!");
      setNewChatEmail("");
      setShowNewChat(false);
      await loadConversations();
    } catch { /* silent */ }
  };

  const contactMap = new Map<string, { id: string; name: string }>();
  conversations.sent.forEach((m) => { if (!contactMap.has(m.receiver.id)) contactMap.set(m.receiver.id, { id: m.receiver.id, name: m.receiver.displayName }); });
  conversations.received.forEach((m) => { if (!contactMap.has(m.sender.id)) contactMap.set(m.sender.id, { id: m.sender.id, name: m.sender.displayName }); });
  const contacts = [...contactMap.values()];

  return (
    <>
      <Stack.Screen options={{ title: "Chat" }} />
      <KeyboardAvoidingView style={{ flex: 1, backgroundColor: "#09090b" }} behavior={Platform.OS === "ios" ? "padding" : undefined}>
        <View style={{ flex: 1, padding: 20, paddingBottom: 0 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
            <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Chat</Text>
            <TouchableOpacity onPress={() => setShowNewChat(true)} style={{ backgroundColor: "#ea580c", borderRadius: 12, paddingHorizontal: 14, paddingVertical: 8 }}>
              <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>+ Nova</Text>
            </TouchableOpacity>
          </View>

          <View style={{ flex: 1, flexDirection: "row", gap: 12 }}>
            <View style={{ width: "30%", gap: 8 }}>
              {loading ? <ActivityIndicator size="small" color="#ea580c" /> : contacts.length === 0 ? (
                <Text style={{ color: "#71717a", fontSize: 10 }}>Sem conversas</Text>
              ) : contacts.map((c) => (
                <TouchableOpacity key={c.id} onPress={() => loadMessages(c.id, c.name)} style={{ backgroundColor: activeUser === c.id ? "#ea580c20" : "#18181b", borderWidth: 1, borderColor: activeUser === c.id ? "#ea580c" : "#27272a", borderRadius: 14, padding: 10 }}>
                  <View style={{ width: 28, height: 28, borderRadius: 10, backgroundColor: "#ea580c20", alignItems: "center", justifyContent: "center", marginBottom: 4 }}>
                    <Text style={{ color: "#ea580c", fontSize: 12, fontWeight: "900" }}>{c.name.charAt(0)}</Text>
                  </View>
                  <Text style={{ fontSize: 10, fontWeight: "900", color: "#fff" }} numberOfLines={1}>{c.name}</Text>
                </TouchableOpacity>
              ))}
            </View>

            <View style={{ flex: 1, backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, overflow: "hidden" }}>
              {activeUser ? (
                <>
                  <ScrollView ref={scrollRef} style={{ flex: 1, padding: 12 }} contentContainerStyle={{ gap: 8 }}>
                    {messages.map((m, i) => (
                      <View key={i} style={{ alignItems: m.senderId === activeUser ? "flex-start" : "flex-end" }}>
                        <View style={{ maxWidth: "80%", backgroundColor: m.senderId === activeUser ? "#27272a" : "#ea580c", borderRadius: 16, paddingHorizontal: 14, paddingVertical: 10 }}>
                          <Text style={{ color: "#fff", fontSize: 13 }}>{m.text}</Text>
                          <Text style={{ fontSize: 9, color: "rgba(255,255,255,0.5)", marginTop: 4 }}>{new Date(m.createdAt).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}</Text>
                        </View>
                      </View>
                    ))}
                  </ScrollView>
                  <View style={{ flexDirection: "row", gap: 8, padding: 10, borderTopWidth: 1, borderTopColor: "#27272a" }}>
                    <TextInput value={text} onChangeText={setText} placeholder="Digite sua mensagem..." placeholderTextColor="#71717a" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, paddingHorizontal: 14, paddingVertical: 10, fontSize: 13, color: "#fff" }} />
                    <TouchableOpacity onPress={handleSend} disabled={!text.trim()} style={{ backgroundColor: text.trim() ? "#ea580c" : "#27272a", borderRadius: 14, padding: 12, justifyContent: "center" }}>
                      <Text style={{ color: "#fff", fontSize: 14 }}>➤</Text>
                    </TouchableOpacity>
                  </View>
                </>
              ) : (
                <View style={{ flex: 1, alignItems: "center", justifyContent: "center" }}>
                  <Text style={{ fontSize: 36, marginBottom: 12 }}>💬</Text>
                  <Text style={{ color: "#71717a", fontSize: 13 }}>Selecione um contato</Text>
                </View>
              )}
            </View>
          </View>
        </View>

        {/* New Chat Modal */}
        <Modal visible={showNewChat} animationType="slide" transparent>
          <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.7)", justifyContent: "flex-end" }}>
            <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24 }}>
              <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 16 }}>Nova conversa</Text>
              <TextInput value={newChatEmail} onChangeText={setNewChatEmail} placeholder="Email do usuário" placeholderTextColor="#71717a" autoCapitalize="none" keyboardType="email-address" style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 12 }} />
              <View style={{ flexDirection: "row", gap: 12 }}>
                <TouchableOpacity onPress={() => setShowNewChat(false)} style={{ flex: 1, backgroundColor: "#27272a", borderRadius: 14, padding: 14, alignItems: "center" }}>
                  <Text style={{ color: "#a1a1aa", fontSize: 12, fontWeight: "800", textTransform: "uppercase" }}>Cancelar</Text>
                </TouchableOpacity>
                <TouchableOpacity onPress={handleStartNewChat} disabled={!newChatEmail.trim()} style={{ flex: 1, backgroundColor: newChatEmail.trim() ? "#ea580c" : "#27272a", borderRadius: 14, padding: 14, alignItems: "center" }}>
                  <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>Iniciar</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        </Modal>
      </KeyboardAvoidingView>
    </>
  );
}
