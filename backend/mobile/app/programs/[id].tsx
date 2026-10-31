import { useEffect, useState } from "react";
import { View, Text, ScrollView, ActivityIndicator } from "react-native";
import { useLocalSearchParams, Stack } from "expo-router";
import { getProgram, type Program } from "@/api/programs";

export default function ProgramDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const [program, setProgram] = useState<Program | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    getProgram(id).then(setProgram).catch(() => {}).finally(() => setLoading(false));
  }, [id]);

  const weeks = program ? [...new Set(program.exercises.map((e) => e.weekNumber))] : [];

  return (
    <>
      <Stack.Screen options={{ title: program?.title || "Programa" }} />
      <ScrollView style={{ flex: 1, backgroundColor: "#09090b" }}>
        <View style={{ padding: 20 }}>
          {loading ? <ActivityIndicator size="large" color="#ea580c" /> : !program ? (
            <Text style={{ color: "#71717a", textAlign: "center", marginTop: 60 }}>Programa não encontrado</Text>
          ) : (
            <>
              <Text style={{ fontSize: 22, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{program.title}</Text>
              <Text style={{ fontSize: 12, color: "#71717a", marginTop: 8, lineHeight: 18 }}>{program.description}</Text>
              <Text style={{ fontSize: 10, color: "#52525b", fontWeight: "800", textTransform: "uppercase", marginTop: 12 }}>{program.durationWeeks} semanas · {program.daysPerWeek}x/semana</Text>

              {weeks.map((week) => {
                const weekExercises = program.exercises.filter((e) => e.weekNumber === week);
                const days = [...new Set(weekExercises.map((e) => e.dayNumber))];
                return (
                  <View key={week} style={{ marginTop: 24 }}>
                    <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 12 }}>Semana {week}</Text>
                    {days.map((day) => {
                      const dayExercises = weekExercises.filter((e) => e.dayNumber === day);
                      return (
                        <View key={day} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 14, marginBottom: 10 }}>
                          <Text style={{ fontSize: 12, fontWeight: "800", color: "#ea580c", textTransform: "uppercase", marginBottom: 8 }}>Dia {day}</Text>
                          {dayExercises.sort((a, b) => a.order - b.order).map((ex) => (
                            <View key={ex.id} style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 6, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
                              <Text style={{ color: "#d4d4d8", fontSize: 13, flex: 1 }}>{ex.name}</Text>
                              <Text style={{ color: "#71717a", fontSize: 11 }}>{ex.sets}x{ex.reps}</Text>
                            </View>
                          ))}
                        </View>
                      );
                    })}
                  </View>
                );
              })}
            </>
          )}
        </View>
      </ScrollView>
    </>
  );
}
