"use client";

import React from "react";
import { Settings } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { SectionHeader } from "./SectionHeader";
import { PlanRow } from "./PlanRow";

interface AccountSectionProps {
  isPro: boolean;
  onUpgrade: () => void;
}

export function AccountSection({ isPro, onUpgrade }: AccountSectionProps) {
  const { t } = useTranslations();
  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <SectionHeader eyebrow={t('profile.account')} title={t('profile.yourPlan')} icon={Settings} />
      <div className="mt-6 space-y-3">
        <PlanRow isPro={isPro} onUpgrade={onUpgrade} />
      </div>
    </section>
  );
}
