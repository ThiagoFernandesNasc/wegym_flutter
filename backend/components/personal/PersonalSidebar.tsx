"use client";

import { ChevronRight, Bot } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { Student } from "@/types/personal";

interface PersonalSidebarProps {
  students: Student[];
  onSelectStudent: (id: string) => void;
  onOpenChat: () => void;
}

export function PersonalSidebar({ students, onSelectStudent, onOpenChat }: PersonalSidebarProps) {
  const { t } = useTranslations();
  return (
    <aside className="space-y-6">
      <div className="bg-orange-600 rounded-[28px] sm:rounded-[40px] p-5 sm:p-8 relative overflow-hidden shadow-2xl shadow-orange-600/20">
        <div className="relative z-10">
          <h3 className="text-white font-black italic uppercase text-xl sm:text-2xl leading-tight mb-3 sm:mb-4">{t('personal.aiOptimization')}</h3>
          <button onClick={onOpenChat}
            className="bg-white text-orange-600 px-5 sm:px-8 py-3 sm:py-4 rounded-xl sm:rounded-2xl font-black uppercase italic text-[10px] sm:text-xs flex items-center gap-2 sm:gap-3 hover:scale-105 transition-transform shadow-xl cursor-pointer">
            {t('personal.talkToCopilot')} <Bot size={16} />
          </button>
        </div>
        <Bot size={120} className="sm:hidden absolute -right-8 -bottom-8 text-white/10 -rotate-12" />
        <Bot size={160} className="hidden sm:block absolute -right-10 -bottom-10 text-white/10 -rotate-12" />
      </div>

      <div className="card-base p-6">
        <h3 className="text-white font-black italic uppercase text-sm mb-4">{t('personal.myStudents')}</h3>
        <div className="space-y-5">
          {students.map((student) => (
            <div key={student.id} className="flex flex-col gap-2 cursor-pointer hover:translate-x-1 transition-transform" onClick={() => onSelectStudent(student.id)}>
              <div className="flex justify-between items-center">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-full bg-zinc-800 border border-white/10 flex items-center justify-center text-[10px] font-bold">{student.name.charAt(0)}</div>
                  <div>
                    <p className="text-[11px] font-black uppercase text-white">{student.name}</p>
                    <p className="text-[9px] text-zinc-500 font-bold uppercase">{student.lastTraining}</p>
                  </div>
                </div>
                <ChevronRight size={14} className="text-zinc-600" />
              </div>
            </div>
          ))}
        </div>
      </div>
    </aside>
  );
}
