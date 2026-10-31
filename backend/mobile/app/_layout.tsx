import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { useEffect, useState } from "react";
import { View, Text } from "react-native";
import * as Notifications from "expo-notifications";
import NetInfo from "@react-native-community/netinfo";
import { GlobalAIChatFAB } from "@/components/GlobalAIChat";
import { ConsentBanner } from "@/components/ConsentBanner";

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

export default function RootLayout() {
  const [isOffline, setIsOffline] = useState(false);

  useEffect(() => {
    Notifications.requestPermissionsAsync();
    const unsub = NetInfo.addEventListener((state) => {
      setIsOffline(!(state.isConnected ?? false));
    });
    return () => unsub();
  }, []);

  if (isOffline) {
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

  return (
    <View style={{ flex: 1, backgroundColor: "#09090b" }}>
      <StatusBar style="light" />
      <Stack
        screenOptions={{
          headerShown: false,
          contentStyle: { backgroundColor: "#09090b" },
          animation: "slide_from_right",
        }}
      >
        <Stack.Screen name="login" />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="training/[id]" />
        <Stack.Screen name="gps/[mode]" />
        <Stack.Screen name="gym/index" />
        <Stack.Screen name="integrations" />
        <Stack.Screen name="goals/index" />
        <Stack.Screen name="checkin/index" />
        <Stack.Screen name="feed/index" />
        <Stack.Screen name="chat/index" />
        <Stack.Screen name="programs/index" />
        <Stack.Screen name="programs/[id]" />
        <Stack.Screen name="nutrition/index" />
        <Stack.Screen name="achievements/index" />
        <Stack.Screen name="challenges/index" />
        <Stack.Screen name="challenges/[id]"/>
        <Stack.Screen name="appointments/index" />
        <Stack.Screen name="measurements/index" />
        <Stack.Screen name="personal/index" />
        <Stack.Screen name="pro/index" />
        <Stack.Screen name="privacy/index" />
        <Stack.Screen name="payment/index" />
        <Stack.Screen name="friends/index" />
        <Stack.Screen name="reset-password/index" />
        <Stack.Screen name="ble/index" />
      </Stack>
      <GlobalAIChatFAB />
      <ConsentBanner />
    </View>
  );
}
