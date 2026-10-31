import { useEffect, useState } from "react";
import { View, Text, ActivityIndicator } from "react-native";
import { router } from "expo-router";
import { getProfile } from "@/api/auth";

type Props = {
  allowedRoles: ("atleta" | "personal")[];
  children: React.ReactNode;
};

export function AuthGuard({ allowedRoles, children }: Props) {
  const [authorized, setAuthorized] = useState(false);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    (async () => {
      try {
        const profile = await getProfile();
        const role = (profile as { role: string }).role as "atleta" | "personal";
        if (allowedRoles.includes(role)) {
          setAuthorized(true);
        } else {
          router.replace(role === "personal" ? "/personal" : "/(tabs)/home");
        }
      } catch {
        router.replace("/login");
      } finally {
        setChecking(false);
      }
    })();
  }, []);

  if (checking) {
    return (
      <View style={{ flex: 1, backgroundColor: "#09090b", justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" color="#ea580c" />
      </View>
    );
  }

  if (!authorized) return null;

  return <>{children}</>;
}
