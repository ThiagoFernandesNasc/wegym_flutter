import type { ExpoConfig, ConfigContext } from "expo/config";

export default ({ config }: ConfigContext): ExpoConfig => {
  const apiKey = process.env.EXPO_PUBLIC_GOOGLE_MAPS_API_KEY;

  return {
    ...config,
    name: config.name ?? "WEGYM",
    slug: config.slug ?? "wegym",
    android: {
      ...config.android,
      ...(apiKey
        ? {
            config: {
              ...(config.android?.config ?? {}),
              googleMaps: { apiKey },
            },
          }
        : {}),
    },
  };
};
