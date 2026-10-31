"use client";

import React from "react";
import { IdCard } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { SectionHeader } from "./SectionHeader";

export function CredentialSection({ cref }: { cref: string }) {
  const { t } = useTranslations();
  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <SectionHeader eyebrow={t('profile.credential')} title={t('profile.professionalRegistry')} icon={IdCard} />
      <div className="mt-5 bg-zinc-950/60 border border-white/5 rounded-4xl p-5 flex items-center gap-4">
        <div className="w-12 h-12 rounded-2xl bg-orange-600/15 text-orange-500 flex items-center justify-center shrink-0">
          <IdCard size={22} />
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500">{t('profile.cref')}</p>
          <p className="text-lg font-black italic uppercase text-white tracking-tight truncate">
            {cref || "\u2014"}
          </p>
        </div>
      </div>
    </section>
  );
}
