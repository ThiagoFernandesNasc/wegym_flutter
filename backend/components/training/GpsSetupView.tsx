"use client";

import React from "react";
import { motion } from "framer-motion";
import { useTranslations } from "@/lib/i18n/hook";
import { formatDurationHMS } from "@/utils/training-helpers";

interface GpsSetupViewProps {
  targetKm: number;
  targetTimes: { minSec: number; avgSec: number; maxSec: number } | null;
  selectedTarget: 'min' | 'avg' | 'max' | null;
  onSetTargetKm: (v: number) => void;
  onSetSelectedTarget: (v: 'min' | 'avg' | 'max' | null) => void;
  onStartGps: () => void;
}

export function GpsSetupView({ targetKm, targetTimes, selectedTarget, onSetTargetKm, onSetSelectedTarget, onStartGps }: GpsSetupViewProps) {
  const { t } = useTranslations();
  return (
    <>
      <div className="bg-zinc-900/50 p-5 rounded-3xl border border-white/5">
        <p className="text-[10px] font-black uppercase italic text-zinc-400 mb-3">{t('training.kmQuestion')}</p>
        <div className="flex gap-2 items-center">
          <input type="number" inputMode="decimal" value={targetKm || ''}
            onChange={(e) => onSetTargetKm(Number(e.target.value) || 0)} placeholder="0"
            className="w-full bg-zinc-950 border border-white/10 rounded-xl px-4 py-3 text-white font-mono text-lg outline-none focus:border-orange-500"
            min={0} step={0.1} />
          <span className="text-sm font-black text-zinc-500">{t('common.kmUnit')}</span>
        </div>
      </div>
      {targetTimes && targetKm > 0 && (
        <div className="bg-zinc-900/50 p-5 rounded-3xl border border-white/5 space-y-3">
          <p className="text-[10px] font-black uppercase italic text-zinc-400">{t('training.targetTime')}</p>
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-xs text-emerald-400 font-bold">{t('training.minTime')}</span>
              <span className="text-sm font-mono text-white font-black">{formatDurationHMS(targetTimes.minSec)}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-xs text-zinc-400 font-bold">{t('training.avgTime')}</span>
              <span className="text-sm font-mono text-white font-black">{formatDurationHMS(targetTimes.avgSec)}</span>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-xs text-amber-400 font-bold">{t('training.maxTime')}</span>
              <span className="text-sm font-mono text-white font-black">{formatDurationHMS(targetTimes.maxSec)}</span>
            </div>
          </div>
        </div>
      )}
      {targetTimes && targetKm > 0 && (
        <div className="bg-zinc-900/50 p-5 rounded-3xl border border-white/5 space-y-3">
          <p className="text-[10px] font-black uppercase italic text-zinc-400">Selecionar ritmo alvo</p>
          <div className="grid grid-cols-3 gap-2">
            {(['min', 'avg', 'max'] as const).map((key) => {
              const sec = targetTimes[`${key}Sec`];
              const labels: Record<string, { label: string; color: string }> = {
                min: { label: t('training.minTime'), color: 'border-emerald-500/50 text-emerald-400' },
                avg: { label: t('training.avgTime'), color: 'border-zinc-500/50 text-zinc-300' },
                max: { label: t('training.maxTime'), color: 'border-amber-500/50 text-amber-400' },
              };
              const isActive = selectedTarget === key;
              return (
                <button key={key} type="button" onClick={() => onSetSelectedTarget(key)}
                  className={`px-3 py-3 rounded-xl font-black uppercase italic text-[10px] border transition-all cursor-pointer ${isActive ? 'bg-orange-600 border-orange-400 text-white' : `${labels[key].color} bg-zinc-950 border-white/10 hover:border-white/30`}`}>
                  <span className="block">{labels[key].label}</span>
                  <span className="block mt-1 font-mono text-[11px] not-italic">{formatDurationHMS(sec)}</span>
                </button>
              );
            })}
          </div>
        </div>
      )}
      <button type="button" onClick={onStartGps}
        className="w-full py-4 rounded-xl font-black uppercase italic text-sm bg-white text-black hover:bg-orange-500 hover:text-white transition-all cursor-pointer flex items-center justify-center gap-2">
        <span role="img" aria-label="satellite">{`\u{1F6F0}\u{FE0F}`}</span> {t('training.startGps')}
      </button>
    </>
  );
}
