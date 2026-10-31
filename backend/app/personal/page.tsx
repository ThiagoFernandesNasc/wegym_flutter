"use client";

export const dynamic = 'force-dynamic';

import React, { useMemo, useState, useEffect, useCallback } from 'react';
import { useSearchParams } from 'next/navigation';
import { AnimatePresence } from 'framer-motion';
import { AuthGuard } from '@/components/auth/AuthGuard';
import { OnboardingTutorial } from '@/components/onboarding/OnboardingTutorial';
import { useTranslations } from '@/lib/i18n/hook';
import { logger } from '@/lib/logger';
import { toast } from "sonner";
import { Student, WeeklyClass } from '@/types/personal';
import { INITIAL_STUDENTS, INITIAL_WEEKLY_CLASSES } from '@/mocks/personalData';
import { OTHER_DAYS_PREFIX } from '@/constants/options';

import { PersonalHeader } from '@/components/personal/PersonalHeader';
import { NewStudentForm } from '@/components/personal/NewStudentForm';
import { StatsBar } from '@/components/personal/StatsBar';
import { StudentsList } from '@/components/personal/StudentsList';
import { AgendaItem } from '@/components/personal/AgendaItem';
import { StudentProfile } from '@/components/personal/StudentProfile';
import { PersonalSidebar } from '@/components/personal/PersonalSidebar';
import { PersonalChat } from '@/components/personal/PersonalChat';

const createEmptyStudentForm = () => ({
  id: '', name: '', email: '', cpf: '', birthDate: '', phone: '', gender: '',
  emergencyContact: '', experience: '', objective: '', plan: '', height: '',
  weight: '', availableDays: '', notes: '', bodyFat: '', restrictions: '',
  injuries: '', medications: '', observations: '',
});

export default function PersonalDashboard() {
  const searchParams = useSearchParams();
  const { t } = useTranslations();
  const [activeMobileTab, setActiveMobileTab] = useState<'home' | 'students' | 'create'>('home');
  const [csrfToken, setCsrfToken] = useState<string>("");

  const [students, setStudents] = useState<Student[]>(INITIAL_STUDENTS);
  const [cursor, setCursor] = useState<string | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasMore, setHasMore] = useState(true);

  const [weeklyClasses, setWeeklyClasses] = useState<WeeklyClass[]>(INITIAL_WEEKLY_CLASSES);
  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(null);

  const [showNewStudentForm, setShowNewStudentForm] = useState(false);
  const [newStudent, setNewStudent] = useState(createEmptyStudentForm());

  const [showExerciseForm, setShowExerciseForm] = useState(false);
  const [exerciseToAdd, setExerciseToAdd] = useState({ day: 'Seg', name: '', sets: '', reps: '', load: '' });

  const [historyInput, setHistoryInput] = useState({ date: '', weight: '', muscleMass: '', bodyFat: '', note: '' });

  const [isChatOpen, setIsChatOpen] = useState(false);
  const [input, setInput] = useState('');
  const [messages, setMessages] = useState<{ role: string; content: string }[]>([]);
  const [loading, setLoading] = useState(false);

  const [studentsSearch, setStudentsSearch] = useState('');
  const [dashboardStats, setDashboardStats] = useState({ activeStudents: 0, classesPerWeek: 0 });

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const res = await fetch('/api/personal-stats');
        if (res.ok) {
          const data = await res.json();
          if (data.data) setDashboardStats(data.data);
        }
      } catch {}
    };
    fetchStats();
  }, []);

  const selectedStudent = useMemo(
    () => students.find((student) => student.id === selectedStudentId) ?? null,
    [students, selectedStudentId]
  );

  const safeNewStudent = useMemo(
    () => ({ ...createEmptyStudentForm(), ...newStudent }),
    [newStudent]
  );

  const filteredStudents = useMemo(() => {
    const q = studentsSearch.trim().toLowerCase();
    if (!q) return students;
    return students.filter((s) =>
      [s.name, s.objective, s.experience, s.plan]
        .filter(Boolean)
        .some((field) => String(field).toLowerCase().includes(q))
    );
  }, [students, studentsSearch]);

  useEffect(() => {
    const controller = new AbortController();
    const fetchClasses = async () => {
      try {
        const res = await fetch('/api/classes', { signal: controller.signal, cache: 'no-store' });
        if (!res.ok) return;
        const data = await res.json();
        type RawClass = { id: string; studentId: string; day: string; date: string; time: string; type: string; status: string };
        const formatted = (Array.isArray(data) ? data : data.data ?? []).map((c: RawClass) => ({
          id: c.id, studentId: c.studentId, day: c.day, date: c.date, time: c.time, type: c.type, status: c.status,
        }));
        setWeeklyClasses(formatted);
      } catch (err) {
        logger.error({ err }, "Erro ao buscar aulas");
      }
    };
    fetchClasses();
    return () => controller.abort();
  }, []);

  type AthleteAPI = {
    id: string; name: string; experienceLevel?: string;
    trainingPlans?: { day: string; exercises: unknown[] }[];
    progressEntries?: { date: string; weight: string; muscleMass: string; bodyFat: string; note: string }[];
  };

  const formatAthlete = useCallback((a: AthleteAPI) => ({
    id: a.id, name: a.name, email: '', phone: '', birthDate: '', gender: '',
    emergencyContact: '', objective: '', restrictions: '', injuries: '',
    medications: '', experience: a.experienceLevel ?? '', availableDays: '',
    height: '', weight: '', bodyFat: '', observations: '', lastTraining: 'Recente',
    plan: 'Basic', progress: 0,
    weeklyPlan: (a.trainingPlans ?? []).reduce<Record<string, unknown[]>>((acc, plan) => {
      acc[plan.day] = plan.exercises ?? [];
      return acc;
    }, { Seg: [], Ter: [], Qua: [], Qui: [], Sex: [], Sab: [], Dom: [] }),
    progressHistory: (a.progressEntries ?? []).map((p) => ({
      date: p.date ?? '', weight: p.weight ?? '', muscleMass: p.muscleMass ?? '',
      bodyFat: p.bodyFat ?? '', note: p.note ?? '',
    })),
  }), []);

  useEffect(() => {
    const controller = new AbortController();
    const fetchStudents = async () => {
      try {
        const res = await fetch('/api/athletes', { cache: 'no-store', signal: controller.signal });
        if (!res.ok) return;
        const data = await res.json();
        const formatted = (data.data ?? []).map(formatAthlete);
        setStudents(formatted);
        setCursor(data.nextCursor ?? null);
        setHasMore(!!data.nextCursor);
      } catch (err) {
        logger.error({ err }, "Erro ao buscar alunos");
      }
    };
    fetchStudents();
    return () => controller.abort();
  }, [formatAthlete]);

  useEffect(() => {
    const handleScroll = async () => {
      if (loadingMore || !hasMore || !cursor) return;
      if (window.innerHeight + window.scrollY >= document.body.offsetHeight - 200) {
        setLoadingMore(true);
        try {
          const res = await fetch(`/api/athletes?cursor=${cursor}`, { cache: 'no-store' });
          if (!res.ok) return;
          const data = await res.json();
          const formatted = (data.data ?? []).map(formatAthlete);
          setStudents((prev) => [...prev, ...formatted]);
          setCursor(data.nextCursor ?? null);
          setHasMore(!!data.nextCursor);
        } catch (err) {
          logger.error({ err }, "Erro ao carregar mais alunos");
        }
        setLoadingMore(false);
      }
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, [cursor, loadingMore, hasMore, formatAthlete]);

  useEffect(() => {
    const view = searchParams.get('view');
    if (view === 'students') {
      setShowNewStudentForm(false);
      setShowExerciseForm(false);
      setIsChatOpen(false);
      setActiveMobileTab('students');
    } else if (view === 'create') {
      setSelectedStudentId(null);
      setShowExerciseForm(false);
      setIsChatOpen(false);
      setShowNewStudentForm(true);
      setNewStudent((prev) => ({ ...createEmptyStudentForm(), ...prev }));
      setActiveMobileTab('create');
    } else if (view === 'home') {
      setShowNewStudentForm(false);
      setSelectedStudentId(null);
      setShowExerciseForm(false);
      setIsChatOpen(false);
      setActiveMobileTab('home');
    }
  }, [searchParams]);

  useEffect(() => {
    const getCsrfToken = async () => {
      const res = await fetch('/api/csrf', { credentials: 'include' });
      const data = await res.json();
      setCsrfToken(data.csrfToken || '');
    };
    getCsrfToken();
  }, []);

  const openStudentProfile = (studentId: string) => {
    setSelectedStudentId(studentId);
    setShowExerciseForm(false);
    setShowNewStudentForm(false);
    setActiveMobileTab('students');
  };

  const handleAddStudent = () => {
    setShowNewStudentForm(true);
    setNewStudent((prev) => ({ ...createEmptyStudentForm(), ...prev }));
    setSelectedStudentId(null);
    setActiveMobileTab('create');
  };

  const handleResetView = () => {
    setShowNewStudentForm(false);
    setSelectedStudentId(null);
    setShowExerciseForm(false);
    setIsChatOpen(false);
    setActiveMobileTab('home');
  };

  const createStudent = async () => {
    const availableDaysValue = Array.isArray(newStudent.availableDays)
      ? newStudent.availableDays.join(' ')
      : String(newStudent.availableDays ?? '');
    const hasValidAvailableDays = availableDaysValue.startsWith(OTHER_DAYS_PREFIX)
      ? availableDaysValue.replace(OTHER_DAYS_PREFIX, '').trim().length > 0
      : availableDaysValue.length > 0;

    if (!newStudent.name || !newStudent.cpf || !newStudent.phone ||
      !newStudent.birthDate || !newStudent.gender || !newStudent.objective ||
      !newStudent.experience || !hasValidAvailableDays) return;

    try {
      const res = await fetch('/api/athletes/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken },
        body: JSON.stringify({
          email: newStudent.email || `${Date.now()}@temp.com`,
          name: newStudent.name, cpf: newStudent.cpf,
          birthDate: newStudent.birthDate || undefined,
          sex: newStudent.gender.toLowerCase(),
          heightCm: Number(newStudent.height) * 100,
          weightKg: Number(newStudent.weight),
          experienceLevel: newStudent.experience.toLowerCase(),
          city: 'Não informado', state: 'Não informado', cep: '00000-000',
        }),
      });
      if (!res.ok) { const err = await res.json(); throw new Error(err.error); }
      const data = await res.json();
      const studentId = data?.athlete?.id ?? `s${Date.now()}`;
      const student: Student = {
        ...newStudent, id: studentId, lastTraining: 'Novo', progress: 0,
        weeklyPlan: { Seg: [], Ter: [], Qua: [], Qui: [], Sex: [], Sab: [], Dom: [] },
        progressHistory: [],
      };
      setStudents((prev) => [student, ...prev]);
      setNewStudent(createEmptyStudentForm());
      setShowNewStudentForm(false);
      setSelectedStudentId(studentId);
    } catch (err) {
      toast.error((err as Error).message || 'Erro ao cadastrar atleta');
    }
  };

  const updateSelectedStudentField = (field: keyof Student, value: string) => {
    if (!selectedStudentId) return;
    setStudents((prev) =>
      prev.map((s) => s.id === selectedStudentId ? { ...s, [field]: value } : s)
    );
  };

  const deleteSelectedStudent = () => {
    if (!selectedStudentId) return;
    if (!window.confirm(t('personal.confirmDeleteStudent'))) return;
    setStudents((prev) => prev.filter((s) => s.id !== selectedStudentId));
    setWeeklyClasses((prev) => prev.filter((item) => item.studentId !== selectedStudentId));
    setSelectedStudentId(null);
  };

  const addExerciseToSelectedStudent = async () => {
    if (!selectedStudentId || !exerciseToAdd.name || !exerciseToAdd.sets || !exerciseToAdd.reps) return;
    try {
      await fetch('/api/training-plans', {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken },
        body: JSON.stringify({
          athleteId: selectedStudentId, day: exerciseToAdd.day,
          exercises: [{ name: exerciseToAdd.name, sets: exerciseToAdd.sets, reps: exerciseToAdd.reps, load: exerciseToAdd.load || '0' }],
        }),
      });
    } catch {}
    setStudents((prev) =>
      prev.map((s) => {
        if (s.id !== selectedStudentId) return s;
        const updatedPlan = { ...s.weeklyPlan };
        const dayExercises = [...(updatedPlan[exerciseToAdd.day] ?? [])];
        dayExercises.push({ name: exerciseToAdd.name, sets: exerciseToAdd.sets || '-', reps: exerciseToAdd.reps || '-', load: exerciseToAdd.load || '-' });
        updatedPlan[exerciseToAdd.day] = dayExercises;
        return { ...s, weeklyPlan: updatedPlan };
      })
    );
    setExerciseToAdd({ day: 'Seg', name: '', sets: '', reps: '', load: '' });
  };

  const removeExercise = (day: string, idx: number) => {
    if (!selectedStudentId) return;
    setStudents((prev) =>
      prev.map((s) => {
        if (s.id !== selectedStudentId) return s;
        const updatedPlan = { ...s.weeklyPlan };
        const dayExercises = [...(updatedPlan[day] ?? [])];
        dayExercises.splice(idx, 1);
        updatedPlan[day] = dayExercises;
        return { ...s, weeklyPlan: updatedPlan };
      })
    );
  };

  const addHistoryEntry = async () => {
    if (!selectedStudentId || !historyInput.date || !historyInput.weight) return;
    try {
      await fetch('/api/progress', {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken },
        body: JSON.stringify({
          athleteId: selectedStudentId, date: historyInput.date,
          weight: Number(historyInput.weight),
          muscleMass: historyInput.muscleMass ? Number(historyInput.muscleMass) : undefined,
          bodyFat: historyInput.bodyFat ? Number(historyInput.bodyFat) : undefined,
          note: historyInput.note || undefined,
        }),
      });
    } catch {}
    setStudents((prev) =>
      prev.map((s) =>
        s.id === selectedStudentId
          ? { ...s, progressHistory: [{ ...historyInput, date: historyInput.date || new Date().toISOString().split('T')[0] }, ...s.progressHistory] }
          : s
      )
    );
    setHistoryInput({ date: '', weight: '', muscleMass: '', bodyFat: '', note: '' });
  };

  const handleChat = async () => {
    if (!input.trim()) return;
    const userMsg = { role: 'user', content: input };
    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setLoading(true);
    try {
      const res = await fetch('/api/chat', {
        method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken },
        body: JSON.stringify({ message: input }),
      });
      const data = await res.json();
      setMessages((prev) => [...prev, { role: 'assistant', content: data.text }]);
    } catch {
      setMessages((prev) => [...prev, { role: 'assistant', content: "Houve um erro na conexão, mas gerei um treino padrão para você continuar." }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthGuard allowedRoles={['personal']}>
      <OnboardingTutorial role="personal" />
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-24 relative overflow-hidden antialiased font-sans">
        <div className="fixed top-[-10%] left-[-5%] w-96 h-96 bg-orange-600/5 rounded-full blur-[120px] pointer-events-none" />

        <PersonalHeader onAddStudent={handleAddStudent} />

        <main className="max-w-6xl mx-auto px-4 pt-8">
          {showNewStudentForm && (
            <NewStudentForm form={safeNewStudent} onSetForm={setNewStudent} onSave={createStudent} onCancel={() => setShowNewStudentForm(false)} />
          )}

          <StatsBar activeStudents={dashboardStats.activeStudents} classesPerWeek={dashboardStats.classesPerWeek} studentsCount={students.length} />

          <div className={`grid grid-cols-1 gap-8 ${activeMobileTab === 'students' && !selectedStudent ? '' : 'lg:grid-cols-3'}`}>
            <div className={`space-y-6 ${activeMobileTab === 'students' && !selectedStudent ? '' : 'lg:col-span-2'}`}>
              <AnimatePresence mode="wait">
                {!selectedStudent && activeMobileTab === 'students' ? (
                  <StudentsList students={students} filteredStudents={filteredStudents} studentsSearch={studentsSearch}
                    onSelectStudent={openStudentProfile} onSetSearch={setStudentsSearch} onAddStudent={handleAddStudent} />
                ) : !selectedStudent ? (
                  <div key="agenda" className="space-y-6">
                    <h2 className="text-2xl font-black italic uppercase text-white tracking-tighter">Agenda Semanal</h2>
                    <div className="space-y-3">
                      {weeklyClasses.map((item) => {
                        const student = students.find((s) => s.id === item.studentId);
                        if (!student) return null;
                        return <AgendaItem key={item.id} item={item} studentName={student.name} onOpenStudent={() => openStudentProfile(student.id)} />;
                      })}
                    </div>
                  </div>
                ) : selectedStudent ? (
                  <StudentProfile student={selectedStudent} showExerciseForm={showExerciseForm} exerciseToAdd={exerciseToAdd}
                    historyInput={historyInput} onSetShowExerciseForm={setShowExerciseForm} onSetExerciseToAdd={setExerciseToAdd}
                    onSetHistoryInput={setHistoryInput} onUpdateField={updateSelectedStudentField}
                    onAddExercise={addExerciseToSelectedStudent} onRemoveExercise={removeExercise}
                    onAddHistoryEntry={addHistoryEntry} onDelete={deleteSelectedStudent} onClose={() => setSelectedStudentId(null)} />
                ) : null}
              </AnimatePresence>
            </div>

            {!(activeMobileTab === 'students' && !selectedStudent) && (
              <PersonalSidebar students={students} onSelectStudent={openStudentProfile} onOpenChat={() => setIsChatOpen(true)} />
            )}
          </div>
        </main>

        <PersonalChat isOpen={isChatOpen} messages={messages} input={input} loading={loading}
          onSetInput={setInput} onSend={handleChat} onClose={() => setIsChatOpen(false)} />
      </div>
    </AuthGuard>
  );
}
