"use client";

export const dynamic = 'force-dynamic';

import "leaflet/dist/leaflet.css";
import React, { useState, useEffect, useMemo, useCallback, useRef, startTransition } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { AnimatePresence } from 'framer-motion';
import { BluetoothManager, type HRData, type ConnectionState } from '@/lib/bluetooth';
import { MODALITY_OPTIONS } from '@/constants/modalities';
import { MODALITY_STORAGE_KEY } from '@/constants/keys';
import { ALL_AVAILABLE_EXERCISES } from '@/constants/exercises';
import { INITIAL_WEEKLY_PLAN } from '@/constants/plans';
import type { DayPlan, TrainingModalityId, ModalitySessionEntry, AIChatMessage, Exercise } from '@/types/training';
import { parseKmInput } from '@/utils/training-helpers';
import { AuthGuard } from '@/components/auth/AuthGuard';
import { useGpsTracker } from '@/hooks/use-gps-tracker';
import GpsSessionResult from '@/components/training/GpsSessionResult';
import { ParallaxField } from '@/components/ui/ParallaxField';
import { useTranslations } from '@/lib/i18n/hook';
import { TrainingHeader } from '@/components/training/TrainingHeader';
import { DaySelector } from '@/components/training/DaySelector';
import { GymSidebar } from '@/components/training/GymSidebar';
import { GymExerciseList } from '@/components/training/GymExerciseList';
import { ModalityHistory } from '@/components/training/ModalityHistory';
import dyn from 'next/dynamic';

const AiWorkoutModal = dyn(
  () => import('@/components/training/AiWorkoutModal').then(mod => mod.AiWorkoutModal),
  { ssr: false }
);
import { ChatPanel } from '@/components/training/ChatPanel';
import { FloatingChatButton } from '@/components/training/FloatingChatButton';
import { NonGymSession } from '@/components/training/NonGymSession';

const DAY_TKEY_MAP: Record<string, string> = {
  "Seg": "days.mon", "Ter": "days.tue", "Qua": "days.wed",
  "Qui": "days.thu", "Sex": "days.fri", "Sáb": "days.sat", "Dom": "days.sun",
};

const TARGET_TKEY_MAP: Record<string, string> = {
  "Push": "planDayTarget.push", "Pull": "planDayTarget.pull",
  "Legs": "planDayTarget.legs", "Cardio e Core": "planDayTarget.cardioCore",
  "Upper Body": "planDayTarget.upperBody", "Lower Body": "planDayTarget.lowerBody",
  "Descanso": "planDayTarget.rest",
};

export default function TrainingPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t } = useTranslations();
  const progressBarRef = useRef<HTMLDivElement>(null);

  const [activeDay, setActiveDay] = useState(new Date().getDay());
  const [showAI, setShowAI] = useState(false);
  const [userPlans, setUserPlans] = useState<DayPlan[]>(INITIAL_WEEKLY_PLAN);
  const [completedIds, setCompletedIds] = useState<string[]>([]);
  const [timeLeft, setTimeLeft] = useState(60);
  const [timerActive, setTimerActive] = useState(false);

  const modalityParam = searchParams.get('modality');
  const trainingModality: TrainingModalityId = (
    modalityParam && MODALITY_OPTIONS.some((m) => m.id === modalityParam)
      ? (modalityParam as TrainingModalityId) : 'gym'
  );

  const [sessionSec, setSessionSec] = useState(0);
  const [sessionRun, setSessionRun] = useState(false);
  const [distanceKm, setDistanceKm] = useState('');
  const [, setPaceChoice] = useState<'min' | 'max' | null>(null);
  const [sessionCountdownActive, setSessionCountdownActive] = useState(false);
  const [initialCountdownSec, setInitialCountdownSec] = useState(0);
  const [modalityHistory, setModalityHistory] = useState<Partial<Record<TrainingModalityId, ModalitySessionEntry[]>>>({
    gym: [], cycling: [], running: [], aerobic: [], combat: [],
  });

  const [useGpsMode] = useState(true);
  const [showGpsResult, setShowGpsResult] = useState(false);
  const [targetKm, setTargetKm] = useState<number>(0);
  const [selectedTarget, setSelectedTarget] = useState<'min' | 'avg' | 'max' | null>(null);
  const GPS_MODALITIES: TrainingModalityId[] = ['running', 'walking', 'hiking', 'cycling'];
  const isGpsModality = GPS_MODALITIES.includes(trainingModality);
  const isSwimming = trainingModality === 'swimming';
  const gps = useGpsTracker(trainingModality);

  const targetTimes = useMemo(() => {
    const PACE: Record<string, { minSecPerKm: number; avgSecPerKm: number; maxSecPerKm: number }> = {
      running: { minSecPerKm: 270, avgSecPerKm: 345, maxSecPerKm: 420 },
      walking: { minSecPerKm: 480, avgSecPerKm: 600, maxSecPerKm: 720 },
      hiking: { minSecPerKm: 360, avgSecPerKm: 480, maxSecPerKm: 600 },
      cycling: { minSecPerKm: 112, avgSecPerKm: 144, maxSecPerKm: 200 },
    };
    if (!isGpsModality || targetKm <= 0) return null;
    const pace = PACE[trainingModality];
    if (!pace) return null;
    return {
      minSec: Math.round(targetKm * pace.minSecPerKm),
      avgSec: Math.round(targetKm * pace.avgSecPerKm),
      maxSec: Math.round(targetKm * pace.maxSecPerKm),
    };
  }, [isGpsModality, targetKm, trainingModality]);

  const targetPaceSec = useMemo(() => {
    if (!selectedTarget || !targetTimes || targetKm <= 0) return null;
    return Math.round(targetTimes[`${selectedTarget}Sec`] / targetKm);
  }, [selectedTarget, targetTimes, targetKm]);

  const [poolLengthM, setPoolLengthM] = useState(25);
  const [lapCount, setLapCount] = useState(0);

  const [chatOpen, setChatOpen] = useState(false);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);
  const [bleState, setBleState] = useState<ConnectionState>("idle");
  const [lastHR, setLastHR] = useState<HRData | null>(null);
  const btRef = useRef<BluetoothManager | null>(null);
  const [aiLoading, setAiLoading] = useState(false);
  const [, setAiResponse] = useState('');
  const [aiStep, setAiStep] = useState<'workout_goal' | 'add_manual' | 'result'>('workout_goal');
  const [chatMessages, setChatMessages] = useState<AIChatMessage[]>([
    { role: 'ai', text: t('training.chatInitialMessage') }
  ]);

  const currentModalityMeta = useMemo(
    () => MODALITY_OPTIONS.find((m) => m.id === trainingModality) ?? MODALITY_OPTIONS[0],
    [trainingModality],
  );
  const currentPlan = useMemo(() => userPlans[activeDay], [userPlans, activeDay]);
  const progressPercentage = useMemo(() => {
    const totalExercises = currentPlan.exercises.length;
    if (totalExercises === 0) return 0;
    const completedExercises = currentPlan.exercises.filter(ex => ex.id && completedIds.includes(ex.id)).length;
    return Math.round((completedExercises / totalExercises) * 100);
  }, [currentPlan.exercises, completedIds]);

  useEffect(() => { router.prefetch('/profile'); }, [router]);

  useEffect(() => {
    startTransition(() => {
      try {
        const raw = localStorage.getItem(MODALITY_STORAGE_KEY);
        if (!raw) return;
        const parsed = JSON.parse(raw) as Record<string, ModalitySessionEntry[]>;
        setModalityHistory({
          gym: parsed.gym ?? [], cycling: parsed.cycling ?? [],
          running: parsed.running ?? [], aerobic: parsed.aerobic ?? [], combat: parsed.combat ?? [],
        });
      } catch {}
    });
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem(MODALITY_STORAGE_KEY, JSON.stringify({
        gym: modalityHistory.gym, cycling: modalityHistory.cycling,
        running: modalityHistory.running, aerobic: modalityHistory.aerobic, combat: modalityHistory.combat,
      }));
    } catch {}
  }, [modalityHistory]);

  useEffect(() => {
    if (progressBarRef.current) progressBarRef.current.style.width = `${progressPercentage}%`;
  }, [progressPercentage]);

  useEffect(() => {
    if (!timerActive) return;
    const id = setInterval(() => {
      setTimeLeft((tl) => { if (tl <= 1) { setTimerActive(false); return 0; } return tl - 1; });
    }, 1000);
    return () => clearInterval(id);
  }, [timerActive]);

  useEffect(() => {
    if (!sessionRun || trainingModality === 'gym') return;
    const isCountdownMode = (trainingModality === 'running' || trainingModality === 'cycling') && sessionCountdownActive;
    if (isCountdownMode) {
      const id = setInterval(() => {
        setSessionSec((s) => { if (s <= 1) { setSessionRun(false); return 0; } return s - 1; });
      }, 1000);
      return () => clearInterval(id);
    }
    const id = setInterval(() => { setSessionSec((s) => s + 1); }, 1000);
    return () => clearInterval(id);
  }, [sessionRun, trainingModality, sessionCountdownActive]);

  useEffect(() => {
    if (trainingModality === 'gym') return;
    startTransition(() => {
      setSessionRun(false); setSessionSec(0); setDistanceKm('');
      setPaceChoice(null); setSelectedTarget(null);
      setSessionCountdownActive(false); setInitialCountdownSec(0);
    });
  }, [trainingModality]);

  const toggleExercise = useCallback((id: string) => {
    setCompletedIds(prev => prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]);
  }, []);

  const addExerciseToPlan = useCallback((exercise: Exercise) => {
    const newEx = { ...exercise, id: Math.random().toString(36).substr(2, 9) };
    startTransition(() => {
      setUserPlans(prev => prev.map((p, i) => i === activeDay ? { ...p, exercises: [...p.exercises, newEx] } : p));
      setShowAI(false);
    });
  }, [activeDay]);

  const saveModalityEntry = useCallback(async (entry: ModalitySessionEntry) => {
    setModalityHistory((prev) => ({
      ...prev,
      [trainingModality]: [entry, ...(prev[trainingModality] ?? [])].slice(0, 50),
    }));
    try {
      await fetch('/api/workout-sessions', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          modality: trainingModality, durationSec: entry.durationSec,
          distanceKm: entry.distanceKm, avgPaceSecPerKm: entry.avgPaceSecPerKm, steps: entry.steps,
        }),
      });
    } catch {}
  }, [trainingModality]);

  const finalizeModalitySession = useCallback(() => {
    if (trainingModality === 'gym') return;
    if (isGpsModality && gps.gpsState === 'tracking') { gps.stopGps(); setShowGpsResult(true); return; }
    if (isSwimming) {
      if (sessionSec === 0) return;
      const distKm = (lapCount * poolLengthM) / 1000;
      saveModalityEntry({
        id: Math.random().toString(36).slice(2, 12), at: new Date().toISOString(),
        durationSec: sessionSec, ...(lapCount > 0 ? { distanceKm: distKm } : {}),
      });
      setSessionSec(0); setSessionRun(false); setLapCount(0); return;
    }
    const distN = parseKmInput(distanceKm);
    const isCountdown = (trainingModality === 'running' || trainingModality === 'cycling') && sessionCountdownActive;
    const durationSec = isCountdown ? initialCountdownSec - sessionSec : sessionSec;
    if (durationSec <= 0) return;
    saveModalityEntry({
      id: Math.random().toString(36).slice(2, 12), at: new Date().toISOString(), durationSec,
      ...(currentModalityMeta.showDistance && distN != null ? { distanceKm: distN } : {}),
    });
    setSessionSec(0); setSessionRun(false); setDistanceKm(''); setPaceChoice(null);
    setSessionCountdownActive(false); setInitialCountdownSec(0);
  }, [trainingModality, isGpsModality, isSwimming, gps, lapCount, poolLengthM, sessionSec, distanceKm, currentModalityMeta.showDistance, sessionCountdownActive, initialCountdownSec, saveModalityEntry]);

  const handleSaveGpsSession = useCallback(async () => {
    const snap = gps.gpsSnapshot;
    if (!snap) return;
    saveModalityEntry({
      id: Math.random().toString(36).slice(2, 12), at: new Date().toISOString(),
      durationSec: snap.durationSec, distanceKm: snap.distanceKm,
      avgPaceSecPerKm: snap.avgPaceSecPerKm, steps: snap.steps, coordinates: snap.coordinates,
    });
    try {
      await fetch('/api/gps-sessions', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          modality: trainingModality, distanceKm: snap.distanceKm,
          durationSec: snap.durationSec, avgPaceSecPerKm: snap.avgPaceSecPerKm, steps: snap.steps,
        }),
      });
    } catch {}
    setShowGpsResult(false); gps.resetGps(); setSessionSec(0); setSessionRun(false);
  }, [gps, saveModalityEntry, trainingModality]);

  const handleDiscardGpsSession = useCallback(() => {
    setShowGpsResult(false); gps.resetGps(); setSessionSec(0); setSessionRun(false);
  }, [gps]);

  const toggleBLE = useCallback(() => {
    if (bleState === "connected" && btRef.current) { btRef.current.disconnect(); setLastHR(null); return; }
    const manager = new BluetoothManager({
      onHR: (data: HRData) => setLastHR(data),
      onState: (state: ConnectionState) => setBleState(state),
      onDevice: () => {}, onError: () => {},
    }, t);
    btRef.current = manager;
    manager.scan();
  }, [bleState, t]);

  useEffect(() => { return () => { btRef.current?.disconnect(); }; }, []);

  const sendChatMessage = useCallback(async () => {
    if (!chatInput.trim()) return;
    const userMessage = chatInput.trim();
    setChatMessages(prev => [...prev, { role: 'user', text: userMessage }]);
    setChatInput(''); setChatLoading(true);
    try {
      const res = await fetch('/api/chat', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: userMessage }),
      });
      const data = await res.json();
      setChatMessages(prev => [...prev, { role: 'ai', text: data.text ?? t('training.chatError') }]);
    } catch {
      setChatMessages(prev => [...prev, { role: 'ai', text: t('training.chatConnectionError') }]);
    }
    setChatLoading(false);
  }, [chatInput, t]);

  const generateAIWorkout = useCallback(async (goal: 'cut' | 'bulk') => {
    setAiLoading(true);
    await new Promise(resolve => setTimeout(resolve, 1000));
    setUserPlans(INITIAL_WEEKLY_PLAN.map(plan => {
      if (plan.day === "Dom") return plan;
      return {
        ...plan,
        target: `${goal === 'bulk' ? 'HIPERTROFIA' : 'DEFINIÇÃO'} - ${plan.target}`,
        exercises: ALL_AVAILABLE_EXERCISES.filter(ex => plan.muscles.some((m: string) => ex.muscle === m))
          .map(ex => ({ ...ex, id: Math.random().toString(36).substr(2, 9), sets: goal === 'bulk' ? 4 : 3, reps: goal === 'bulk' ? "8-12" : "15-20" })),
      };
    }));
    setAiResponse(t('training.planBulkApplied'));
    setAiStep('result'); setAiLoading(false);
  }, [t]);

  return (
    <AuthGuard allowedRoles={['atleta']}>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-24 relative overflow-hidden antialiased font-sans">
        <FloatingChatButton onClick={() => setChatOpen(true)} />
        <ParallaxField />
        <TrainingHeader
          modalityIcon={currentModalityMeta.Icon} modalityLabel={currentModalityMeta.tKey}
          bleState={bleState} lastHR={lastHR} onToggleBle={toggleBLE}
          onOpenAddExercise={() => { setShowAI(true); setAiStep('add_manual'); }}
          isGym={trainingModality === 'gym'}
        />
        <main className="max-w-5xl mx-auto px-4 pt-8">
          {trainingModality === 'gym' ? (
            <>
              <DaySelector plans={userPlans} activeDay={activeDay} dayKeyMap={DAY_TKEY_MAP} onSelectDay={setActiveDay} />
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                <GymSidebar
                  timeLeft={timeLeft} timerActive={timerActive} progressPercentage={progressPercentage}
                  progressBarRef={progressBarRef} onToggleTimer={() => setTimerActive(!timerActive)}
                  onResetTimer={() => setTimeLeft(60)} onOpenAi={() => { setShowAI(true); setAiStep('workout_goal'); }}
                />
                <GymExerciseList
                  currentPlan={currentPlan} completedIds={completedIds}
                  dayKey={DAY_TKEY_MAP[currentPlan.day] ?? currentPlan.day}
                  targetKey={TARGET_TKEY_MAP[currentPlan.target] ?? currentPlan.target}
                  onToggleExercise={toggleExercise}
                />
              </div>
            </>
          ) : (
            <div className="max-w-xl mx-auto space-y-6 pb-8">
              <NonGymSession
                trainingModality={trainingModality} isGpsModality={isGpsModality} isSwimming={isSwimming}
                useGpsMode={useGpsMode} gps={gps} sessionSec={sessionSec} sessionRun={sessionRun}
                distanceKm={distanceKm} targetKm={targetKm} targetTimes={targetTimes} targetPaceSec={targetPaceSec}
                selectedTarget={selectedTarget} poolLengthM={poolLengthM} lapCount={lapCount}
                bleState={bleState} lastHR={lastHR} currentModalityMeta={currentModalityMeta}
                modalityHistory={modalityHistory}
                onSetTargetKm={(v) => { setTargetKm(v); setSelectedTarget(null); }}
                onSetSelectedTarget={setSelectedTarget} onSetSessionRun={setSessionRun}
                onSetSessionSec={setSessionSec} onSetPoolLengthM={setPoolLengthM}
                onSetLapCount={setLapCount} onStartGps={gps.startGps}
                onFinalize={finalizeModalitySession}
                onReset={() => { setSessionRun(false); setSessionSec(0); setLapCount(0); }}
              />
            </div>
          )}
        </main>
        <AiWorkoutModal
          isOpen={showAI} onClose={() => setShowAI(false)} aiLoading={aiLoading} aiStep={aiStep}
          onGenerateWorkout={generateAIWorkout} onAddExercise={addExerciseToPlan}
          availableExercises={ALL_AVAILABLE_EXERCISES}
        />
        <ChatPanel
          isOpen={chatOpen} onClose={() => setChatOpen(false)} messages={chatMessages}
          chatInput={chatInput} chatLoading={chatLoading} onInputChange={setChatInput} onSend={sendChatMessage}
        />
        <AnimatePresence>
          {showGpsResult && gps.gpsSnapshot && (
            <GpsSessionResult
              snapshot={gps.gpsSnapshot} targetTimes={targetTimes} targetKm={targetKm}
              selectedTarget={selectedTarget} onSave={handleSaveGpsSession}
              onDiscard={handleDiscardGpsSession} t={t}
            />
          )}
        </AnimatePresence>
      </div>
    </AuthGuard>
  );
}
