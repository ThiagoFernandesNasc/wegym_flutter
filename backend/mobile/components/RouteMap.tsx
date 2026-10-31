import { View } from "react-native";
import MapView, { Polyline, Marker, PROVIDER_GOOGLE } from "react-native-maps";
import { Platform } from "react-native";

interface Coordinate {
  latitude: number;
  longitude: number;
}

interface RouteMapProps {
  coordinates: Coordinate[];
  height?: number;
  interactive?: boolean;
}

export default function RouteMap({ coordinates, height = 180, interactive = false }: RouteMapProps) {
  if (coordinates.length < 2) {
    return (
      <View style={{ height, backgroundColor: "#18181b", borderRadius: 16, justifyContent: "center", alignItems: "center" }}>
        <View style={{ backgroundColor: "#27272a", paddingHorizontal: 16, paddingVertical: 8, borderRadius: 8 }}>
          <MapIcon />
        </View>
      </View>
    );
  }

  const start = coordinates[0];
  const end = coordinates[coordinates.length - 1];
  const lats = coordinates.map((c) => c.latitude);
  const lngs = coordinates.map((c) => c.longitude);
  const minLat = Math.min(...lats);
  const maxLat = Math.max(...lats);
  const minLng = Math.min(...lngs);
  const maxLng = Math.max(...lngs);
  const latDelta = (maxLat - minLat) * 1.3 || 0.01;
  const lngDelta = (maxLng - minLng) * 1.3 || 0.01;

  return (
    <View style={{ height, borderRadius: 16, overflow: "hidden" }}>
      <MapView
        style={{ flex: 1 }}
        initialRegion={{
          latitude: (minLat + maxLat) / 2,
          longitude: (minLng + maxLng) / 2,
          latitudeDelta: latDelta,
          longitudeDelta: lngDelta,
        }}
        scrollEnabled={interactive}
        zoomEnabled={interactive}
        rotateEnabled={false}
        pitchEnabled={false}
        provider={Platform.OS === "android" ? PROVIDER_GOOGLE : undefined}
      >
        <Polyline coordinates={coordinates} strokeColor="#ea580c" strokeWidth={4} />
        <Marker coordinate={start} title="Início" pinColor="#22c55e" />
        <Marker coordinate={end} title="Fim" pinColor="#ef4444" />
      </MapView>
    </View>
  );
}

function MapIcon() {
  return null;
}
