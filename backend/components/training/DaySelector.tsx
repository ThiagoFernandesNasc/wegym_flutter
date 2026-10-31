"use client";

import React from "react";
import { motion } from "framer-motion";
import { useTranslations } from "@/lib/i18n/hook";
import type { DayPlan } from "@/types/training";

interface DaySelectorProps {
  plans: DayPlan[];
  activeDay: number;
  dayKeyMap: Record<string, string>;
  onSelectDay: (index: number) => void;
}

export function DaySelector({ plans, activeDay, dayKeyMap, onSelectDay }: DaySelectorProps) {
  const { t } = useTranslations();

  return (
    <div className="flex space-x-3 overflow-x-auto pb-6 mb-8 no-scrollbar">
      {plans.map((plan, index) => (
        <button
          key={index}
          onClick={() => onSelectDay(index)}
          className={`shrink-0 relative px-6 py-3 rounded-2xl font-black text-xs uppercase italic border transition-all cursor-pointer hover:border-orange-500 ${activeDay === index ? 'text-white border-transparent' : 'bg-zinc-900/50 border-white/5 text-zinc-500'}`}
        >
          {activeDay === index && (
            <motion.div
              layoutId="active-day-pill"
              className="absolute inset-0 bg-orange-600 border border-orange-400 rounded-2xl shadow-lg shadow-orange-600/30"
              transition={{ type: 'spring', stiffness: 320, damping: 30 }}
            />
          )}
          <span className="relative z-10">{t(dayKeyMap[plan.day] ?? plan.day)}</span>
        </button>
      ))}
    </div>
  );
}
