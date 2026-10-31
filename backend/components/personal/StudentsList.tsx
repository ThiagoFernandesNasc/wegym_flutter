"use client";

import { motion } from "framer-motion";
import { Award, ChevronRight, Target, UserPlus, Users, Search } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { Student } from "@/types/personal";

interface StudentsListProps {
  students: Student[];
  filteredStudents: Student[];
  studentsSearch: string;
  onSelectStudent: (id: string) => void;
  onSetSearch: (v: string) => void;
  onAddStudent: () => void;
}

export function StudentsList({ students, filteredStudents, studentsSearch, onSelectStudent, onSetSearch, onAddStudent }: StudentsListProps) {
  const { t } = useTranslations();
  return (
    <motion.div key="students-list" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4">
        <div>
          <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500 mb-1">{t('personal.dashboardTitle')}</p>
          <h2 className="text-2xl sm:text-3xl font-black italic uppercase text-white tracking-tighter leading-tight">{t('personal.myStudents')}</h2>
          <p className="text-[11px] text-zinc-500 font-medium mt-1">
            {students.length === 0 ? t('personal.noStudents')
              : `${students.length} ${students.length === 1 ? t('personal.studentSingular') : t('personal.studentPlural')} no total${studentsSearch ? ` · ${filteredStudents.length} no filtro` : ''}`}
          </p>
        </div>
        <button type="button" onClick={onAddStudent}
          className="self-stretch sm:self-auto bg-orange-600 hover:bg-orange-700 px-4 py-2.5 rounded-xl flex items-center justify-center gap-2 text-[10px] font-black uppercase italic text-white cursor-pointer transition-colors">
          <UserPlus size={14} /> {t('personal.addStudent')}
        </button>
      </div>

      <div className="relative">
        <Search size={14} className="absolute left-4 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none" />
        <input type="search" value={studentsSearch} onChange={(e) => onSetSearch(e.target.value)} placeholder={t('personal.searchPlaceholder')}
          className="w-full bg-zinc-900/60 border border-white/5 rounded-2xl pl-10 pr-4 py-3 text-xs text-white placeholder:text-zinc-600 outline-none focus:border-orange-500/40 transition-colors" />
      </div>

      {students.length === 0 ? (
        <div className="text-center py-16 px-6 bg-zinc-900/30 rounded-4xl border border-white/5">
          <div className="w-14 h-14 rounded-2xl bg-zinc-950 border border-white/5 flex items-center justify-center mx-auto mb-4">
            <Users size={22} className="text-zinc-500" />
          </div>
          <p className="text-sm font-black italic uppercase text-white tracking-tight">{t('personal.noStudentsHere')}</p>
          <p className="text-[11px] text-zinc-500 mt-1 max-w-xs mx-auto font-medium leading-relaxed">{t('personal.noStudentsDescription')}</p>
          <button type="button" onClick={onAddStudent}
            className="mt-5 bg-orange-600 hover:bg-orange-700 px-5 py-2.5 rounded-xl text-[10px] font-black uppercase italic text-white cursor-pointer transition-colors inline-flex items-center gap-2">
            <UserPlus size={14} /> {t('personal.registerFirstStudent')}
          </button>
        </div>
      ) : filteredStudents.length === 0 ? (
        <div className="text-center py-12 px-6 bg-zinc-900/30 rounded-4xl border border-white/5">
          <p className="text-sm font-black italic uppercase text-white tracking-tight">{t('personal.noStudentsFound')}</p>
          <p className="text-[11px] text-zinc-500 mt-1 font-medium">{t('personal.tryDifferentSearch')}</p>
          <button type="button" onClick={() => onSetSearch('')}
            className="mt-4 text-[10px] font-black uppercase italic text-orange-500 hover:text-orange-400 cursor-pointer">
            {t('personal.clearSearch')}
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-3">
          {filteredStudents.map((student) => {
            const initials = student.name.split(' ').filter(Boolean).slice(0, 2).map((p) => p.charAt(0).toUpperCase()).join('');
            return (
              <button key={student.id} type="button" onClick={() => onSelectStudent(student.id)}
                className="text-left bg-zinc-900/40 hover:bg-zinc-900/70 border border-white/5 hover:border-orange-500/30 rounded-3xl p-5 flex flex-col gap-4 transition-all cursor-pointer group">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-12 h-12 rounded-2xl bg-orange-600/15 text-orange-400 border border-orange-500/20 flex items-center justify-center shrink-0 font-black italic text-sm">
                    {initials || '?'}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-black italic uppercase text-white truncate leading-tight">{student.name}</p>
                    <p className="text-[10px] text-zinc-500 font-bold uppercase tracking-widest truncate">{student.lastTraining || t('personal.noRecord')}</p>
                  </div>
                  <ChevronRight size={16} className="text-zinc-600 group-hover:text-orange-500 transition-colors shrink-0" />
                </div>
                <div className="flex flex-wrap gap-1.5">
                  {student.experience && (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/5 border border-white/10 text-[9px] font-black uppercase italic tracking-wider text-zinc-300">
                      <Award size={10} className="text-zinc-500" /> {student.experience}
                    </span>
                  )}
                  {student.plan && (
                    <span className="inline-flex items-center px-2 py-0.5 rounded-full bg-white/5 border border-white/10 text-[9px] font-black uppercase italic tracking-wider text-zinc-300">
                      {student.plan}
                    </span>
                  )}
                  {student.objective && (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-orange-600/10 border border-orange-500/20 text-[9px] font-black uppercase italic tracking-wider text-orange-300 max-w-full truncate">
                      <Target size={10} className="text-orange-400 shrink-0" /> <span className="truncate">{student.objective}</span>
                    </span>
                  )}
                </div>
              </button>
            );
          })}
        </div>
      )}
    </motion.div>
  );
}
