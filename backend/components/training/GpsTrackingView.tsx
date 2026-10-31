"use client";

import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { HeartPulse } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { formatDurationHMS } from "@/utils/training-helpers";
import { Tilt3D } from "@/components/ui/Tilt3D";
import { useGpsTracker } from "@/hooks/use-gps-tracker";
import RouteMap from "@/components/training/RouteMap";
import type { ConnectionState, HRData } from "@/lib/bluetooth";

interface GpsTrackingViewProps {
  gps: ReturnType<typeof useGpsTracker>;
  targetKm: number;
  targetTimes: { minSec: number; avgSec: number; maxSec: number } | null;
  targetPaceSec: number | null;
  selectedTarget: 'min' | 'avg' | 'max' | null;
  bleState: ConnectionState;
  lastHR: HRData | null;
  onFinalize: () => void;
}

export function GpsTrackingView({ gps, targetKm, targetTimes, targetPaceSec, selectedTarget, bleState, lastHR, onFinalize }: GpsTrackingViewProps) {
  const { t } = useTranslations();
  return (
    <>
      <div className="bg-zinc-900/50 p-5 rounded-3xl border border-white/5">
        <div className="flex items-center justify-between mb-4">
          <span className="text-[10px] font-black uppercase italic text-zinc-400">{t('training.gpsTracking')}</span>
          <div className="flex items-center gap-2 text-emerald-400 text-[10px] font-bold uppercase">
            <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />{t('training.gpsActive')}
          </div>
        </div>
        {targetKm > 0 && (
          <div className="mb-4">
            <div className="flex justify-between text-[10px] font-bold text-zinc-500 mb-1">
              <span>{gps.liveDistKm.toFixed(2)} km</span><span>{targetKm} km</span>
            </div>
            <div className="w-full h-2 bg-zinc-800 rounded-full overflow-hidden">
              <div className="h-full bg-linear-to-r from-orange-500 to-orange-600 rounded-full transition-all duration-300"
                style={{ width: `${Math.min((gps.liveDistKm / targetKm) * 100, 100)}%` }} />
            </div>
          </div>
        )}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-zinc-950 rounded-xl p-3 text-center">
            <p className="text-[9px] font-black uppercase text-zinc-500">{t('training.resultDistance')}</p>
            <p className="text-lg font-black text-white mt-1 font-mono">{gps.liveDistKm.toFixed(2)}<span className="text-[10px] text-orange-500 ml-1">{t('common.kmUnit')}</span></p>
          </div>
          <div className="bg-zinc-950 rounded-xl p-3 text-center">
            <p className="text-[9px] font-black uppercase text-zinc-500">{t('training.resultPace')}</p>
            <p className="text-lg font-black text-white mt-1 font-mono">
              {gps.livePace > 0 ? `${Math.floor(gps.livePace / 60)}:${(gps.livePace % 60).toString().padStart(2, '0')}` : '\u2014'}
            </p>
          </div>
          <div className="bg-zinc-950 rounded-xl p-3 text-center">
            <p className="text-[9px] font-black uppercase text-zinc-500">{t('training.resultSteps')}</p>
            <p className="text-lg font-black text-white mt-1">{gps.liveSteps.toLocaleString()}</p>
          </div>
        </div>
        {selectedTarget && targetPaceSec != null && targetTimes && (
          <div className="bg-zinc-950 rounded-xl p-3 flex items-center justify-between mt-3">
            <span className="text-[10px] font-black uppercase text-zinc-400">
              Ritmo alvo ({selectedTarget === 'min' ? t('training.minTime') : selectedTarget === 'avg' ? t('training.avgTime') : t('training.maxTime')})
            </span>
            <span className={`text-sm font-mono font-black flex items-center gap-2 ${gps.livePace > 0 && gps.livePace <= targetPaceSec ? 'text-emerald-400' : 'text-red-400'}`}>
              {gps.livePace > 0 && <span>{gps.livePace <= targetPaceSec ? '\u2705' : '\u26a0\ufe0f'}</span>}
              {formatDurationHMS(targetPaceSec)}/km
            </span>
          </div>
        )}
        <div className="mt-6 flex flex-wrap gap-2 justify-center">
          <button type="button" onClick={onFinalize} className="px-6 py-3 rounded-xl font-black uppercase italic text-sm bg-orange-600 text-white border border-orange-400/50 hover:bg-orange-700 cursor-pointer transition-all">
            {t('training.finishSession')}
          </button>
          <button type="button" onClick={gps.resetGps} className="px-6 py-3 rounded-xl font-black uppercase italic text-sm bg-zinc-950 border border-white/10 text-zinc-300 hover:border-orange-500/50 cursor-pointer transition-all">
            {t('training.reset')}
          </button>
        </div>
      </div>
      <Tilt3D className="rounded-3xl" intensity={6} scale={1.01}>
        <div className="bg-zinc-900/50 p-5 rounded-3xl border border-white/5">
          <p className="text-[10px] font-black uppercase italic text-zinc-400 mb-2">{t('training.sessionTime')}</p>
          <div className="relative h-11">
            <AnimatePresence>
              <motion.div key={gps.liveSec} initial={{ opacity: 0, y: 10, rotateX: 70, transformPerspective: 400 }}
                animate={{ opacity: 1, y: 0, rotateX: 0 }} exit={{ opacity: 0, y: -10, rotateX: -70 }}
                transition={{ duration: 0.18, ease: 'easeOut' }}
                className="absolute inset-0 text-4xl font-black text-white font-mono tracking-tight tabular-nums">
                {formatDurationHMS(gps.liveSec)}
              </motion.div>
            </AnimatePresence>
          </div>
          {bleState === "connected" && lastHR && (
            <div className="mt-4 flex items-center gap-2 text-emerald-400">
              <HeartPulse size={18} className="animate-pulse" />
              <span className="text-2xl font-black tabular-nums">{lastHR.bpm}</span>
              <span className="text-[10px] font-black uppercase tracking-widest text-zinc-500">{t('training.bpm')}</span>
            </div>
          )}
        </div>
      </Tilt3D>
      {gps.liveCoordinates.length >= 2 && (
        <Tilt3D className="rounded-3xl" intensity={5} scale={1.01} glare={false}>
          <div className="bg-zinc-900/50 p-3 rounded-3xl border border-white/5">
            <p className="text-[9px] font-black uppercase italic text-zinc-400 mb-2">{t('training.resultRoute')}</p>
            <div className="w-full rounded-2xl overflow-hidden" style={{ height: 200 }}>
              <RouteMap coordinates={gps.liveCoordinates} height={200} interactive={true} />
            </div>
          </div>
        </Tilt3D>
      )}
    </>
  );
}
