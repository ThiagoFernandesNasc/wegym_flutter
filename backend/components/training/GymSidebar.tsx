"use client";

import React, { RefObject } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Timer, RotateCcw, Zap } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { Tilt3D } from "@/components/ui/Tilt3D";

interface GymSidebarProps {
  timeLeft: number;
  timerActive: boolean;
  progressPercentage: number;
  progressBarRef: RefObject<HTMLDivElement | null>;
  onToggleTimer: () => void;
  onResetTimer: () => void;
  onOpenAi: () => void;
}

function GymSidebarInner({ timeLeft, timerActive, progressPercentage, progressBarRef, onToggleTimer, onResetTimer, onOpenAi }: GymSidebarProps) {
  const { t } = useTranslations();

  return (
    <aside className="space-y-6">
      <Tilt3D className="rounded-3xl" intensity={7} scale={1.01}>
        <div className="bg-zinc-900/50 p-6 rounded-3xl border border-white/5 text-center">
          <div className="flex justify-between items-center mb-4 text-zinc-400">
            <Timer size={18} />
            <RotateCcw size={16} onClick={onResetTimer} className="cursor-pointer hover:text-white transition-colors" />
          </div>
          <div className="relative h-16 mb-6">
            <AnimatePresence>
              <motion.div
                key={timeLeft}
                initial={{ opacity: 0, y: 14, rotateX: 75, transformPerspective: 400 }}
                animate={{ opacity: 1, y: 0, rotateX: 0 }}
                exit={{ opacity: 0, y: -14, rotateX: -75 }}
                transition={{ duration: 0.22, ease: 'easeOut' }}
                className="absolute inset-0 flex items-center justify-center text-6xl font-black text-white font-mono tracking-tighter"
              >
                {timeLeft}
                <span className="text-2xl text-orange-500 ml-1">s</span>
              </motion.div>
            </AnimatePresence>
          </div>
          <button
            onClick={onToggleTimer}
            className={`w-full py-4 rounded-xl font-black uppercase italic transition-all cursor-pointer ${timerActive ? 'bg-zinc-800 text-white' : 'bg-white text-black'}`}
          >
            {timerActive ? t('training.pause') : t('training.startRest')}
          </button>
        </div>
      </Tilt3D>

      <Tilt3D className="rounded-3xl" intensity={6} scale={1.01}>
        <div className="bg-zinc-900/50 p-6 rounded-3xl border border-white/5 space-y-4">
          <div className="text-center">
            <p className="text-xs font-black uppercase italic text-zinc-400 mb-3">{t('training.workoutProgress')}</p>
            <div className="mb-3">
              <div className="w-full h-3 bg-zinc-800 rounded-full overflow-hidden">
                <div ref={progressBarRef} className="h-full bg-linear-to-r from-orange-500 to-orange-600 transition-all duration-300" />
              </div>
            </div>
            <div className="relative h-9">
              <AnimatePresence>
                <motion.div
                  key={progressPercentage}
                  initial={{ opacity: 0, y: 10, rotateX: 60, transformPerspective: 400 }}
                  animate={{ opacity: 1, y: 0, rotateX: 0 }}
                  exit={{ opacity: 0, y: -10, rotateX: -60 }}
                  transition={{ duration: 0.25, ease: 'easeOut' }}
                  className="absolute inset-0 text-2xl font-black text-white"
                >
                  {progressPercentage}%
                </motion.div>
              </AnimatePresence>
            </div>
          </div>
        </div>
      </Tilt3D>

      <Tilt3D className="rounded-2xl" intensity={8} scale={1.02}>
        <button
          onClick={onOpenAi}
          className="relative w-full px-6 py-4 bg-orange-600 rounded-2xl shadow-2xl shadow-orange-600/40 border border-orange-400/50 hover:bg-orange-700 transition-all cursor-pointer overflow-hidden"
        >
          <motion.div
            aria-hidden
            className="absolute inset-0 bg-white/10 rounded-2xl"
            animate={{ opacity: [0.2, 0.05, 0.2] }}
            transition={{ duration: 2.4, repeat: Infinity, ease: 'easeInOut' }}
          />
          <div className="relative flex items-center justify-center gap-3">
            <span className="text-white font-black uppercase italic text-sm">{t('training.generateAI')}</span>
            <Zap className="text-white w-5 h-5" />
          </div>
        </button>
      </Tilt3D>
    </aside>
  );
}

export const GymSidebar = React.memo(GymSidebarInner);
