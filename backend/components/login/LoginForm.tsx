"use client";

import React from "react";
import { Eye, EyeOff, Mail, Lock, Loader2 } from "lucide-react";
import { motion } from "framer-motion";
import { useTranslations } from "@/lib/i18n/hook";

interface LoginFormProps {
  formData: { email: string; password: string };
  showPassword: boolean;
  isLoading: boolean;
  error: string | null;
  onInputChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
  onTogglePassword: () => void;
  onSubmit: (e: React.FormEvent) => void;
}

export function LoginForm({
  formData,
  showPassword,
  isLoading,
  error,
  onInputChange,
  onTogglePassword,
  onSubmit,
}: LoginFormProps) {
  const { t } = useTranslations();
  const inputClass = "w-full px-4 py-3 rounded-xl border border-zinc-800 bg-zinc-800/50 text-white focus:border-orange-500 outline-none transition-all";
  const labelClass = "text-xs font-bold text-zinc-400 uppercase ml-1 flex items-center gap-1";

  return (
    <motion.div key="login" initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: 10 }}>
      <h3 className="text-4xl font-black text-white mb-2 italic">{t('login.title')}</h3>
      <p className="text-zinc-500 mb-8 font-medium">{t('login.subtitle')}</p>
      <form className="space-y-4" onSubmit={onSubmit}>
        <div className="space-y-1">
          <label className={labelClass}><Mail className="w-3 h-3" /> {t('login.emailLabel')} <span className="text-red-500">*</span></label>
          <input type="email" name="email" value={formData.email} onChange={onInputChange} placeholder={t('login.emailPlaceholder')} className={inputClass} required />
        </div>
        <div className="space-y-1">
          <div className="flex justify-between items-center px-1">
            <label className={labelClass}><Lock className="w-3 h-3" /> {t('login.passwordLabel')} <span className="text-red-500">*</span></label>
            <button type="button" onClick={() => window.location.href = '/forgot-password'} className="text-xs font-bold text-orange-500 hover:text-orange-400 cursor-pointer">{t('login.forgotPassword')}</button>
          </div>
          <div className="relative">
            <input type={showPassword ? "text" : "password"} name="password" value={formData.password} onChange={onInputChange} placeholder="••••••••" className={inputClass} required />
            <button type="button" onClick={onTogglePassword} className="absolute right-4 top-1/2 -translate-y-1/2 text-zinc-500 hover:text-white cursor-pointer">
              {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
        </div>
        {error && (
          <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="bg-red-500/10 border border-red-500/50 text-red-500 text-sm p-3 rounded-xl text-center font-bold">
            {error}
          </motion.div>
        )}
        <motion.button disabled={isLoading} whileHover={{ scale: 1.01 }} whileTap={{ scale: 0.99 }} className="w-full bg-orange-500 hover:bg-orange-600 disabled:bg-zinc-700 text-black font-black py-4 rounded-xl shadow-lg uppercase italic tracking-tighter flex items-center justify-center cursor-pointer disabled:cursor-not-allowed">
          {isLoading ? <Loader2 className="w-6 h-6 animate-spin" /> : t('login.signIn')}
        </motion.button>
      </form>
    </motion.div>
  );
}
