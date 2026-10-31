import { useCallback, useEffect, useRef, useState } from "react";
import { View, Text, TextInput, TouchableOpacity, ScrollView, ActivityIndicator, Alert, Modal, FlatList } from "react-native";
import { Stack } from "expo-router";
import { getPersonalStats, type PersonalStats } from "@/api/personal";
import { getClasses, type ClassEntry } from "@/api/classes";
import { getAthletes, registerAthlete, deleteAthlete, type Athlete } from "@/api/athletes";
import { getTrainingPlan, addExercise, removeExercise, type TrainingPlanExercise } from "@/api/training-plans";
import { getStudentProgress, addProgress, type ProgressEntry } from "@/api/progress";
import { sendChatMessage } from "@/api/chat";

const DAYS = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"];

export default function PersonalScreen() {
  const [view, setView] = useState<"home" | "students" | "profile">("home");
  const [stats, setStats] = useState<PersonalStats | null>(null);
  const [classes, setClasses] = useState<ClassEntry[]>([]);
  const [students, setStudents] = useState<Athlete[]>([]);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);
  const [selectedStudent, setSelectedStudent] = useState<Athlete | null>(null);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    name: "", email: "", phone: "", cpf: "", gender: "", birthDate: "",
    emergency: "", experienceLevel: "", objective: "",
    plan: "", height: "", weight: "", bodyFat: "",
    availableDays: "", restrictions: "", injuries: "",
    medications: "", observations: "",
  });

  const [studentPlan, setStudentPlan] = useState<TrainingPlanExercise[]>([]);
  const [studentProgress, setStudentProgress] = useState<ProgressEntry[]>([]);
  const [newEx, setNewEx] = useState({ name: "", sets: "4", reps: "10", load: "", day: 0 });
  const [newProgress, setNewProgress] = useState({ weight: "", muscleMass: "", bodyFat: "", notes: "" });

  // AI Copilot
  const [showCopilot, setShowCopilot] = useState(false);
  const [copilotInput, setCopilotInput] = useState("");
  const [copilotReply, setCopilotReply] = useState("");
  const [copilotLoading, setCopilotLoading] = useState(false);

  const loadDashboard = useCallback(async () => {
    try {
      const [s, c] = await Promise.all([getPersonalStats().catch(() => null), getClasses().catch(() => [])]);
      setStats(s); setClasses(c);
    } catch { /* silent */ } finally { setLoading(false); }
  }, []);

  const loadStudents = useCallback(async (cursor?: string, append = false) => {
    try {
      const res = await getAthletes(cursor);
      setStudents(append ? (prev) => [...prev, ...res.data] : res.data);
      setNextCursor(res.nextCursor);
    } catch { /* silent */ }
  }, []);

  useEffect(() => { loadDashboard(); }, [loadDashboard]);

  const handleSelectStudent = async (s: Athlete) => {
    setSelectedStudent(s); setView("profile");
    try {
      const [plan, progress] = await Promise.all([
        getTrainingPlan(s.id).catch(() => []),
        getStudentProgress(s.id).catch(() => []),
      ]);
      setStudentPlan(plan); setStudentProgress(progress);
    } catch { /* silent */ }
  };

  const handleAddExercise = async () => {
    if (!selectedStudent || !newEx.name) return;
    await addExercise({ studentId: selectedStudent.id, name: newEx.name, sets: Number(newEx.sets), reps: newEx.reps, load: newEx.load, dayOfWeek: newEx.day });
    setNewEx({ name: "", sets: "4", reps: "10", load: "", day: 0 });
    const plan = await getTrainingPlan(selectedStudent.id);
    setStudentPlan(plan);
  };

  const handleRemoveExercise = async (id: string) => {
    await removeExercise(id);
    if (selectedStudent) { const plan = await getTrainingPlan(selectedStudent.id); setStudentPlan(plan); }
  };

  const handleAddProgress = async () => {
    if (!selectedStudent || !newProgress.weight) return;
    await addProgress({ studentId: selectedStudent.id, weight: Number(newProgress.weight), muscleMass: newProgress.muscleMass ? Number(newProgress.muscleMass) : undefined, bodyFat: newProgress.bodyFat ? Number(newProgress.bodyFat) : undefined, notes: newProgress.notes });
    setNewProgress({ weight: "", muscleMass: "", bodyFat: "", notes: "" });
    const progress = await getStudentProgress(selectedStudent.id);
    setStudentProgress(progress);
  };

  const handleRegister = async () => {
    if (!form.name || !form.email) { Alert.alert("Campos obrigatórios", "Nome e email são obrigatórios"); return; }
    await registerAthlete({
      name: form.name, email: form.email, phone: form.phone, cpf: form.cpf,
      birthDate: form.birthDate, sex: form.gender,
      heightCm: form.height ? Number(form.height) : undefined,
      weightKg: form.weight ? Number(form.weight) : undefined,
      experienceLevel: form.experienceLevel, objective: form.objective,
      availableDays: form.availableDays, emergencyContact: form.emergency,
      restrictions: form.restrictions, injuries: form.injuries,
      medications: form.medications, observations: form.observations,
    });
    setShowForm(false);
    setForm({ name: "", email: "", phone: "", cpf: "", gender: "", birthDate: "", emergency: "", experienceLevel: "", objective: "", plan: "", height: "", weight: "", bodyFat: "", availableDays: "", restrictions: "", injuries: "", medications: "", observations: "" });
    loadStudents();
  };

  const handleDeleteStudent = (s: Athlete) => {
    Alert.alert("Excluir aluno", `Tem certeza que deseja excluir ${s.name}?`, [
      { text: "Cancelar", style: "cancel" },
      { text: "Excluir", style: "destructive", onPress: async () => {
        try { await deleteAthlete(s.id).catch(() => {}); setStudents((prev) => prev.filter((x) => x.id !== s.id)); if (selectedStudent?.id === s.id) { setSelectedStudent(null); setView("students"); } Alert.alert("Aluno excluído"); } catch { Alert.alert("Erro", "Não foi possível excluir"); }
      }},
    ]);
  };

  const handleCopilot = async () => {
    if (!copilotInput.trim()) return;
    setCopilotLoading(true);
    try {
      const res = await sendChatMessage(`[Personal Coach] ${copilotInput}${selectedStudent ? ` (aluno: ${selectedStudent.name})` : ""}`);
      setCopilotReply(res.reply);
    } catch { setCopilotReply("Desculpe, não consegui processar. Tente novamente."); } finally { setCopilotLoading(false); }
  };

  const handleLoadMore = async () => {
    if (loadingMore || !nextCursor) return;
    setLoadingMore(true);
    await loadStudents(nextCursor, true);
    setLoadingMore(false);
  };

  const filteredStudents = students.filter((s) => !search || s.name?.toLowerCase().includes(search.toLowerCase()));

  const inputStyle = { backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 14, fontSize: 14, color: "#fff", marginBottom: 12 };

  const renderStudentItem = ({ item }: { item: Athlete }) => (
    <TouchableOpacity key={item.id} onPress={() => handleSelectStudent(item)} onLongPress={() => handleDeleteStudent(item)} style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 14, marginBottom: 8, flexDirection: "row", alignItems: "center", gap: 12 }}>
      <View style={{ width: 40, height: 40, borderRadius: 14, backgroundColor: "#ea580c20", alignItems: "center", justifyContent: "center" }}>
        <Text style={{ color: "#ea580c", fontSize: 16, fontWeight: "900" }}>{item.name?.charAt(0) || "?"}</Text>
      </View>
      <View style={{ flex: 1 }}>
        <Text style={{ fontSize: 13, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{item.name}</Text>
        {item.lastTrainingDate && <Text style={{ fontSize: 10, color: "#71717a", marginTop: 2 }}>Último treino: {new Date(item.lastTrainingDate).toLocaleDateString("pt-BR")}</Text>}
      </View>
      <Text style={{ color: "#52525b", fontSize: 16 }}>›</Text>
    </TouchableOpacity>
  );

  return (
    <>
      <Stack.Screen options={{ title: "Personal" }} />
      <View style={{ flex: 1, backgroundColor: "#09090b", flexDirection: "row" }}>
        {/* Sidebar quick-list */}
        {view === "students" && students.length > 5 && (
          <View style={{ width: 60, backgroundColor: "#101012", borderRightWidth: 1, borderRightColor: "#27272a", paddingTop: 60, paddingHorizontal: 6 }}>
            <Text style={{ color: "#52525b", fontSize: 8, fontWeight: "900", textTransform: "uppercase", textAlign: "center", marginBottom: 10 }}>Alunos</Text>
            <ScrollView>
              {students.map((s) => (
                <TouchableOpacity key={s.id} onPress={() => handleSelectStudent(s)} style={{ width: 44, height: 44, borderRadius: 12, backgroundColor: selectedStudent?.id === s.id ? "#ea580c30" : "#18181b", alignItems: "center", justifyContent: "center", marginBottom: 6, borderWidth: 1, borderColor: selectedStudent?.id === s.id ? "#ea580c" : "transparent" }}>
                  <Text style={{ fontSize: 14, fontWeight: "900", color: "#ea580c" }}>{s.name?.charAt(0)}</Text>
                </TouchableOpacity>
              ))}
            </ScrollView>
          </View>
        )}

        <ScrollView style={{ flex: 1 }} onMomentumScrollEnd={({ nativeEvent }) => {
          const { contentOffset, contentSize, layoutMeasurement } = nativeEvent;
          if (contentOffset.y + layoutMeasurement.height >= contentSize.height - 100) handleLoadMore();
        }}>
          <View style={{ padding: 20 }}>
            {view === "home" && (
              <>
                <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
                  <Text style={{ fontSize: 24, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>PRO COACH</Text>
                  <View style={{ flexDirection: "row", gap: 8 }}>
                    <TouchableOpacity onPress={() => setShowCopilot(true)} style={{ backgroundColor: "#7c3aed", borderRadius: 14, paddingHorizontal: 12, paddingVertical: 10 }}>
                      <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>Copilot</Text>
                    </TouchableOpacity>
                    <TouchableOpacity onPress={() => setShowForm(true)} style={{ backgroundColor: "#ea580c", borderRadius: 14, paddingHorizontal: 16, paddingVertical: 10 }}>
                      <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>+ Aluno</Text>
                    </TouchableOpacity>
                  </View>
                </View>

                {loading ? <ActivityIndicator size="large" color="#ea580c" /> : (
                  <>
                    <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10, marginBottom: 16 }}>
                      {[
                        { label: "Alunos ativos", value: String(stats?.activeStudents ?? 0) },
                        { label: "Aulas/sem", value: String(stats?.classesPerWeek ?? 0) },
                        { label: "Receita", value: `R$ ${(stats?.monthlyRevenue ?? 0).toFixed(0)}` },
                        { label: "Retenção", value: `${(stats?.retentionRate ?? 0).toFixed(0)}%` },
                      ].map((c) => (
                        <View key={c.label} style={{ flex: 1, minWidth: "45%", backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 16, padding: 12 }}>
                          <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", color: "#71717a", marginBottom: 4 }}>{c.label}</Text>
                          <Text style={{ fontSize: 18, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>{c.value}</Text>
                        </View>
                      ))}
                    </View>

                    <View style={{ flexDirection: "row", gap: 8, marginBottom: 16 }}>
                      <TouchableOpacity onPress={() => { loadStudents(); setView("students"); }} style={{ flex: 1, backgroundColor: "#ea580c", borderRadius: 14, padding: 14, alignItems: "center" }}>
                        <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Ver alunos</Text>
                      </TouchableOpacity>
                      <TouchableOpacity onPress={() => setShowCopilot(true)} style={{ flex: 1, backgroundColor: "#7c3aed", borderRadius: 14, padding: 14, alignItems: "center" }}>
                        <Text style={{ color: "#fff", fontSize: 11, fontWeight: "900", textTransform: "uppercase" }}>Copilot IA</Text>
                      </TouchableOpacity>
                    </View>

                    {/* Agenda semanal */}
                    <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
                      <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Agenda da semana</Text>
                      <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 4 }}>
                        {DAYS.map((d, idx) => {
                          const dayClasses = classes.filter((c) => c.dayOfWeek === idx);
                          return (
                            <View key={d} style={{ width: "13.5%", backgroundColor: "#09090b", borderRadius: 10, padding: 6, alignItems: "center", marginBottom: 4 }}>
                              <Text style={{ color: "#ea580c", fontSize: 8, fontWeight: "900", marginBottom: 4, textTransform: "uppercase" }}>{d}</Text>
                              {dayClasses.length === 0 ? (
                                <Text style={{ color: "#27272a", fontSize: 10 }}>—</Text>
                              ) : (
                                dayClasses.slice(0, 2).map((c) => (
                                  <Text key={c.id} style={{ color: "#d4d4d8", fontSize: 8, lineHeight: 12 }} numberOfLines={1}>{c.studentName?.slice(0, 8)}</Text>
                                ))
                              )}
                            </View>
                          );
                        })}
                      </View>
                      {classes.length > 0 && (
                        <View style={{ marginTop: 8 }}>
                          {classes.slice(0, 3).map((c) => (
                            <View key={c.id} style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 4, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
                              <Text style={{ color: "#d4d4d8", fontSize: 11 }}>{c.studentName}</Text>
                              <Text style={{ color: "#71717a", fontSize: 10 }}>{DAYS[c.dayOfWeek]} {c.time}</Text>
                            </View>
                          ))}
                        </View>
                      )}
                    </View>
                  </>
                )}
              </>
            )}

            {view === "students" && (
              <>
                <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
                  <TouchableOpacity onPress={() => setView("home")}><Text style={{ color: "#ea580c", fontSize: 14 }}>‹ Voltar</Text></TouchableOpacity>
                  <TouchableOpacity onPress={() => setShowForm(true)} style={{ backgroundColor: "#ea580c", borderRadius: 10, paddingHorizontal: 14, paddingVertical: 8 }}>
                    <Text style={{ color: "#fff", fontSize: 10, fontWeight: "900", textTransform: "uppercase" }}>+ Novo</Text>
                  </TouchableOpacity>
                </View>
                <TextInput value={search} onChangeText={setSearch} placeholder="Buscar alunos..." placeholderTextColor="#71717a" style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, padding: 12, fontSize: 14, color: "#fff", marginBottom: 16 }} />
                {filteredStudents.length === 0 && !loading && <Text style={{ color: "#71717a", fontSize: 12, textAlign: "center", marginTop: 20 }}>Nenhum aluno encontrado</Text>}
                {filteredStudents.map((s) => renderStudentItem({ item: s }))}
                {loadingMore && <ActivityIndicator size="small" color="#ea580c" style={{ marginVertical: 12 }} />}
                {nextCursor && !loadingMore && (
                  <TouchableOpacity onPress={handleLoadMore} style={{ backgroundColor: "#27272a", borderRadius: 14, padding: 12, alignItems: "center", marginTop: 8 }}>
                    <Text style={{ color: "#a1a1aa", fontSize: 11, fontWeight: "800" }}>Carregar mais</Text>
                  </TouchableOpacity>
                )}
              </>
            )}

            {view === "profile" && selectedStudent && (
              <>
                <TouchableOpacity onPress={() => { setSelectedStudent(null); setView("students"); }} style={{ marginBottom: 12 }}><Text style={{ color: "#ea580c", fontSize: 14 }}>‹ Alunos</Text></TouchableOpacity>
                <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <View style={{ flex: 1 }}>
                    <Text style={{ fontSize: 22, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 2 }}>{selectedStudent.name}</Text>
                    <Text style={{ fontSize: 11, color: "#71717a", marginBottom: 4 }}>{selectedStudent.email}</Text>
                    {selectedStudent.phone && <Text style={{ fontSize: 10, color: "#52525b" }}>{selectedStudent.phone}</Text>}
                  </View>
                  <TouchableOpacity onPress={() => handleDeleteStudent(selectedStudent)} style={{ backgroundColor: "#dc262610", borderRadius: 12, padding: 10, borderWidth: 1, borderColor: "#dc262630" }}>
                    <Text style={{ color: "#ef4444", fontSize: 12 }}>🗑️</Text>
                  </TouchableOpacity>
                </View>

                {/* Student info badges */}
                <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6, marginVertical: 12 }}>
                  {selectedStudent.experienceLevel && (
                    <View style={{ backgroundColor: "#ea580c20", borderRadius: 20, paddingHorizontal: 10, paddingVertical: 4 }}>
                      <Text style={{ color: "#ea580c", fontSize: 9, fontWeight: "800", textTransform: "uppercase" }}>{selectedStudent.experienceLevel}</Text>
                    </View>
                  )}
                  {selectedStudent.objective && (
                    <View style={{ backgroundColor: "#3b82f620", borderRadius: 20, paddingHorizontal: 10, paddingVertical: 4 }}>
                      <Text style={{ color: "#3b82f6", fontSize: 9, fontWeight: "800", textTransform: "uppercase" }}>{selectedStudent.objective}</Text>
                    </View>
                  )}
                  {selectedStudent.plan && (
                    <View style={{ backgroundColor: "#22c55e20", borderRadius: 20, paddingHorizontal: 10, paddingVertical: 4 }}>
                      <Text style={{ color: "#22c55e", fontSize: 9, fontWeight: "800", textTransform: "uppercase" }}>{selectedStudent.plan}</Text>
                    </View>
                  )}
                  {selectedStudent.weightKg && (
                    <View style={{ backgroundColor: "#27272a", borderRadius: 20, paddingHorizontal: 10, paddingVertical: 4 }}>
                      <Text style={{ color: "#a1a1aa", fontSize: 9, fontWeight: "800" }}>{selectedStudent.weightKg}kg</Text>
                    </View>
                  )}
                </View>

                {/* Weekly Plan */}
                <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
                  <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Plano semanal</Text>
                  {DAYS.map((d, dayIdx) => {
                    const dayExercises = studentPlan.filter((e) => e.dayOfWeek === dayIdx);
                    return (
                      <View key={dayIdx} style={{ marginBottom: 10 }}>
                        <Text style={{ fontSize: 11, fontWeight: "800", color: "#ea580c", textTransform: "uppercase", marginBottom: 4 }}>{d}</Text>
                        {dayExercises.length === 0 ? <Text style={{ fontSize: 10, color: "#52525b", marginLeft: 8 }}>—</Text> : dayExercises.map((ex) => (
                          <View key={ex.id} style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 4, paddingLeft: 8 }}>
                            <Text style={{ color: "#d4d4d8", fontSize: 12 }}>{ex.name}</Text>
                            <View style={{ flexDirection: "row", gap: 8 }}>
                              <Text style={{ color: "#71717a", fontSize: 11 }}>{ex.sets}x{ex.reps}{ex.load ? ` ${ex.load}kg` : ""}</Text>
                              <TouchableOpacity onPress={() => handleRemoveExercise(ex.id)}><Text style={{ color: "#ef4444", fontSize: 11 }}>✕</Text></TouchableOpacity>
                            </View>
                          </View>
                        ))}
                        <View style={{ flexDirection: "row", gap: 4, marginTop: 4, marginLeft: 8 }}>
                          <TextInput value={dayIdx === newEx.day ? newEx.name : ""} onChangeText={(t) => setNewEx({ ...newEx, name: t, day: dayIdx })} placeholder="Exercício" placeholderTextColor="#52525b" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 8, padding: 6, fontSize: 10, color: "#fff" }} />
                          <TextInput value={dayIdx === newEx.day ? newEx.sets : ""} onChangeText={(t) => setNewEx({ ...newEx, sets: t, day: dayIdx })} placeholder="S" keyboardType="numeric" style={{ width: 30, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 8, padding: 6, fontSize: 10, color: "#fff", textAlign: "center" }} />
                          <TextInput value={dayIdx === newEx.day ? newEx.reps : ""} onChangeText={(t) => setNewEx({ ...newEx, reps: t, day: dayIdx })} placeholder="R" keyboardType="numeric" style={{ width: 30, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 8, padding: 6, fontSize: 10, color: "#fff", textAlign: "center" }} />
                          <TouchableOpacity onPress={handleAddExercise} style={{ backgroundColor: "#ea580c", borderRadius: 8, padding: 6, justifyContent: "center" }}><Text style={{ color: "#fff", fontSize: 12 }}>+</Text></TouchableOpacity>
                        </View>
                      </View>
                    );
                  })}
                </View>

                {/* Evolution */}
                <View style={{ backgroundColor: "#18181b", borderWidth: 1, borderColor: "#27272a", borderRadius: 20, padding: 16, marginBottom: 16 }}>
                  <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 12 }}>Evolução</Text>
                  <View style={{ flexDirection: "row", gap: 6, marginBottom: 10 }}>
                    <TextInput value={newProgress.weight} onChangeText={(t) => setNewProgress({ ...newProgress, weight: t })} placeholder="Peso kg" keyboardType="decimal-pad" placeholderTextColor="#52525b" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 8, fontSize: 11, color: "#fff" }} />
                    <TextInput value={newProgress.muscleMass} onChangeText={(t) => setNewProgress({ ...newProgress, muscleMass: t })} placeholder="Massa kg" keyboardType="decimal-pad" placeholderTextColor="#52525b" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 8, fontSize: 11, color: "#fff" }} />
                    <TextInput value={newProgress.bodyFat} onChangeText={(t) => setNewProgress({ ...newProgress, bodyFat: t })} placeholder="% Gordura" keyboardType="decimal-pad" placeholderTextColor="#52525b" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 10, padding: 8, fontSize: 11, color: "#fff" }} />
                    <TouchableOpacity onPress={handleAddProgress} style={{ backgroundColor: "#ea580c", borderRadius: 10, padding: 8, justifyContent: "center" }}><Text style={{ color: "#fff", fontSize: 12 }}>+</Text></TouchableOpacity>
                  </View>
                  {studentProgress.map((p) => (
                    <View key={p.id} style={{ flexDirection: "row", justifyContent: "space-between", paddingVertical: 6, borderBottomWidth: 1, borderBottomColor: "#27272a" }}>
                      <Text style={{ color: "#a1a1aa", fontSize: 10 }}>{new Date(p.date).toLocaleDateString("pt-BR")}</Text>
                      <Text style={{ color: "#fff", fontSize: 11, fontWeight: "700" }}>{p.weight} kg{p.muscleMass ? ` / ${p.muscleMass} kg` : ""}{p.bodyFat ? ` / ${p.bodyFat}%` : ""}</Text>
                    </View>
                  ))}
                </View>
              </>
            )}

            {/* New Student Modal */}
            <Modal visible={showForm} animationType="slide" transparent>
              <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.7)", justifyContent: "flex-end" }}>
                <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 24, maxHeight: "85%" }}>
                  <ScrollView>
                    <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff", marginBottom: 16 }}>Novo Aluno</Text>
                    <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 8 }}>Dados pessoais</Text>
                    <TextInput value={form.name} onChangeText={(t) => setForm({ ...form, name: t })} placeholder="Nome *" placeholderTextColor="#71717a" style={inputStyle} />
                    <TextInput value={form.email} onChangeText={(t) => setForm({ ...form, email: t })} placeholder="Email *" placeholderTextColor="#71717a" autoCapitalize="none" style={inputStyle} />
                    <View style={{ flexDirection: "row", gap: 8 }}>
                      <TextInput value={form.phone} onChangeText={(t) => setForm({ ...form, phone: t })} placeholder="Telefone" placeholderTextColor="#71717a" style={{ ...inputStyle, flex: 1 }} />
                      <TextInput value={form.cpf} onChangeText={(t) => setForm({ ...form, cpf: t })} placeholder="CPF" placeholderTextColor="#71717a" style={{ ...inputStyle, flex: 1 }} />
                    </View>
                    <View style={{ flexDirection: "row", gap: 8 }}>
                      <TextInput value={form.birthDate} onChangeText={(t) => setForm({ ...form, birthDate: t })} placeholder="Nascimento" placeholderTextColor="#71717a" style={{ ...inputStyle, flex: 1 }} />
                      <TextInput value={form.gender} onChangeText={(t) => setForm({ ...form, gender: t })} placeholder="Sexo" placeholderTextColor="#71717a" style={{ ...inputStyle, flex: 1 }} />
                    </View>
                    <TextInput value={form.emergency} onChangeText={(t) => setForm({ ...form, emergency: t })} placeholder="Contato emergência" placeholderTextColor="#71717a" style={inputStyle} />

                    <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 8, marginTop: 8 }}>Treino</Text>
                    <View style={{ flexDirection: "row", gap: 8 }}>
                      <TextInput value={form.height} onChangeText={(t) => setForm({ ...form, height: t })} placeholder="Altura cm" keyboardType="numeric" placeholderTextColor="#71717a" style={{ ...inputStyle, flex: 1 }} />
                      <TextInput value={form.weight} onChangeText={(t) => setForm({ ...form, weight: t })} placeholder="Peso kg" keyboardType="decimal-pad" placeholderTextColor="#71717a" style={{ ...inputStyle, flex: 1 }} />
                    </View>
                    <View style={{ flexDirection: "row", gap: 8 }}>
                      <TextInput value={form.bodyFat} onChangeText={(t) => setForm({ ...form, bodyFat: t })} placeholder="% Gordura" keyboardType="decimal-pad" placeholderTextColor="#71717a" style={{ ...inputStyle, flex: 1 }} />
                      <TextInput value={form.availableDays} onChangeText={(t) => setForm({ ...form, availableDays: t })} placeholder="Dias disp. (ex: Seg,Qua,Sex)" placeholderTextColor="#71717a" style={{ ...inputStyle, flex: 1 }} />
                    </View>
                    <TextInput value={form.experienceLevel} onChangeText={(t) => setForm({ ...form, experienceLevel: t })} placeholder="Nível (iniciante/intermediario/avancado)" placeholderTextColor="#71717a" style={inputStyle} />
                    <TextInput value={form.objective} onChangeText={(t) => setForm({ ...form, objective: t })} placeholder="Objetivo principal" placeholderTextColor="#71717a" style={inputStyle} />
                    <TextInput value={form.plan} onChangeText={(t) => setForm({ ...form, plan: t })} placeholder="Plano" placeholderTextColor="#71717a" style={inputStyle} />

                    <Text style={{ fontSize: 9, fontWeight: "900", textTransform: "uppercase", letterSpacing: 1, color: "#71717a", marginBottom: 8, marginTop: 8 }}>Saúde</Text>
                    <TextInput value={form.restrictions} onChangeText={(t) => setForm({ ...form, restrictions: t })} placeholder="Restrições" placeholderTextColor="#71717a" style={inputStyle} />
                    <TextInput value={form.injuries} onChangeText={(t) => setForm({ ...form, injuries: t })} placeholder="Lesões" placeholderTextColor="#71717a" style={inputStyle} />
                    <TextInput value={form.medications} onChangeText={(t) => setForm({ ...form, medications: t })} placeholder="Medicamentos" placeholderTextColor="#71717a" style={inputStyle} />
                    <TextInput value={form.observations} onChangeText={(t) => setForm({ ...form, observations: t })} placeholder="Observações" placeholderTextColor="#71717a" multiline style={{ ...inputStyle, minHeight: 60 }} />

                    <View style={{ flexDirection: "row", gap: 12, marginTop: 8 }}>
                      <TouchableOpacity onPress={() => setShowForm(false)} style={{ flex: 1, backgroundColor: "#27272a", borderRadius: 14, padding: 14, alignItems: "center" }}>
                        <Text style={{ color: "#a1a1aa", fontSize: 12, fontWeight: "800", textTransform: "uppercase" }}>Cancelar</Text>
                      </TouchableOpacity>
                      <TouchableOpacity onPress={handleRegister} style={{ flex: 1, backgroundColor: "#ea580c", borderRadius: 14, padding: 14, alignItems: "center" }}>
                        <Text style={{ color: "#fff", fontSize: 12, fontWeight: "900", textTransform: "uppercase" }}>Salvar</Text>
                      </TouchableOpacity>
                    </View>
                  </ScrollView>
                </View>
              </View>
            </Modal>

            {/* AI Copilot Modal */}
            <Modal visible={showCopilot} animationType="slide" transparent>
              <View style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.85)", justifyContent: "flex-end" }}>
                <View style={{ backgroundColor: "#18181b", borderTopLeftRadius: 24, borderTopRightRadius: 24, height: "60%", padding: 16 }}>
                  <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
                    <Text style={{ fontSize: 16, fontWeight: "900", fontStyle: "italic", color: "#fff" }}>Copilot IA</Text>
                    <TouchableOpacity onPress={() => { setShowCopilot(false); setCopilotReply(""); }}><Text style={{ color: "#71717a", fontSize: 18 }}>✕</Text></TouchableOpacity>
                  </View>
                  <ScrollView style={{ flex: 1 }}>
                    {!copilotReply && !copilotLoading && (
                      <View style={{ alignItems: "center", paddingTop: 32 }}>
                        <Text style={{ fontSize: 36, marginBottom: 8 }}>🤖</Text>
                        <Text style={{ color: "#71717a", fontSize: 13, textAlign: "center" }}>Pergunte sobre treinos, periodização, lesões...</Text>
                      </View>
                    )}
                    {copilotLoading && <ActivityIndicator size="large" color="#7c3aed" />}
                    {copilotReply && (
                      <View style={{ backgroundColor: "#27272a", borderRadius: 16, padding: 16 }}>
                        <Text style={{ color: "#fff", fontSize: 13, lineHeight: 20 }}>{copilotReply}</Text>
                      </View>
                    )}
                  </ScrollView>
                  <View style={{ flexDirection: "row", gap: 8, paddingTop: 12, borderTopWidth: 1, borderTopColor: "#27272a" }}>
                    <TextInput value={copilotInput} onChangeText={setCopilotInput} placeholder="Ex: crie um treino para iniciante..." placeholderTextColor="#71717a" style={{ flex: 1, backgroundColor: "#09090b", borderWidth: 1, borderColor: "#3f3f46", borderRadius: 14, paddingHorizontal: 14, paddingVertical: 10, fontSize: 13, color: "#fff" }} />
                    <TouchableOpacity onPress={handleCopilot} disabled={!copilotInput.trim() || copilotLoading} style={{ backgroundColor: copilotInput.trim() && !copilotLoading ? "#7c3aed" : "#27272a", borderRadius: 14, padding: 12, justifyContent: "center" }}>
                      <Text style={{ color: "#fff", fontSize: 14 }}>➤</Text>
                    </TouchableOpacity>
                  </View>
                </View>
              </View>
            </Modal>
          </View>
        </ScrollView>
      </View>
    </>
  );
}
