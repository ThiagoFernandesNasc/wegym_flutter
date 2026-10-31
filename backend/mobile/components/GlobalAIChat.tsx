import { useState } from "react";
import { View, TouchableOpacity, Text } from "react-native";
import { usePathname } from "expo-router";
import { AIChatModal } from "./AIChat";

const HIDE_ON_ROUTES = ["/login", "/reset-password"];

export function GlobalAIChatFAB() {
  const [show, setShow] = useState(false);
  const pathname = usePathname();

  if (HIDE_ON_ROUTES.includes(pathname)) return null;

  return (
    <>
      <TouchableOpacity
        onPress={() => setShow(true)}
        style={{
          position: "absolute",
          bottom: 80,
          right: 16,
          backgroundColor: "#ea580c",
          borderRadius: 28,
          width: 56,
          height: 56,
          alignItems: "center",
          justifyContent: "center",
          shadowColor: "#ea580c",
          shadowOffset: { width: 0, height: 4 },
          shadowOpacity: 0.4,
          shadowRadius: 8,
          elevation: 8,
          zIndex: 999,
        }}
      >
        <Text style={{ color: "#fff", fontSize: 22 }}>🤖</Text>
      </TouchableOpacity>
      <AIChatModal visible={show} onClose={() => setShow(false)} />
    </>
  );
}
