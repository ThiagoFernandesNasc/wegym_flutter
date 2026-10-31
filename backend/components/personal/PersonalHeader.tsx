"use client";

import { Award, Plus } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";

interface PersonalHeaderProps {
  onAddStudent: () => void;
}

export function PersonalHeader({ onAddStudent }: PersonalHeaderProps) {
  const { t } = useTranslations();
  return (
    <header className="sticky top-0 z-50 bg-zinc-950/60 backdrop-blur-md border-b border-white/5 px-6 py-4 flex justify-between items-center">
      <div className="flex items-center space-x-3">
        <div className="w-10 h-10 bg-orange-600 rounded-xl flex items-center justify-center shadow-lg shadow-orange-600/20">
          <Award className="text-white w-5 h-5" />
        </div>
        <div>
          <span className="text-xl font-black italic tracking-tighter text-white block leading-none">{t('personal.proCoach')}</span>
          <span className="text-[9px] font-bold text-orange-500 uppercase tracking-[0.2em]">{t('personal.personalPanel')}</span>
        </div>
      </div>
      <div className="flex items-center space-x-4">
        <button onClick={onAddStudent}
          className="bg-orange-600 hover:bg-orange-700 p-2.5 rounded-xl transition-all flex items-center gap-2 group cursor-pointer">
          <Plus size={20} className="text-white group-hover:rotate-90 transition-transform" />
          <span className="text-[10px] font-black uppercase italic pr-1 hidden md:block text-white">{t('personal.addNewStudent')}</span>
        </button>
      </div>
    </header>
  );
}
