import { TouchableOpacity, Text, ActivityIndicator, type ViewStyle } from "react-native";

type ButtonProps = {
  title: string;
  onPress: () => void;
  variant?: "primary" | "secondary" | "danger" | "ghost";
  loading?: boolean;
  disabled?: boolean;
  style?: ViewStyle;
};

const VARIANTS: Record<string, { bg: string; text: string; border?: string }> = {
  primary: { bg: "#ea580c", text: "#fff" },
  secondary: { bg: "#18181b", text: "#fff", border: "#27272a" },
  danger: { bg: "#dc2626", text: "#fff" },
  ghost: { bg: "transparent", text: "#ea580c" },
};

export function Button({ title, onPress, variant = "primary", loading, disabled, style }: ButtonProps) {
  const v = VARIANTS[variant];

  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled || loading}
      style={{
        backgroundColor: v.bg,
        borderRadius: 16,
        padding: 16,
        alignItems: "center",
        justifyContent: "center",
        opacity: disabled || loading ? 0.5 : 1,
        borderWidth: v.border ? 1 : 0,
        borderColor: v.border ?? "transparent",
        flexDirection: "row",
        gap: 8,
        ...style,
      }}
    >
      {loading ? (
        <ActivityIndicator size="small" color={v.text} />
      ) : (
        <Text style={{ color: v.text, fontSize: 13, fontWeight: "900", fontStyle: "italic", textTransform: "uppercase", letterSpacing: 0.5 }}>
          {title}
        </Text>
      )}
    </TouchableOpacity>
  );
}
