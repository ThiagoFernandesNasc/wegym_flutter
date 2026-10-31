"use client";

import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { HeartPulse } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { formatDurationHMS } from "@/utils/training-helpers";
import { Tilt3D } from "@/components/ui/Tilt3D";
import type { ConnectionState, HRData } from "@/lib/bluetooth";

interface GenericViewProps {
  sessionSec: number;
  sessionRun: boolean;
  bleState: ConnectionState;
  lastHR: HRData | null;
  onSetSessionRun: (v: boolean | ((prev: boolean) => boolean)) => void;
  onSetSessionSec: (v: number | ((prev: number) => number)) => void;
  onFinalize: () => void;
  onReset: () => void;
}

export function GenericView({ sessionSec, sessionRun, bleState, lastHR, onSetSessionRun, onSetSessionSec, onFinalize, onReset }: GenericViewProps) {
  const { t } = useTranslations();
  return (
    <Tilt3D className="rounded-3xl" intensity={6} scale={1.01}>
      <div className="bg-zinc-900/50 p-8 rounded-3xl border border-white/5 text-center">
        <p className="text-[10px] font-black uppercase italic text-zinc-500 mb-2">{t('training.sessionTime')}</p>
        <div className="relative h-16">
          <AnimatePresence>
            <motion.div key={sessionSec} initial={{ opacity: 0, y: 12, rotateX: 70, transformPerspective: 400 }}
              animate={{ opacity: 1, y: 0, rotateX: 0 }} exit={{ opacity: 0, y: -12, rotateX: -70 }}
              transition={{ duration: 0.18, ease: 'easeOut' }}
              className="absolute inset-0 text-5xl sm:text-6xl font-black text-white font-mono tracking-tight tabular-nums">
              {formatDurationHMS(sessionSec)}
            </motion.div>
          </AnimatePresence>
        </div>
        {bleState === "connected" && lastHR && (
          <div className="mt-4 flex items-center justify-center gap-2 text-emerald-400">
            <HeartPulse size={18} className="animate-pulse" />
            <span className="text-3xl font-black tabular-nums">{lastHR.bpm}</span>
            <span className="text-[10px] font-black uppercase tracking-widest text-zinc-500">{t('training.bpm')}</span>
          </div>
        )}
        <div className="mt-6 flex flex-wrap gap-2 justify-center">
          <button type="button" onClick={() => onSetSessionRun((r) => !r)}
            className={`px-6 py-3 rounded-xl font-black uppercase italic text-sm cursor-pointer transition-all ${sessionRun ? 'bg-zinc-800 text-white border border-white/10' : 'bg-white text-black'}`}>
            {sessionRun ? t('training.pause') : sessionSec > 0 ? t('training.resume') : t('home.start')}
          </button>
          <button type="button" onClick={onReset}
            className="px-6 py-3 rounded-xl font-black uppercase italic text-sm bg-zinc-950 border border-white/10 text-zinc-300 hover:border-orange-500/50 cursor-pointer transition-all">
            {t('training.reset')}
          </button>
          <button type="button" onClick={onFinalize} disabled={sessionSec === 0}
            className="px-6 py-3 rounded-xl font-black uppercase italic text-sm bg-orange-600 text-white border border-orange-400/50 hover:bg-orange-700 disabled:opacity-30 disabled:cursor-not-allowed cursor-pointer transition-all">
            {t('training.finishSession')}
          </button>
        </div>
      </div>
    </Tilt3D>
  );
}
