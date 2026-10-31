import { Redirect } from "expo-router";
import { getToken } from "@/api/client";
import { useEffect, useState } from "react";
import { ActivityIndicator, View } from "react-native";

export default function Index() {
  const [ready, setReady] = useState(false);
  const [hasToken, setHasToken] = useState(false);

  useEffect(() => {
    getToken().then((t) => {
      setHasToken(!!t);
      setReady(true);
    });
  }, []);

  if (!ready) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center", backgroundColor: "#09090b" }}>
        <ActivityIndicator size="large" color="#ea580c" />
      </View>
    );
  }

  return <Redirect href={hasToken ? "/(tabs)/home" : "/login"} />;
}
