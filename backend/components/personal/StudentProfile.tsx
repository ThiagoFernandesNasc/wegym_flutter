"use client";

import { motion } from "framer-motion";
import { Plus, Trash2, X, Dumbbell } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { Field } from "@/components/ui/DashboardElements";
import { EXPERIENCE_LEVELS, GENDER_OPTIONS, AVAILABLE_DAYS_OPTIONS, OTHER_DAYS_PREFIX, DAYS } from "@/constants/options";
import { Student } from "@/types/personal";

interface StudentProfileProps {
  student: Student;
  showExerciseForm: boolean;
  exerciseToAdd: { day: string; name: string; sets: string; reps: string; load: string };
  historyInput: { date: string; weight: string; muscleMass: string; bodyFat: string; note: string };
  onSetShowExerciseForm: (v: boolean | ((prev: boolean) => boolean)) => void;
  onSetExerciseToAdd: (v: { day: string; name: string; sets: string; reps: string; load: string }) => void;
  onSetHistoryInput: (v: { date: string; weight: string; muscleMass: string; bodyFat: string; note: string }) => void;
  onUpdateField: (field: keyof Student, value: string) => void;
  onAddExercise: () => void;
  onRemoveExercise: (day: string, idx: number) => void;
  onAddHistoryEntry: () => void;
  onDelete: () => void;
  onClose: () => void;
}

export function StudentProfile({
  student, showExerciseForm, exerciseToAdd, historyInput,
  onSetShowExerciseForm, onSetExerciseToAdd, onSetHistoryInput,
  onUpdateField, onAddExercise, onRemoveExercise, onAddHistoryEntry, onDelete, onClose,
}: StudentProfileProps) {
  const { t } = useTranslations();
  const inputCls = "bg-zinc-950 border border-white/10 rounded-xl px-4 py-2 text-xs text-white outline-none";
  const hasOtherDays = (student.availableDays ?? "").startsWith(OTHER_DAYS_PREFIX);

  return (
    <motion.div key="workout" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }}
      className="bg-zinc-900/50 rounded-[40px] border border-white/10 p-8 relative">
      <div className="flex justify-between items-start mb-8">
        <div className="flex items-center gap-4">
          <div className="p-4 bg-orange-600 rounded-3xl"><Dumbbell className="text-white" size={32} /></div>
          <div>
            <h2 className="text-3xl font-black italic uppercase text-white tracking-tighter">{student.name}</h2>
            <p className="text-orange-500 text-xs font-black uppercase tracking-[0.2em]">{student.objective}</p>
          </div>
        </div>
        <button onClick={onClose} className="text-zinc-500 hover:text-white p-2 bg-white/5 rounded-full transition-colors cursor-pointer"><X size={24} /></button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mb-6">
        <Field label={t('personal.fullName')} required><input required value={student.name ?? ""} onChange={(e) => onUpdateField('name', e.target.value)} placeholder={t('personal.fullName')} className={inputCls} /></Field>
        <Field label={t('personal.cpf')} required><input required value={student.cpf ?? ""} onChange={(e) => onUpdateField('cpf', e.target.value)} placeholder="000.000.000-00" className={inputCls} /></Field>
        <Field label={t('personal.email')}><input value={student.email ?? ""} onChange={(e) => onUpdateField('email', e.target.value)} placeholder={t('personal.email')} className={inputCls} /></Field>
        <Field label={t('personal.phone')} required><input required value={student.phone ?? ""} onChange={(e) => onUpdateField('phone', e.target.value)} placeholder={t('personal.phone')} className={inputCls} /></Field>
        <Field label={t('personal.birthDate')} required><input required type="date" value={student.birthDate ?? ""} onChange={(e) => onUpdateField('birthDate', e.target.value)} className={`${inputCls} scheme-light`} /></Field>
        <Field label={t('personal.gender')} required>
          <select required value={student.gender ?? ""} onChange={(e) => onUpdateField('gender', e.target.value)} className={inputCls}>
            <option value="">{t('common.select')}</option>
            {GENDER_OPTIONS.map((o) => <option key={o.value} value={o.value}>{t(o.tKey ?? o.label)}</option>)}
          </select>
        </Field>
        <Field label={t('personal.mainObjective')} required><input required value={student.objective ?? ""} onChange={(e) => onUpdateField('objective', e.target.value)} placeholder={t('personal.mainObjective')} className={inputCls} /></Field>
        <Field label={t('personal.experienceLevel')} required>
          <select required value={student.experience ?? ""} onChange={(e) => onUpdateField('experience', e.target.value)} className={inputCls}>
            <option value="">{t('common.select')}</option>
            {EXPERIENCE_LEVELS.map((o) => <option key={o.value} value={o.value}>{t(o.tKey ?? o.label)}</option>)}
          </select>
        </Field>
        <Field label={t('personal.availableDays')} required>
          <select required value={hasOtherDays ? "other" : (student.availableDays ?? "")}
            onChange={(e) => onUpdateField('availableDays', e.target.value === "other" ? OTHER_DAYS_PREFIX : e.target.value)} className={inputCls}>
            <option value="">{t('common.select')}</option>
            {AVAILABLE_DAYS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{t(o.tKey ?? o.label)}</option>)}
          </select>
        </Field>
        {hasOtherDays && (
          <Field label={t('personal.customDays')} required className="md:col-span-2">
            <input required value={(student.availableDays ?? "").replace(OTHER_DAYS_PREFIX, "")}
              onChange={(e) => onUpdateField('availableDays', `${OTHER_DAYS_PREFIX}${e.target.value}`)} placeholder="Ex.: Seg, Ter e Sábado" className={inputCls} />
          </Field>
        )}
        <Field label={t('personal.height')}><input value={student.height ?? ""} onChange={(e) => onUpdateField('height', e.target.value)} placeholder={t('personal.height')} className={inputCls} /></Field>
        <Field label={t('personal.weight')}><input value={student.weight ?? ""} onChange={(e) => onUpdateField('weight', e.target.value)} placeholder={t('personal.weight')} className={inputCls} /></Field>
        <Field label={t('personal.bodyFat')}><input value={student.bodyFat ?? ""} onChange={(e) => onUpdateField('bodyFat', e.target.value)} placeholder={t('personal.bodyFat')} className={inputCls} /></Field>
        <Field label={t('personal.medicalRestrictions')}><input value={student.restrictions ?? ""} onChange={(e) => onUpdateField('restrictions', e.target.value)} placeholder={t('personal.medicalRestrictions')} className={inputCls} /></Field>
        <Field label={t('personal.injuries')}><input value={student.injuries ?? ""} onChange={(e) => onUpdateField('injuries', e.target.value)} placeholder={t('personal.injuries')} className={inputCls} /></Field>
        <Field label={t('personal.medications')}><input value={student.medications ?? ""} onChange={(e) => onUpdateField('medications', e.target.value)} placeholder={t('personal.medications')} className={inputCls} /></Field>
        <Field label={t('personal.generalNotes')} className="md:col-span-2">
          <textarea value={student.observations ?? ""} onChange={(e) => onUpdateField('observations', e.target.value)} placeholder={t('personal.generalNotes')} className={`${inputCls} min-h-24 resize-none`} />
        </Field>
      </div>

      <div className="flex gap-2 mb-6">
        <button onClick={() => onSetShowExerciseForm((p) => !p)} className="btn-primary">{t('personal.addExercises')}</button>
        <button onClick={onDelete} className="btn-primary bg-red-600/90 hover:bg-red-600">{t('personal.deleteStudent')}</button>
      </div>

      {showExerciseForm && (
        <motion.div initial={{ height: 0, opacity: 0 }} animate={{ height: "auto", opacity: 1 }}
          className="mb-8 p-6 bg-zinc-950/50 rounded-3xl border border-orange-500/20 grid grid-cols-1 md:grid-cols-4 gap-3">
          <Field label={t('personal.weekDay')} required>
            <select required value={exerciseToAdd.day} onChange={(e) => onSetExerciseToAdd({ ...exerciseToAdd, day: e.target.value })} className="bg-zinc-900 border border-white/5 rounded-xl px-4 py-2 text-xs text-white outline-none">
              {DAYS.map((day) => <option key={day.value} value={day.value}>{t(day.tKey ?? day.label)}</option>)}
            </select>
          </Field>
          <Field label={t('personal.exercise')} required>
            <input required value={exerciseToAdd.name} onChange={(e) => onSetExerciseToAdd({ ...exerciseToAdd, name: e.target.value })} placeholder={t('personal.exercise')} className="bg-zinc-900 border border-white/5 rounded-xl px-4 py-2 text-xs text-white focus:border-orange-500 outline-none" />
          </Field>
          <Field label={t('personal.sets')} required>
            <input required value={exerciseToAdd.sets} onChange={(e) => onSetExerciseToAdd({ ...exerciseToAdd, sets: e.target.value })} placeholder={t('personal.sets')} className="bg-zinc-900 border border-white/5 rounded-xl px-4 py-2 text-xs text-white focus:border-orange-500 outline-none" />
          </Field>
          <Field label={t('personal.reps')} required>
            <input required value={exerciseToAdd.reps} onChange={(e) => onSetExerciseToAdd({ ...exerciseToAdd, reps: e.target.value })} placeholder={t('personal.reps')} className="bg-zinc-900 border border-white/5 rounded-xl px-4 py-2 text-xs text-white focus:border-orange-500 outline-none" />
          </Field>
          <Field label={t('personal.load')}>
            <input value={exerciseToAdd.load} onChange={(e) => onSetExerciseToAdd({ ...exerciseToAdd, load: e.target.value })} placeholder={t('personal.load')} className="bg-zinc-900 border border-white/5 rounded-xl px-4 py-2 text-xs text-white focus:border-orange-500 outline-none" />
          </Field>
          <div className="md:col-span-3 flex items-end">
            <button onClick={onAddExercise} className="w-full bg-orange-600 text-white font-black italic uppercase text-[10px] rounded-xl hover:bg-orange-700 transition-all flex items-center justify-center gap-2 py-2 cursor-pointer">
              <Plus size={14} /> {t('training.add')}
            </button>
          </div>
        </motion.div>
      )}

      <h3 className="text-white font-black italic uppercase text-sm mb-4">{t('personal.fullSheet')}</h3>
      <div className="space-y-4 mb-8">
        {DAYS.map((day) => (
          <div key={day.value} className="bg-zinc-950/50 rounded-2xl border border-white/5 p-4">
            <p className="text-orange-500 font-black uppercase text-xs mb-3">{t(day.tKey ?? day.label)}</p>
            <div className="space-y-2">
              {(student.weeklyPlan[day.value] ?? []).length === 0 && <p className="text-[11px] text-zinc-500">{t('personal.noExercises')}</p>}
              {(student.weeklyPlan[day.value] ?? []).map((ex, idx) => (
                <div key={`${day.value}-${idx}`} className="flex items-center justify-between p-3 bg-zinc-900/50 rounded-xl border border-white/5">
                  <div>
                    <p className="font-black italic uppercase text-white text-xs">{ex.name}</p>
                    <p className="text-[10px] font-bold text-zinc-500 uppercase tracking-widest">{ex.sets} {t('chatbot.times')} {ex.reps}</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="bg-zinc-900 px-3 py-1 rounded-lg text-orange-500 font-black italic text-[10px] border border-white/5">{ex.load || "0kg"}</span>
                    <button onClick={() => onRemoveExercise(day.value, idx)} className="text-zinc-600 hover:text-red-500 transition-colors cursor-pointer"><Trash2 size={16} /></button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      <h3 className="text-white font-black italic uppercase text-sm mb-3">{t('personal.evolutionHistory')}</h3>
      <div className="grid grid-cols-1 md:grid-cols-5 gap-2 mb-3">
        <Field label={t('personal.date')} required><input required type="date" value={historyInput.date} onChange={(e) => onSetHistoryInput({ ...historyInput, date: e.target.value })} className={inputCls} /></Field>
        <Field label={t('personal.weight')} required><input required value={historyInput.weight} onChange={(e) => onSetHistoryInput({ ...historyInput, weight: e.target.value })} placeholder={t('personal.weight')} className={inputCls} /></Field>
        <Field label={t('personal.muscleGain')}><input value={historyInput.muscleMass} onChange={(e) => onSetHistoryInput({ ...historyInput, muscleMass: e.target.value })} placeholder={t('personal.muscleGain')} className={inputCls} /></Field>
        <Field label={t('personal.fatLoss')}><input value={historyInput.bodyFat} onChange={(e) => onSetHistoryInput({ ...historyInput, bodyFat: e.target.value })} placeholder={t('personal.fatLoss')} className={inputCls} /></Field>
        <div className="flex items-end">
          <button onClick={onAddHistoryEntry} className="w-full bg-orange-600 hover:bg-orange-700 rounded-xl px-4 py-2 text-[10px] font-black uppercase italic cursor-pointer">{t('personal.addHistory')}</button>
        </div>
      </div>
      <Field label={t('personal.evolutionNote')} className="mb-4">
        <textarea value={historyInput.note} onChange={(e) => onSetHistoryInput({ ...historyInput, note: e.target.value })} placeholder={t('personal.evolutionNote')} className={`w-full ${inputCls} min-h-20 resize-none`} />
      </Field>
      <div className="space-y-2">
        {student.progressHistory.map((entry, idx) => (
          <div key={`${entry.date}-${idx}`} className="p-4 bg-zinc-950/60 rounded-xl border border-white/5">
            <div className="flex flex-wrap gap-3 text-[10px] uppercase font-bold">
              <span className="text-zinc-400">{entry.date}</span>
              <span className="text-white">Peso: {entry.weight}</span>
              <span className="text-emerald-400">Massa: {entry.muscleMass}</span>
              <span className="text-orange-400">Gordura: {entry.bodyFat}</span>
            </div>
            {entry.note && <p className="text-[11px] text-zinc-300 mt-2">{entry.note}</p>}
          </div>
        ))}
      </div>
    </motion.div>
  );
}
