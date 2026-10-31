import { View, Text, type ViewStyle } from "react-native";

type CardProps = {
  children: React.ReactNode;
  style?: ViewStyle;
  color?: string;
};

export function Card({ children, style, color }: CardProps) {
  return (
    <View
      style={{
        backgroundColor: "#18181b",
        borderWidth: 1,
        borderColor: color ? color + "30" : "#27272a",
        borderRadius: 20,
        padding: 16,
        ...style,
      }}
    >
      {children}
    </View>
  );
}

export function CardRow({ label, value, unit }: { label: string; value: string; unit?: string }) {
  return (
    <View style={{ alignItems: "center" }}>
      <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1.5, color: "#71717a", marginBottom: 4 }}>
        {label}
      </Text>
      <Text style={{ fontSize: 28, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>
        {value}
      </Text>
      {unit && <Text style={{ fontSize: 10, color: "#a1a1aa", marginTop: 2 }}>{unit}</Text>}
    </View>
  );
}

export function Divider() {
  return <View style={{ height: 1, backgroundColor: "#27272a", marginVertical: 12 }} />;
}

export function Badge({ label, color = "#ea580c" }: { label: string; color?: string }) {
  return (
    <View style={{ backgroundColor: color + "20", borderRadius: 20, paddingHorizontal: 10, paddingVertical: 3 }}>
      <Text style={{ fontSize: 9, fontWeight: "800", textTransform: "uppercase", letterSpacing: 0.5, color }}>{label}</Text>
    </View>
  );
}
