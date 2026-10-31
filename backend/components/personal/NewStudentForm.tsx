"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { useTranslations } from "@/lib/i18n/hook";
import { Field } from "@/components/ui/DashboardElements";
import { EXPERIENCE_LEVELS, GENDER_OPTIONS, AVAILABLE_DAYS_OPTIONS, OTHER_DAYS_PREFIX } from "@/constants/options";

type StudentForm = {
  id: string; name: string; email: string; cpf: string; birthDate: string; phone: string;
  gender: string; emergencyContact: string; experience: string; objective: string; plan: string;
  height: string; weight: string; availableDays: string; notes: string; bodyFat: string;
  restrictions: string; injuries: string; medications: string; observations: string;
};

interface NewStudentFormProps {
  form: StudentForm;
  onSetForm: (v: StudentForm | ((prev: StudentForm) => StudentForm)) => void;
  onSave: () => void;
  onCancel: () => void;
}

export function NewStudentForm({ form, onSetForm, onSave, onCancel }: NewStudentFormProps) {
  const { t } = useTranslations();
  const inputCls = "bg-zinc-900 border border-white/10 rounded-xl px-4 py-2 text-xs outline-none text-white";
  const hasOtherDays = form.availableDays.startsWith(OTHER_DAYS_PREFIX);

  return (
    <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }}
      className="mb-8 bg-zinc-900/50 rounded-4xl border border-orange-500/20 p-6">
      <h2 className="text-lg font-black italic uppercase text-white mb-4">{t('personal.studentRegistration')}</h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
        <Field label={t('personal.fullName')} required><input required value={form.name} onChange={(e) => onSetForm({ ...form, name: e.target.value })} placeholder={t('personal.fullName')} className={inputCls} /></Field>
        <Field label={t('personal.cpf')} required><input required value={form.cpf} onChange={(e) => onSetForm({ ...form, cpf: e.target.value })} placeholder="000.000.000-00" className={inputCls} /></Field>
        <Field label={t('personal.email')}><input value={form.email} onChange={(e) => onSetForm({ ...form, email: e.target.value })} placeholder={t('personal.email')} className={inputCls} /></Field>
        <Field label={t('personal.phone')} required><input required value={form.phone} onChange={(e) => onSetForm({ ...form, phone: e.target.value })} placeholder={t('personal.phone')} className={inputCls} /></Field>
        <Field label={t('personal.birthDate')} required><input required type="date" value={form.birthDate} onChange={(e) => onSetForm({ ...form, birthDate: e.target.value })} className={`${inputCls} scheme-light`} /></Field>
        <Field label={t('personal.gender')} required>
          <select required value={form.gender} onChange={(e) => onSetForm({ ...form, gender: e.target.value })} className={inputCls}>
            <option value="">{t('common.select')}</option>
            {GENDER_OPTIONS.map((o) => <option key={o.value} value={o.value}>{t(o.tKey ?? o.label)}</option>)}
          </select>
        </Field>
        <Field label={t('personal.emergencyContact')}><input value={form.emergencyContact} onChange={(e) => onSetForm({ ...form, emergencyContact: e.target.value })} placeholder={t('personal.emergencyContact')} className={inputCls} /></Field>
        <Field label={t('personal.mainObjective')} required><input required value={form.objective} onChange={(e) => onSetForm({ ...form, objective: e.target.value })} placeholder={t('personal.mainObjective')} className={inputCls} /></Field>
        <Field label={t('personal.experienceLevel')} required>
          <select required value={form.experience} onChange={(e) => onSetForm({ ...form, experience: e.target.value })} className={inputCls}>
            <option value="">{t('common.select')}</option>
            {EXPERIENCE_LEVELS.map((o) => <option key={o.value} value={o.value}>{t(o.tKey ?? o.label)}</option>)}
          </select>
        </Field>
        <Field label={t('personal.availableDays')} required>
          <select required value={hasOtherDays ? "other" : form.availableDays}
            onChange={(e) => onSetForm({ ...form, availableDays: e.target.value === "other" ? OTHER_DAYS_PREFIX : e.target.value })} className={inputCls}>
            <option value="">{t('common.select')}</option>
            {AVAILABLE_DAYS_OPTIONS.map((o) => <option key={o.value} value={o.value}>{t(o.tKey ?? o.label)}</option>)}
          </select>
        </Field>
        {hasOtherDays && (
          <Field label={t('personal.customDays')} required className="md:col-span-3">
            <input required value={form.availableDays.replace(OTHER_DAYS_PREFIX, "")}
              onChange={(e) => onSetForm({ ...form, availableDays: `${OTHER_DAYS_PREFIX}${e.target.value}` })} placeholder="Ex.: Seg, Ter e Sábado" className={inputCls} />
          </Field>
        )}
        <Field label={t('personal.height')}><input value={form.height} onChange={(e) => onSetForm({ ...form, height: e.target.value })} placeholder={t('personal.height')} className={inputCls} /></Field>
        <Field label={t('personal.weight')}><input value={form.weight} onChange={(e) => onSetForm({ ...form, weight: e.target.value })} placeholder={t('personal.weight')} className={inputCls} /></Field>
        <Field label={t('personal.bodyFat')}><input value={form.bodyFat} onChange={(e) => onSetForm({ ...form, bodyFat: e.target.value })} placeholder={t('personal.bodyFat')} className={inputCls} /></Field>
        <Field label={t('personal.medicalRestrictions')} className="md:col-span-2"><input value={form.restrictions} onChange={(e) => onSetForm({ ...form, restrictions: e.target.value })} placeholder={t('personal.medicalRestrictions')} className={inputCls} /></Field>
        <Field label={t('personal.injuries')}><input value={form.injuries} onChange={(e) => onSetForm({ ...form, injuries: e.target.value })} placeholder={t('personal.injuries')} className={inputCls} /></Field>
        <Field label={t('personal.medications')}><input value={form.medications} onChange={(e) => onSetForm({ ...form, medications: e.target.value })} placeholder={t('personal.medications')} className={inputCls} /></Field>
        <Field label={t('personal.plan')}><input value={form.plan} onChange={(e) => onSetForm({ ...form, plan: e.target.value })} placeholder="Basic, Premium..." className={inputCls} /></Field>
        <Field label={t('personal.generalNotes')} className="md:col-span-3">
          <textarea value={form.observations} onChange={(e) => onSetForm({ ...form, observations: e.target.value })} placeholder="Rotina, preferências e observações" className={`${inputCls} min-h-24 resize-none`} />
        </Field>
      </div>
      <div className="mt-4 flex gap-2">
        <button onClick={onSave} className="btn-primary">{t('personal.saveStudent')}</button>
        <button onClick={onCancel} className="bg-white/10 hover:bg-white/20 rounded-xl px-4 py-2 text-[11px] font-black uppercase italic cursor-pointer">{t('common.cancel')}</button>
      </div>
    </motion.div>
  );
}
