import { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, Image, Modal } from "react-native";
import { getExerciseGifUrl } from "@/data/exercise-gifs";

type ExerciseItemProps = {
  name: string;
  sets: string;
  reps: string;
  load: string;
  muscle?: string;
  completed?: boolean;
  gifUrl?: string;
  onToggle?: () => void;
  onUpdateSets?: (v: string) => void;
  onUpdateReps?: (v: string) => void;
  onUpdateLoad?: (v: string) => void;
  onRemove?: () => void;
};

export function ExerciseItem({
  name, sets, reps, load, muscle, completed, gifUrl, onToggle, onUpdateSets, onUpdateReps, onUpdateLoad, onRemove,
}: ExerciseItemProps) {
  const [showGif, setShowGif] = useState(false);
  const resolvedGif = gifUrl ?? getExerciseGifUrl(name);

  return (
    <View style={{ backgroundColor: completed ? "#10b98110" : "#18181b", borderWidth: 1, borderColor: completed ? "#10b981" : "#27272a", borderRadius: 16, padding: 14, marginBottom: 8 }}>
      <View style={{ flexDirection: "row", alignItems: "center", gap: 10, marginBottom: 8 }}>
        <TouchableOpacity onPress={onToggle} style={{ width: 24, height: 24, borderRadius: 6, borderWidth: 2, borderColor: completed ? "#10b981" : "#52525b", backgroundColor: completed ? "#10b981" : "transparent", alignItems: "center", justifyContent: "center" }}>
          {completed && <Text style={{ color: "#fff", fontSize: 12 }}>✓</Text>}
        </TouchableOpacity>
        <View style={{ flex: 1 }}>
          <Text style={{ fontSize: 14, fontWeight: "800", fontStyle: "italic", color: completed ? "#10b981" : "#fff", textDecorationLine: completed ? "line-through" : "none" }}>{name}</Text>
          {muscle && <Text style={{ fontSize: 9, color: "#ea580c", fontWeight: "800", textTransform: "uppercase", marginTop: 1 }}>{muscle} • {sets}x{reps}</Text>}
        </View>
        {onRemove && <TouchableOpacity onPress={onRemove}><Text style={{ color: "#dc2626", fontSize: 14 }}>✕</Text></TouchableOpacity>}
      </View>
      <View style={{ flexDirection: "row", gap: 10, paddingLeft: 34 }}>
        <InputGroup label="S" value={sets} onChange={onUpdateSets || (() => {})} />
        <InputGroup label="R" value={reps} onChange={onUpdateReps || (() => {})} />
        <InputGroup label="kg" value={load} onChange={onUpdateLoad || (() => {})} />
      </View>

      {completed && resolvedGif && (
        <TouchableOpacity onPress={() => setShowGif(true)} style={{ marginTop: 8, paddingLeft: 34 }}>
          <Text style={{ color: "#22c55e", fontSize: 10, fontWeight: "800", textTransform: "uppercase" }}>▶ Ver demonstração</Text>
        </TouchableOpacity>
      )}

      <Modal visible={showGif} transparent animationType="fade" onRequestClose={() => setShowGif(false)}>
        <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.92)", justifyContent: "center", alignItems: "center", padding: 24 }}>
          {resolvedGif && (
            <Image source={{ uri: resolvedGif }} style={{ width: "100%", aspectRatio: 1, maxWidth: 320, borderRadius: 20 }} resizeMode="contain" />
          )}
          <Text style={{ color: "#a1a1aa", fontSize: 12, marginTop: 16, textAlign: "center" }}>{name}</Text>
          <TouchableOpacity onPress={() => setShowGif(false)} style={{ marginTop: 24, backgroundColor: "#ea580c", borderRadius: 14, paddingHorizontal: 40, paddingVertical: 14 }}>
            <Text style={{ color: "#fff", fontSize: 13, fontWeight: "900", textTransform: "uppercase" }}>OK</Text>
          </TouchableOpacity>
        </View>
      </Modal>
    </View>
  );
}

function InputGroup({ label, value, onChange }: { label: string; value: string; onChange: (v: string) => void }) {
  return (
    <View style={{ flex: 1 }}>
      <Text style={{ fontSize: 8, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 2 }}>{label}</Text>
      <TextInput value={value} onChangeText={onChange} keyboardType="numeric" style={{ backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 8, padding: 8, fontSize: 13, fontWeight: "700", color: "#fff", textAlign: "center" }} />
    </View>
  );
}
