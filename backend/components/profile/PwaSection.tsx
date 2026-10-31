"use client";

import React from "react";
import { Download, Wifi, Smartphone as SmartphoneIcon } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { SectionHeader } from "./SectionHeader";

export function PwaSection({
  isInstallable,
  isStandalone,
  onInstall,
}: {
  isInstallable: boolean;
  isStandalone: boolean;
  onInstall: () => void;
}) {
  const { t } = useTranslations();
  if (isStandalone) return null;

  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <SectionHeader eyebrow={t('profile.app')} title={t('profile.installOnPhone')} icon={SmartphoneIcon} />

      <div className="mt-5">
        {isInstallable ? (
          <button
            type="button"
            onClick={onInstall}
            className="w-full rounded-4xl border border-orange-500/30 bg-orange-600/10 hover:bg-orange-600/20 p-4 sm:p-5 flex items-center gap-4 text-left cursor-pointer transition-colors group"
          >
            <div className="w-12 h-12 rounded-2xl bg-orange-600/20 text-orange-400 flex items-center justify-center shrink-0 group-hover:scale-105 transition-transform">
              <Download size={20} />
            </div>
            <div className="flex-1">
              <p className="text-sm font-black italic uppercase text-white tracking-tight">
                {t('profile.installWegym')}
              </p>
              <p className="text-[10px] text-zinc-400 mt-0.5">
                {t('profile.installDescription')}
              </p>
            </div>
            <Download size={16} className="text-orange-400 shrink-0" />
          </button>
        ) : (
          <div className="rounded-4xl border border-white/5 bg-zinc-950/60 p-4 sm:p-5 flex items-center gap-4">
            <div className="w-12 h-12 rounded-2xl bg-white/5 text-zinc-400 flex items-center justify-center shrink-0">
              <Wifi size={20} />
            </div>
            <div className="flex-1">
              <p className="text-sm font-black italic uppercase text-white tracking-tight">
                {t('profile.availableAsApp')}
              </p>
              <p className="text-[10px] text-zinc-500 mt-0.5">
                {t('profile.installInstructions')}
              </p>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
