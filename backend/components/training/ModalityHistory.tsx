"use client";

import React from "react";
import { History } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { formatDurationHMS } from "@/utils/training-helpers";
import type { TrainingModalityId, ModalitySessionEntry } from "@/types/training";

interface ModalityHistoryProps {
  modality: TrainingModalityId;
  history: Partial<Record<TrainingModalityId, ModalitySessionEntry[]>>;
}

export function ModalityHistory({ modality, history }: ModalityHistoryProps) {
  const { t } = useTranslations();
  const sessions = history[modality] ?? [];

  return (
    <div className="bg-zinc-900/50 rounded-3xl border border-white/5 overflow-hidden">
      <div className="p-4 border-b border-white/5 flex items-center gap-2">
        <History size={18} className="text-orange-500" />
        <h3 className="text-xs font-black uppercase italic text-zinc-400">{t('training.modalityHistory')}</h3>
      </div>
      <ul className="divide-y divide-white/5 max-h-72 overflow-y-auto">
        {sessions.length === 0 ? (
          <li className="p-8 text-center text-zinc-600 text-xs font-bold uppercase italic">{t('training.noSessionsYet')}</li>
        ) : (
          sessions.map((row) => (
            <li key={row.id} className="px-5 py-4 flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-black text-white font-mono">{formatDurationHMS(row.durationSec)}</p>
                <p className="text-[9px] text-zinc-500 font-bold mt-0.5">
                  {new Date(row.at).toLocaleString('en-US', {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </p>
              </div>
              <div className="flex flex-col items-end gap-0.5">
                {row.distanceKm != null && (
                  <span className="text-xs font-mono text-orange-400 shrink-0">{row.distanceKm}{t('common.kmUnit')}</span>
                )}
                {row.avgPaceSecPerKm != null && (
                  <span className="text-[9px] font-mono text-zinc-500">
                    {Math.floor(row.avgPaceSecPerKm / 60)}:{(row.avgPaceSecPerKm % 60).toString().padStart(2, '0')}/km
                  </span>
                )}
                {row.steps != null && (
                  <span className="text-[9px] font-mono text-zinc-500">{row.steps} {t('training.resultSteps')}</span>
                )}
              </div>
            </li>
          ))
        )}
      </ul>
    </div>
  );
}
