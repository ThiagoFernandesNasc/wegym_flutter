import { useState, useRef } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, Modal } from "react-native";
import { sendChatMessage } from "@/api/chat";

export function AIChatModal({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const [messages, setMessages] = useState<{ role: string; text: string }[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const scrollRef = useRef<ScrollView>(null);

  const handleSend = async () => {
    if (!input.trim()) return;
    const userMsg = { role: "user", text: input };
    setMessages((prev) => [...prev, userMsg]);
    setInput("");
    setLoading(true);
    try {
      const res = await sendChatMessage(input);
      setMessages((prev) => [...prev, { role: "assistant", text: res.reply }]);
      setTimeout(() => scrollRef.current?.scrollToEnd({ animated: true }), 100);
    } catch {
      setMessages((prev) => [...prev, { role: "assistant", text: "Desculpe, não consegui processar sua solicitação." }]);
    } finally { setLoading(false); }
  };

  return (
    <Modal visible={visible} animationType="slide" transparent>
      <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.85)", justifyContent: "flex-end" }}>
        <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 24, borderTopRightRadius: 24, height: "70%", padding: 16 }}>
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
            <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Assistente IA</Text>
            <TouchableOpacity onPress={onClose}><Text style={{ color: "#71717a", fontSize: 18 }}>✕</Text></TouchableOpacity>
          </View>
          <ScrollView ref={scrollRef} style={{ flex: 1 }} contentContainerStyle={{ gap: 8 }}>
            {messages.length === 0 && (
              <View style={{ alignItems: "center", paddingTop: 40 }}>
                <Text style={{ fontSize: 36, marginBottom: 8 }}>🤖</Text>
                <Text style={{ color: "#71717a", fontSize: 13, textAlign: "center" }}>Pergunte sobre treinos, exercícios, séries...</Text>
              </View>
            )}
            {messages.map((m, i) => (
              <View key={i} style={{ alignItems: m.role === "user" ? "flex-end" : "flex-start" }}>
                <View style={{ maxWidth: "80%", backgroundColor: m.role === "user" ? "#ea580c" : "#27272a", borderRadius: 16, paddingHorizontal: 14, paddingVertical: 10 }}>
                  <Text style={{ color: "#fff", fontSize: 13 }}>{m.text}</Text>
                </View>
              </View>
            ))}
            {loading && (
              <View style={{ alignItems: "flex-start" }}>
                <View style={{ backgroundColor: "#27272a", borderRadius: 16, padding: 14 }}>
                  <ActivityIndicator size="small" color="#ea580c" />
                </View>
              </View>
            )}
          </ScrollView>
          <View style={{ flexDirection: "row", gap: 8, paddingTop: 12, borderTopWidth: 1, borderTopColor: "#27272a" }}>
            <TextInput value={input} onChangeText={setInput} placeholder="Digite sua pergunta..." placeholderTextColor="#71717a" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, paddingHorizontal: 14, paddingVertical: 10, fontSize: 13, color: "#fff" }} />
            <TouchableOpacity onPress={handleSend} disabled={!input.trim() || loading} style={{ backgroundColor: input.trim() && !loading ? "#ea580c" : "#27272a", borderRadius: 14, padding: 12, justifyContent: "center" }}>
              <Text style={{ color: "#fff", fontSize: 14 }}>➤</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}
