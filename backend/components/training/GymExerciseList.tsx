"use client";

import React, { useState } from "react";
import { motion } from "framer-motion";
import { Activity } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { ExerciseItem } from "@/components/ExerciseItem/ExerciseItem";
import { ScrollReveal } from "@/components/ui/ScrollReveal";
import type { DayPlan, Exercise } from "@/types/training";

interface GymExerciseListProps {
  currentPlan: DayPlan;
  completedIds: string[];
  dayKey: string;
  targetKey: string;
  onToggleExercise: (id: string) => void;
}

function GymExerciseListInner({ currentPlan, completedIds, dayKey, targetKey, onToggleExercise }: GymExerciseListProps) {
  const { t } = useTranslations();
  const [openGifExercise, setOpenGifExercise] = useState<Exercise | null>(null);

  const handleOpenGif = (ex: Exercise) => {
    setOpenGifExercise(ex);
  };

  const handleCloseGif = () => {
    setOpenGifExercise(null);
  };

  return (
    <ScrollReveal className="lg:col-span-2 space-y-4" y={24} rotateX={10}>
      <section className="space-y-4">
        <div className="bg-zinc-900/50 rounded-3xl border border-white/5 overflow-hidden">
          <div className="p-5 border-b border-white/5 flex justify-between items-center">
            <h2 className="font-black italic uppercase text-white leading-tight">
              {t(dayKey)} - {t(targetKey)}
            </h2>
            <Activity size={20} className="text-orange-500 opacity-30" />
          </div>
          <div>
            {currentPlan.exercises.length > 0 ? (
              currentPlan.exercises.map((ex: Exercise, idx: number) => (
                <motion.div
                  key={ex.id || idx}
                  initial={{ opacity: 0, y: 16, rotateX: 10 }}
                  animate={{ opacity: 1, y: 0, rotateX: 0 }}
                  transition={{ delay: idx * 0.05, duration: 0.35, ease: 'easeOut' }}
                  style={{ transformPerspective: 600 }}
                >
                  <ExerciseItem
                    ex={ex}
                    isCompleted={!!ex.id && completedIds.includes(ex.id)}
                    onToggle={onToggleExercise}
                    showGif={openGifExercise?.id === ex.id}
                    onOpenGif={handleOpenGif}
                    onCloseGif={handleCloseGif}
                  />
                </motion.div>
              ))
            ) : (
              <div className="p-16 text-center text-zinc-600 font-black uppercase italic text-xs">{t('training.noWorkouts')}</div>
            )}
          </div>
        </div>
      </section>
    </ScrollReveal>
  );
}

export const GymExerciseList = React.memo(GymExerciseListInner);
