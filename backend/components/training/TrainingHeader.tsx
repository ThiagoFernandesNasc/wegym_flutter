"use client";

import React from "react";
import { Bluetooth, HeartPulse, Plus } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import type { ConnectionState, HRData } from "@/lib/bluetooth";
import type { TrainingModalityId } from "@/types/training";

interface TrainingHeaderProps {
  modalityIcon: React.ComponentType<{ size?: number; className?: string }>;
  modalityLabel: string;
  bleState: ConnectionState;
  lastHR: HRData | null;
  onToggleBle: () => void;
  onOpenAddExercise: () => void;
  isGym: boolean;
}

export function TrainingHeader({ modalityIcon: Icon, modalityLabel, bleState, lastHR, onToggleBle, onOpenAddExercise, isGym }: TrainingHeaderProps) {
  const { t } = useTranslations();

  return (
    <header className="sticky top-0 z-50 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4 flex justify-between items-center gap-2 pl-16 lg:pl-6">
      <div className="flex items-center gap-3 min-w-0">
        <Icon size={22} className="text-orange-500 shrink-0" />
        <h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white truncate">
          {t(modalityLabel)}
        </h1>
      </div>
      <div className="flex items-center space-x-2 sm:space-x-3 shrink-0">
        <button
          type="button"
          onClick={onToggleBle}
          className={`flex items-center gap-1.5 px-2.5 py-2 rounded-xl border transition-colors cursor-pointer ${
            bleState === "connected"
              ? "bg-emerald-600/15 border-emerald-500/30 text-emerald-400"
              : "bg-white/5 border-white/10 text-zinc-400 hover:text-zinc-200"
          }`}
          aria-label={t('training.connectSmartwatch')}
        >
          {bleState === "connected" && lastHR ? (
            <>
              <HeartPulse size={14} className="text-emerald-400" />
              <span className="text-xs font-black tabular-nums">{lastHR.bpm}</span>
            </>
          ) : bleState === "scanning" || bleState === "connecting" ? (
            <Bluetooth size={14} className="animate-pulse text-orange-500" />
          ) : (
            <Bluetooth size={14} />
          )}
        </button>
        {isGym && (
          <button
            onClick={onOpenAddExercise}
            className="bg-white/5 border border-white/10 px-2 sm:px-4 py-2 rounded-xl flex items-center space-x-2 cursor-pointer"
          >
            <Plus size={14} className="text-orange-500" />
            <span className="text-[10px] font-black uppercase italic text-zinc-300 hidden sm:inline">{t('training.addMoreExercises')}</span>
          </button>
        )}
      </div>
    </header>
  );
}
