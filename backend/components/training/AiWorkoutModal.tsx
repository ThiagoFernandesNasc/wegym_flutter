"use client";

import React from "react";
import { motion, AnimatePresence } from "framer-motion";
import { BrainCircuit, X, Trophy, Flame, Plus } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import type { Exercise } from "@/types/training";

interface AiWorkoutModalProps {
  isOpen: boolean;
  onClose: () => void;
  aiLoading: boolean;
  aiStep: 'workout_goal' | 'add_manual' | 'result';
  onGenerateWorkout: (goal: 'cut' | 'bulk') => void;
  onAddExercise: (exercise: Exercise) => void;
  availableExercises: Exercise[];
}

export function AiWorkoutModal({ isOpen, onClose, aiLoading, aiStep, onGenerateWorkout, onAddExercise, availableExercises }: AiWorkoutModalProps) {
  const { t } = useTranslations();

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-100 bg-zinc-950/90 backdrop-blur-xl flex items-center justify-center p-4">
          <motion.div initial={{ scale: 0.9 }} animate={{ scale: 1 }} className="w-full max-w-lg bg-zinc-900 border border-white/10 rounded-[40px] overflow-hidden shadow-2xl">
            <div className="p-6 border-b border-white/5 flex justify-between items-center bg-orange-600/5">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-orange-600 rounded-2xl flex items-center justify-center"><BrainCircuit className="text-white w-6 h-6" /></div>
                <h3 className="text-lg font-black uppercase italic text-white">{t('training.wegymAI')}</h3>
              </div>
              <X size={24} role="button" tabIndex={0} className="text-zinc-500 cursor-pointer" onClick={onClose} onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onClose(); } }} />
            </div>
            <div className="p-6">
              {aiLoading ? (
                <div className="py-12 flex flex-col items-center space-y-4">
                  <div className="w-12 h-12 border-4 border-t-orange-600 border-zinc-800 rounded-full animate-spin" />
                  <p className="text-xs font-black uppercase text-orange-500">{t('training.syncingData')}</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {aiStep === 'workout_goal' && (
                    <div className="grid grid-cols-1 gap-3">
                      <button onClick={() => onGenerateWorkout('bulk')} className="p-5 bg-zinc-950 border border-white/5 rounded-3xl flex items-center gap-4 hover:border-orange-500 transition-all cursor-pointer">
                        <Trophy className="text-orange-500" size={20} /><span className="font-black uppercase italic text-xs">{t('training.focusBulk')}</span>
                      </button>
                      <button onClick={() => onGenerateWorkout('cut')} className="p-5 bg-zinc-950 border border-white/5 rounded-3xl flex items-center gap-4 hover:border-orange-500 transition-all cursor-pointer">
                        <Flame className="text-orange-500" size={20} /><span className="font-black uppercase italic text-xs">{t('training.focusCut')}</span>
                      </button>
                    </div>
                  )}
                  {aiStep === 'add_manual' && (
                    <div className="max-h-80 overflow-y-auto pr-2 custom-scrollbar space-y-2">
                      {availableExercises.map((ex, i) => (
                        <button key={i} onClick={() => onAddExercise(ex)} className="w-full p-4 bg-zinc-950 border border-white/5 rounded-2xl flex items-center justify-between hover:bg-emerald-500/5 transition-all cursor-pointer">
                          <div className="text-left"><p className="font-black uppercase italic text-white text-[11px]">{ex.name}</p><p className="text-[9px] text-zinc-500 font-bold uppercase">{ex.muscle}</p></div>
                          <Plus size={16} className="text-emerald-500" />
                        </button>
                      ))}
                    </div>
                  )}
                  {aiStep === 'result' && (
                    <div className="space-y-6">
                      <div className="bg-zinc-950 p-6 rounded-3xl border border-white/10 max-h-72 overflow-y-auto custom-scrollbar">
                        <p className="text-zinc-300 text-xs leading-relaxed whitespace-pre-line font-mono">{t('training.planBulkApplied')}</p>
                      </div>
                      <button onClick={onClose} className="w-full py-4 bg-white text-black font-black uppercase italic rounded-2xl hover:bg-orange-500 hover:text-white transition-all cursor-pointer">{t('training.confirmPlan')}</button>
                    </div>
                  )}
                </div>
              )}
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
