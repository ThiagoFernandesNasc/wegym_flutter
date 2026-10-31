"use client";

import React from "react";
import {
  Dumbbell, Mail, Lock, User, IdCard, MapPin, ExternalLink,
  ChevronDown, Heart, Activity, CheckCircle2, Loader2,
} from "lucide-react";
import { motion } from "framer-motion";
import { useTranslations } from "@/lib/i18n/hook";
import { EXPERIENCE_OPTIONS } from "@/constants/options";

interface RegisterFormProps {
  userType: 'atleta' | 'personal';
  formData: {
    name: string; email: string; cpf: string; cep: string; city: string; state: string;
    password: string; confirmPassword: string; age: string; height: string; weight: string;
    sex: string; experienceLevel: string; injury: string; healthIssues: string;
    medications: string; cref: string;
  };
  isVerifyingCref: boolean;
  crefVerified: boolean;
  termsAccepted: boolean;
  privacyAccepted: boolean;
  isLoading: boolean;
  error: string | null;
  onInputChange: (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => void;
  onSetUserType: (type: 'atleta' | 'personal') => void;
  onVerifyCref: () => void;
  onSetTermsAccepted: (v: boolean) => void;
  onSetPrivacyAccepted: (v: boolean) => void;
  onSetFormData: (updater: (prev: RegisterFormProps['formData']) => RegisterFormProps['formData']) => void;
  onSubmit: (e: React.FormEvent) => void;
}

export function RegisterForm({
  userType, formData, isVerifyingCref, crefVerified, termsAccepted, privacyAccepted,
  isLoading, error, onInputChange, onSetUserType, onVerifyCref,
  onSetTermsAccepted, onSetPrivacyAccepted, onSetFormData, onSubmit,
}: RegisterFormProps) {
  const { t } = useTranslations();
  const inputClass = "w-full px-4 py-3 rounded-xl border border-zinc-800 bg-zinc-800/50 text-white focus:border-orange-500 outline-none transition-all";
  const labelClass = "text-xs font-bold text-zinc-400 uppercase ml-1 flex items-center gap-1";
  const selectClass = "w-full px-4 py-3 rounded-xl border border-zinc-800 bg-zinc-800/50 text-white focus:border-orange-500 outline-none transition-all appearance-none cursor-pointer";
  const textareaClass = "w-full px-4 py-3 rounded-xl border border-zinc-800 bg-zinc-800/50 text-white focus:border-orange-500 outline-none transition-all resize-none";
  const sectionTitleClass = "md:col-span-2 text-xs font-black text-orange-500 uppercase tracking-widest pt-2 pb-1 border-b border-zinc-800 flex items-center gap-2";

  return (
    <motion.div key="signup" initial={{ opacity: 0, x: 10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -10 }}>
      <h3 className="text-4xl font-black text-white mb-2 italic uppercase">{t('register.title')}</h3>
      <p className="text-zinc-500 mb-6 font-medium">{t('register.subtitle')}</p>

      <div className="grid grid-cols-2 gap-4 mb-8">
        <button type="button" onClick={() => onSetUserType('atleta')}
          className={`py-3 px-4 rounded-xl border flex items-center justify-center gap-2 font-bold transition-all cursor-pointer ${userType === 'atleta' ? 'border-orange-500 bg-orange-500/10 text-orange-400' : 'border-zinc-800 bg-zinc-800/50 text-zinc-400 hover:border-zinc-600'}`}>
          <Dumbbell className="w-4 h-4" /> {t('register.userTypeAthlete')}
        </button>
        <button type="button" onClick={() => onSetUserType('personal')}
          className={`py-3 px-4 rounded-xl border flex items-center justify-center gap-2 font-bold transition-all cursor-pointer ${userType === 'personal' ? 'border-orange-500 bg-orange-500/10 text-orange-400' : 'border-zinc-800 bg-zinc-800/50 text-zinc-400 hover:border-zinc-600'}`}>
          <IdCard className="w-4 h-4" /> {t('register.userTypePersonal')}
        </button>
      </div>

      <form className="grid grid-cols-1 md:grid-cols-2 gap-4" onSubmit={onSubmit}>
        {userType === 'atleta' && (
          <>
            <p className={sectionTitleClass}><User className="w-3.5 h-3.5" /> {t('register.personalData')}</p>
            <div className="space-y-1 md:col-span-2">
              <label className={labelClass}><User className="w-3 h-3" /> {t('register.fullName')} <span className="text-red-500">*</span></label>
              <input type="text" name="name" value={formData.name} onChange={onInputChange} placeholder={t('register.fullName')} className={inputClass} required />
            </div>
            <div className="space-y-1">
              <label className={labelClass}><IdCard className="w-3 h-3" /> {t('register.cpf')} <span className="text-red-500">*</span></label>
              <input type="text" name="cpf" value={formData.cpf} onChange={onInputChange} placeholder={t('register.cpfPlaceholder')} className={inputClass} required />
            </div>
            <div className="space-y-1">
              <label className={labelClass}><Mail className="w-3 h-3" /> {t('register.emailLabel')} <span className="text-red-500">*</span></label>
              <input type="email" name="email" value={formData.email} onChange={onInputChange} placeholder={t('login.emailPlaceholder')} className={inputClass} required />
            </div>
            <div className="space-y-1">
              <div className="flex justify-between items-center px-1">
                <label className={labelClass}><MapPin className="w-3 h-3" /> {t('register.zipCode')} <span className="text-red-500">*</span></label>
                <a href="https://buscacepinter.correios.com.br/app/endereco/index.php" target="_blank" rel="noopener noreferrer" className="text-[10px] font-bold text-orange-500 flex items-center hover:underline uppercase italic cursor-pointer">{t('register.dontKnowZip')} <ExternalLink className="w-2 h-2 ml-1" /></a>
              </div>
              <input type="text" name="cep" value={formData.cep} onChange={onInputChange} placeholder={t('register.zipPlaceholder')} className={inputClass} required />
            </div>
            <div className="space-y-1 grid grid-cols-3 gap-2">
              <div className="col-span-2">
                <label className={labelClass}>{t('register.city')} <span className="text-red-500">*</span></label>
                <input type="text" name="city" value={formData.city} onChange={onInputChange} placeholder={t('register.city')} className={inputClass} required />
              </div>
              <div>
                <label className={labelClass}>{t('register.state')} <span className="text-red-500">*</span></label>
                <input type="text" name="state" value={formData.state} onChange={onInputChange} placeholder={t('register.state')} className={inputClass + " text-center"} maxLength={2} required />
              </div>
            </div>

            <p className={sectionTitleClass}><Activity className="w-3.5 h-3.5" /> {t('register.physicalInfo')}</p>
            <div className="space-y-1">
              <label className={labelClass}>{t('register.age')} <span className="text-red-500">*</span></label>
              <input type="number" name="age" value={formData.age} onChange={onInputChange} placeholder={t('register.agePlaceholder')} min={10} max={100} className={inputClass} required />
            </div>
            <div className="space-y-1">
              <label className={labelClass}>{t('register.gender')} <span className="text-red-500">*</span></label>
              <div className="relative">
                <select name="sex" value={formData.sex} onChange={onInputChange} className={selectClass} aria-label={t('register.gender')} required>
                  <option value="" disabled>{t('register.selectDefault')}</option>
                  <option value="masculino">{t('register.genderMale')}</option>
                  <option value="feminino">{t('register.genderFemale')}</option>
                  <option value="outro">{t('register.genderOther')}</option>
                </select>
                <ChevronDown className="w-4 h-4 text-zinc-500 absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              </div>
            </div>
            <div className="space-y-1">
              <label className={labelClass}>{t('register.height')} <span className="text-red-500">*</span></label>
              <input type="number" name="height" value={formData.height} onChange={onInputChange} placeholder={t('register.heightPlaceholder')} min={100} max={250} className={inputClass} required />
            </div>
            <div className="space-y-1">
              <label className={labelClass}>{t('register.weight')} <span className="text-red-500">*</span></label>
              <input type="number" name="weight" value={formData.weight} onChange={onInputChange} placeholder={t('register.weightPlaceholder')} min={30} max={300} className={inputClass} required />
            </div>
            <div className="space-y-1 md:col-span-2">
              <label className={labelClass}><Dumbbell className="w-3 h-3" /> {t('register.experienceLevel')} <span className="text-red-500">*</span></label>
              <div className="grid grid-cols-3 gap-2">
                {EXPERIENCE_OPTIONS.map(opt => (
                  <button key={opt.value} type="button"
                    onClick={() => onSetFormData(prev => ({ ...prev, experienceLevel: opt.value }))}
                    className={`flex flex-col items-center justify-center py-3 px-2 rounded-xl border text-center transition-all cursor-pointer ${formData.experienceLevel === opt.value ? 'border-orange-500 bg-orange-500/10 text-orange-400' : 'border-zinc-800 bg-zinc-800/50 text-zinc-400 hover:border-zinc-600'}`}>
                    <span className="text-sm font-black">{opt.label}</span>
                    <span className="text-[10px] mt-0.5 opacity-70">{opt.sub}</span>
                  </button>
                ))}
              </div>
            </div>

            <p className={sectionTitleClass}><Heart className="w-3.5 h-3.5" /> {t('register.health')}</p>
            <div className="space-y-1 md:col-span-2">
              <label className={labelClass}>{t('register.injury')}</label>
              <textarea name="injury" value={formData.injury} onChange={onInputChange} placeholder={t('register.injuryPlaceholder')} rows={2} className={textareaClass} />
            </div>
            <div className="space-y-1 md:col-span-2">
              <label className={labelClass}>{t('register.healthIssues')}</label>
              <textarea name="healthIssues" value={formData.healthIssues} onChange={onInputChange} placeholder={t('register.healthIssuesPlaceholder')} rows={2} className={textareaClass} />
            </div>
            <div className="space-y-1 md:col-span-2">
              <label className={labelClass}>{t('register.medications')}</label>
              <input type="text" name="medications" value={formData.medications} onChange={onInputChange} placeholder={t('register.medicationsPlaceholder')} className={inputClass} />
            </div>
          </>
        )}

        {userType === 'personal' && (
          <div className="md:col-span-2 space-y-4">
            {!crefVerified ? (
              <div className="space-y-4 bg-zinc-800/20 p-6 rounded-2xl border border-zinc-800">
                <p className="text-zinc-400 text-sm mb-2 font-medium">{t('register.crefDescription')}</p>
                <div className="space-y-1">
                  <label className={labelClass}><IdCard className="w-3 h-3" /> {t('register.crefNumber')} <span className="text-red-500">*</span></label>
                  <input type="text" name="cref" value={formData.cref} onChange={onInputChange} placeholder={t('register.crefPlaceholder')} className={inputClass} required />
                </div>
                <motion.button type="button" onClick={onVerifyCref}
                  disabled={isVerifyingCref || formData.cref.length < 5}
                  className="w-full bg-zinc-800 hover:bg-zinc-700 disabled:bg-zinc-900 border border-zinc-700 text-white font-bold py-3 rounded-xl transition-all flex items-center justify-center cursor-pointer disabled:cursor-not-allowed">
                  {isVerifyingCref ? <Loader2 className="w-5 h-5 animate-spin" /> : t('register.verifyCref')}
                </motion.button>
              </div>
            ) : (
              <motion.div initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
                <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 p-4 rounded-xl flex items-center gap-3">
                  <CheckCircle2 className="w-5 h-5 shrink-0" />
                  <span className="text-sm font-bold">{t('register.crefVerified')}</span>
                </div>
                <p className={sectionTitleClass}><User className="w-3.5 h-3.5" /> {t('register.personalDataTitle')}</p>
                <div className="space-y-1">
                  <label className={labelClass}><User className="w-3 h-3" /> {t('register.fullName')} <span className="text-red-500">*</span></label>
                  <input type="text" name="name" value={formData.name} onChange={onInputChange} placeholder={t('register.fullName')} className={inputClass} required />
                </div>
                <div className="space-y-1">
                  <label className={labelClass}><Mail className="w-3 h-3" /> {t('login.emailLabel')} <span className="text-red-500">*</span></label>
                  <input type="email" name="email" value={formData.email} onChange={onInputChange} placeholder={t('login.emailPlaceholder')} className={inputClass} required />
                </div>
              </motion.div>
            )}
          </div>
        )}

        {(userType === 'atleta' || (userType === 'personal' && crefVerified)) && (
          <>
            <p className={sectionTitleClass}><Lock className="w-3.5 h-3.5" /> {t('register.security')}</p>
            <div className="space-y-1">
              <label className={labelClass}><Lock className="w-3 h-3" /> {t('login.passwordLabel')} <span className="text-red-500">*</span></label>
              <input type="password" name="password" value={formData.password} onChange={onInputChange} placeholder="••••••••" className={inputClass} required />
            </div>
            <div className="space-y-1">
              <label className={labelClass}><Lock className="w-3 h-3" /> {t('register.confirmPassword')} <span className="text-red-500">*</span></label>
              <input type="password" name="confirmPassword" value={formData.confirmPassword} onChange={onInputChange} placeholder="••••••••" className={inputClass} required />
            </div>
          </>
        )}

        {!false && error && (
          <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="md:col-span-2 bg-red-500/10 border border-red-500/50 text-red-500 text-sm p-3 rounded-xl text-center font-bold">
            {error}
          </motion.div>
        )}

        {(userType === 'atleta' || (userType === 'personal' && crefVerified)) && (
          <>
            <div className="md:col-span-2 space-y-3 pt-2 border-t border-zinc-800">
              <p className={sectionTitleClass}>{t('register.privacy')}</p>
              <label className="flex items-start gap-3 cursor-pointer text-left">
                <input type="checkbox" checked={termsAccepted} onChange={(e) => onSetTermsAccepted(e.target.checked)} className="mt-1 rounded border-zinc-600 accent-orange-500" required />
                <span className="text-xs text-zinc-400 leading-relaxed">
                  Aceito os{' '}
                  <a href="/terms" target="_blank" className="text-orange-500 underline hover:text-orange-400">{t('register.termsOfUse')}</a>{' '}
                  e autorizo o tratamento dos meus dados conforme a{' '}
                  <a href="/privacy" target="_blank" className="text-orange-500 underline hover:text-orange-400">{t('register.privacyPolicy')}</a>{' '}
                  (LGPD). <span className="text-red-500">*</span>
                </span>
              </label>
              <label className="flex items-start gap-3 cursor-pointer text-left">
                <input type="checkbox" checked={privacyAccepted} onChange={(e) => onSetPrivacyAccepted(e.target.checked)} className="mt-1 rounded border-zinc-600 accent-orange-500" required />
                <span className="text-xs text-zinc-400 leading-relaxed">{t('register.emailConsent')}</span>
              </label>
            </div>
            <motion.button disabled={isLoading} whileHover={{ scale: 1.01 }} whileTap={{ scale: 0.99 }}
              className="md:col-span-2 w-full bg-white hover:bg-zinc-200 disabled:bg-zinc-700 text-black font-black py-4 rounded-xl shadow-lg uppercase italic mt-4 flex items-center justify-center cursor-pointer disabled:cursor-not-allowed">
              {isLoading ? <Loader2 className="w-6 h-6 animate-spin text-black" /> : t('register.submit')}
            </motion.button>
          </>
        )}
      </form>
    </motion.div>
  );
}
