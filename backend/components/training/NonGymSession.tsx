"use client";

import React from "react";
import { motion } from "framer-motion";
import { useTranslations } from "@/lib/i18n/hook";
import { ScrollReveal } from "@/components/ui/ScrollReveal";
import { ModalityHistory } from "@/components/training/ModalityHistory";
import { GpsTrackingView } from "@/components/training/GpsTrackingView";
import { GpsSetupView } from "@/components/training/GpsSetupView";
import { SwimmingView } from "@/components/training/SwimmingView";
import { GenericView } from "@/components/training/GenericView";
import { useGpsTracker } from "@/hooks/use-gps-tracker";
import type { ConnectionState, HRData } from "@/lib/bluetooth";
import type { TrainingModalityId, ModalitySessionEntry } from "@/types/training";
import type { MODALITY_OPTIONS } from "@/constants/modalities";

interface NonGymSessionProps {
  trainingModality: TrainingModalityId;
  isGpsModality: boolean;
  isSwimming: boolean;
  useGpsMode: boolean;
  gps: ReturnType<typeof useGpsTracker>;
  sessionSec: number;
  sessionRun: boolean;
  distanceKm: string;
  targetKm: number;
  targetTimes: { minSec: number; avgSec: number; maxSec: number } | null;
  targetPaceSec: number | null;
  selectedTarget: 'min' | 'avg' | 'max' | null;
  poolLengthM: number;
  lapCount: number;
  bleState: ConnectionState;
  lastHR: HRData | null;
  currentModalityMeta: typeof MODALITY_OPTIONS[number];
  modalityHistory: Partial<Record<TrainingModalityId, ModalitySessionEntry[]>>;
  onSetTargetKm: (v: number) => void;
  onSetSelectedTarget: (v: 'min' | 'avg' | 'max' | null) => void;
  onSetSessionRun: (v: boolean | ((prev: boolean) => boolean)) => void;
  onSetSessionSec: (v: number | ((prev: number) => number)) => void;
  onSetPoolLengthM: (v: number) => void;
  onSetLapCount: (v: number | ((prev: number) => number)) => void;
  onStartGps: () => void;
  onFinalize: () => void;
  onReset: () => void;
}

export function NonGymSession(props: NonGymSessionProps) {
  const { t } = useTranslations();
  const {
    trainingModality, isGpsModality, isSwimming, useGpsMode, gps, sessionSec, sessionRun,
    targetKm, targetTimes, targetPaceSec, selectedTarget, poolLengthM, lapCount,
    bleState, lastHR, currentModalityMeta, modalityHistory,
    onSetTargetKm, onSetSelectedTarget, onSetSessionRun, onSetSessionSec,
    onSetPoolLengthM, onSetLapCount, onStartGps, onFinalize, onReset,
  } = props;

  return (
    <>
      <motion.div initial={{ opacity: 0, y: -12, rotateX: 15, transformPerspective: 500 }}
        animate={{ opacity: 1, y: 0, rotateX: 0 }} transition={{ duration: 0.45, ease: 'easeOut' }}
        className="flex items-center gap-3 text-zinc-500">
        {React.createElement(currentModalityMeta.Icon, { className: 'text-orange-500', size: 22 })}
        <p className="text-sm font-bold uppercase tracking-wide">{t(currentModalityMeta.tKey)}</p>
      </motion.div>

      {isGpsModality && useGpsMode ? (
        gps.gpsError ? (
          <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-3">
            <p className="text-xs text-red-400 font-bold">{gps.gpsError}</p>
          </div>
        ) : gps.gpsState === 'tracking' ? (
          <GpsTrackingView gps={gps} targetKm={targetKm} targetTimes={targetTimes}
            targetPaceSec={targetPaceSec} selectedTarget={selectedTarget}
            bleState={bleState} lastHR={lastHR} onFinalize={onFinalize} />
        ) : (
          <GpsSetupView targetKm={targetKm} targetTimes={targetTimes} selectedTarget={selectedTarget}
            onSetTargetKm={onSetTargetKm} onSetSelectedTarget={onSetSelectedTarget} onStartGps={onStartGps} />
        )
      ) : isSwimming ? (
        <SwimmingView sessionSec={sessionSec} sessionRun={sessionRun} poolLengthM={poolLengthM}
          lapCount={lapCount} bleState={bleState} lastHR={lastHR}
          onSetSessionRun={onSetSessionRun} onSetSessionSec={onSetSessionSec}
          onSetPoolLengthM={onSetPoolLengthM} onSetLapCount={onSetLapCount}
          onFinalize={onFinalize} onReset={onReset} />
      ) : (
        <GenericView sessionSec={sessionSec} sessionRun={sessionRun}
          bleState={bleState} lastHR={lastHR}
          onSetSessionRun={onSetSessionRun} onSetSessionSec={onSetSessionSec}
          onFinalize={onFinalize} onReset={onReset} />
      )}

      <ScrollReveal className="rounded-3xl" y={24} rotateX={10}>
        <ModalityHistory modality={trainingModality} history={modalityHistory} />
      </ScrollReveal>
    </>
  );
}
