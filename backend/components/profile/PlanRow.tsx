"use client";

import React from "react";
import { ChevronRight, Crown } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";

export function PlanRow({ isPro, onUpgrade }: { isPro: boolean; onUpgrade: () => void }) {
  const { t } = useTranslations();
  return (
    <div
      className={`rounded-4xl border p-4 sm:p-5 flex items-center gap-4 transition-colors ${
        isPro
          ? "bg-orange-600/10 border-orange-500/30"
          : "bg-zinc-950/60 border-white/5 hover:border-white/10"
      }`}
    >
      <div
        className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 ${
          isPro ? "bg-orange-600 text-white" : "bg-orange-600/15 text-orange-500"
        }`}
      >
        <Crown size={20} />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500">{t('profile.planLabel')}</p>
        <p className="text-sm font-black italic uppercase text-white tracking-tight truncate">
          {isPro ? t('profile.wegymPro') : t('profile.free')}
        </p>
        <p className="text-[10px] text-zinc-500 mt-0.5 truncate">
          {isPro
            ? t('profile.proDescription')
            : t('profile.freeDescription')}
        </p>
      </div>
      {!isPro && (
        <button
          type="button"
          onClick={onUpgrade}
          className="shrink-0 bg-orange-600 hover:bg-orange-700 text-white px-3 sm:px-4 py-2.5 rounded-xl flex items-center gap-2 text-[10px] font-black uppercase italic tracking-wider cursor-pointer transition-colors"
        >
          {t('profile.learnPro')}
          <ChevronRight size={14} />
        </button>
      )}
    </div>
  );
}
