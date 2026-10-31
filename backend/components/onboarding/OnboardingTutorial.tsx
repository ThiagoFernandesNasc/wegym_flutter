"use client";

import React, { useState, useEffect, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Dumbbell, Zap, Activity, User, Crown, Award, Users, Bot, TrendingUp, X,
} from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";

const STORAGE_KEY = "wegym_tutorial_completed";

type Role = "atleta" | "personal";

interface Step {
  icon: React.ComponentType<{ size?: number; className?: string }>;
  titleKey: string;
  descKey: string;
}

const ATHLETE_STEPS: Step[] = [
  { icon: Dumbbell, titleKey: "tutorial.athlete.step1Title", descKey: "tutorial.athlete.step1Desc" },
  { icon: Zap, titleKey: "tutorial.athlete.step2Title", descKey: "tutorial.athlete.step2Desc" },
  { icon: Activity, titleKey: "tutorial.athlete.step3Title", descKey: "tutorial.athlete.step3Desc" },
  { icon: TrendingUp, titleKey: "tutorial.athlete.step4Title", descKey: "tutorial.athlete.step4Desc" },
  { icon: User, titleKey: "tutorial.athlete.step5Title", descKey: "tutorial.athlete.step5Desc" },
];

const PERSONAL_STEPS: Step[] = [
  { icon: Award, titleKey: "tutorial.personal.step1Title", descKey: "tutorial.personal.step1Desc" },
  { icon: Users, titleKey: "tutorial.personal.step2Title", descKey: "tutorial.personal.step2Desc" },
  { icon: Bot, titleKey: "tutorial.personal.step3Title", descKey: "tutorial.personal.step3Desc" },
  { icon: TrendingUp, titleKey: "tutorial.personal.step4Title", descKey: "tutorial.personal.step4Desc" },
];

export function OnboardingTutorial({ role }: { role: Role }) {
  const { t } = useTranslations();
  const [visible, setVisible] = useState(false);
  const [step, setStep] = useState(0);

  const steps = role === "personal" ? PERSONAL_STEPS : ATHLETE_STEPS;
  const total = steps.length;
  const current = steps[step];
  const isLast = step === total - 1;

  useEffect(() => {
    const completed = localStorage.getItem(STORAGE_KEY);
    if (!completed) {
      const timer = setTimeout(() => setVisible(true), 500);
      return () => clearTimeout(timer);
    }
  }, []);

  const handleNext = useCallback(() => {
    if (isLast) {
      localStorage.setItem(STORAGE_KEY, "true");
      setVisible(false);
    } else {
      setStep((s) => s + 1);
    }
  }, [isLast]);

  const handleSkip = useCallback(() => {
    localStorage.setItem(STORAGE_KEY, "true");
    setVisible(false);
  }, []);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Escape") handleSkip();
    },
    [handleSkip]
  );

  const Icon = current?.icon || Dumbbell;

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          key="tutorial-backdrop"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="fixed inset-0 z-200 flex items-center justify-center p-4"
          onKeyDown={handleKeyDown}
          tabIndex={-1}
        >
          <div className="absolute inset-0 bg-zinc-950/80 backdrop-blur-xl" onClick={handleSkip} />

          <motion.div
            key={step}
            initial={{ opacity: 0, y: 24, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -24, scale: 0.95 }}
            transition={{ duration: 0.3, ease: "easeOut" }}
            className="relative z-10 w-full max-w-md bg-zinc-900 border border-white/5 rounded-[40px] overflow-hidden shadow-2xl"
          >
            <div className="p-8 sm:p-10">
              <div className="flex justify-end mb-2">
                <button
                  type="button"
                  onClick={handleSkip}
                  className="text-zinc-600 hover:text-zinc-400 transition-colors cursor-pointer"
                  aria-label={t("tutorial.skip")}
                >
                  <X size={20} />
                </button>
              </div>

              <div className="flex flex-col items-center text-center">
                <div className="w-20 h-20 rounded-[28px] bg-orange-600/15 border border-orange-500/20 flex items-center justify-center mb-6">
                  <Icon size={36} className="text-orange-500" />
                </div>

                <h2 className="text-2xl font-black italic uppercase tracking-tighter text-white leading-tight mb-3">
                  {t(current.titleKey)}
                </h2>

                <p className="text-sm text-zinc-400 leading-relaxed max-w-xs">
                  {t(current.descKey)}
                </p>
              </div>

              <div className="flex items-center justify-center gap-2 mt-8 mb-8">
                {steps.map((_, i) => (
                  <div
                    key={i}
                    className={`h-1.5 rounded-full transition-all duration-300 ${
                      i === step
                        ? "w-8 bg-orange-500"
                        : i < step
                          ? "w-2 bg-orange-500/40"
                          : "w-2 bg-zinc-700"
                    }`}
                  />
                ))}
              </div>

              <div className="flex flex-col gap-2">
                <button
                  type="button"
                  onClick={handleNext}
                  className="w-full bg-orange-600 hover:bg-orange-700 text-white font-black uppercase italic py-4 rounded-2xl transition-all cursor-pointer text-sm tracking-tight"
                >
                  {isLast ? t("tutorial.start") : t("tutorial.next")}
                </button>

                <button
                  type="button"
                  onClick={handleSkip}
                  className="w-full text-zinc-500 hover:text-zinc-300 font-bold uppercase italic py-3 rounded-2xl transition-colors cursor-pointer text-xs"
                >
                  {t("tutorial.skip")}
                </button>
              </div>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
