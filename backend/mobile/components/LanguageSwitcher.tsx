import { View, Text } from "react-native";

export function LanguageSwitcher() {
  return (
    <View style={{ flexDirection: "row", alignItems: "center", gap: 4, padding: 4 }}>
      <Text style={{ fontSize: 10, color: "#71717a", fontWeight: "700" }}>🇧🇷 PT-BR</Text>
    </View>
  );
}
