import { View, Text, TouchableOpacity } from "react-native";
import { router } from "expo-router";

type HeaderProps = {
  title: string;
  subtitle?: string;
  showBack?: boolean;
  rightAction?: React.ReactNode;
};

export function Header({ title, subtitle, showBack = true, rightAction }: HeaderProps) {
  return (
    <View style={{ paddingTop: 60, paddingHorizontal: 20, paddingBottom: 16 }}>
      <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
        <View style={{ flexDirection: "row", alignItems: "center", gap: 12, flex: 1 }}>
          {showBack && (
            <TouchableOpacity onPress={() => router.back()} style={{ padding: 4 }}>
              <Text style={{ color: "#ea580c", fontSize: 18, fontWeight: "800" }}>{"<"}</Text>
            </TouchableOpacity>
          )}
          <View style={{ flex: 1 }}>
            <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff", letterSpacing: -0.5 }} numberOfLines={1}>
              {title}
            </Text>
            {subtitle && (
              <Text style={{ fontSize: 12, color: "#a1a1aa", marginTop: 2 }}>{subtitle}</Text>
            )}
          </View>
        </View>
        {rightAction}
      </View>
    </View>
  );
}
