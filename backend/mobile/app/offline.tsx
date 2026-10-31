import { View, Text } from "react-native";

export default function OfflineScreen() {
  return (
    <View style={{ flex: 1, backgroundColor: "#09090b", justifyContent: "center", alignItems: "center", padding: 32 }}>
      <Text style={{ fontSize: 64, marginBottom: 16 }}>📡</Text>
      <Text style={{ fontSize: 22, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 8 }}>Sem conexão</Text>
      <Text style={{ fontSize: 13, color: "#a1a1aa", textAlign: "center", lineHeight: 20 }}>
        Você está offline. Conecte-se à internet para continuar usando o WEGYM.
      </Text>
    </View>
  );
}
