"use client";

import React, { useState } from "react";
import Link from "next/link";
import { ChevronRight, Download, Info, Loader2, ShieldCheck, X } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { SectionHeader } from "./SectionHeader";

export function DataPrivacySection({ triggerToast }: { triggerToast: (msg: string, tone?: "success" | "info") => void }) {
  const { t } = useTranslations();
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [deleteText, setDeleteText] = useState("");
  const [isDeleting, setIsDeleting] = useState(false);
  const [isExporting, setIsExporting] = useState(false);

  const handleExport = async () => {
    setIsExporting(true);
    try {
      const res = await fetch("/api/user/export", { credentials: "include" });
      if (!res.ok) {
        const err = (await res.json().catch(() => ({}))) as { error?: string };
        triggerToast(err.error || t('profile.exportError'), "info");
        return;
      }
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "dados-pessoais.json";
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      triggerToast(t('profile.exportSuccess'));
    } catch {
      triggerToast(t('profile.exportFailed'), "info");
    } finally {
      setIsExporting(false);
    }
  };

  const handleDelete = async () => {
    if (deleteText !== "EXCLUIR") return;
    setIsDeleting(true);
    try {
      const res = await fetch("/api/user/account", { method: "DELETE", credentials: "include" });
      if (res.ok) {
        triggerToast(t('profile.accountDeleted'));
        window.location.href = "/";
      } else {
        const err = (await res.json().catch(() => ({}))) as { error?: string };
        triggerToast(err.error || t('profile.deleteError'), "info");
      }
    } catch {
      triggerToast(t('profile.deleteFailed'), "info");
    } finally {
      setIsDeleting(false);
      setShowDeleteConfirm(false);
      setDeleteText("");
    }
  };

  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <SectionHeader eyebrow={t('profile.lgpd')} title={t('profile.personalData')} icon={ShieldCheck} />

      <div className="mt-6 space-y-3">
        <button
          type="button"
          onClick={handleExport}
          disabled={isExporting}
          className="w-full rounded-4xl border border-white/5 bg-zinc-950/60 hover:border-white/10 p-4 sm:p-5 flex items-center gap-4 text-left cursor-pointer transition-colors disabled:opacity-60"
        >
          <div className="w-12 h-12 rounded-2xl bg-blue-600/20 text-blue-400 flex items-center justify-center shrink-0">
            {isExporting ? <Loader2 size={20} className="animate-spin" /> : <Download size={20} />}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500">{t('profile.portability')}</p>
            <p className="text-sm font-black italic uppercase text-white tracking-tight truncate">
              {isExporting ? t('common.loading') : t('profile.exportData')}
            </p>
            <p className="text-[10px] text-zinc-500 mt-0.5 truncate">{t('profile.exportDescription')}</p>
          </div>
          <Download size={16} className="text-zinc-500 shrink-0" />
        </button>

        {!showDeleteConfirm ? (
          <button
            type="button"
            onClick={() => setShowDeleteConfirm(true)}
            className="w-full rounded-4xl border border-rose-500/20 bg-rose-600/5 hover:bg-rose-600/10 p-4 sm:p-5 flex items-center gap-4 text-left cursor-pointer transition-colors"
          >
            <div className="w-12 h-12 rounded-2xl bg-rose-600/20 text-rose-400 flex items-center justify-center shrink-0">
              <X size={20} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500">{t('profile.deletion')}</p>
              <p className="text-sm font-black italic uppercase text-white tracking-tight truncate">{t('profile.deleteAccount')}</p>
              <p className="text-[10px] text-zinc-500 mt-0.5 truncate">{t('profile.deleteDescription')}</p>
            </div>
            <ChevronRight size={16} className="text-zinc-500 shrink-0" />
          </button>
        ) : (
          <div className="bg-rose-600/10 border border-rose-500/30 rounded-4xl p-5 space-y-4">
            <p className="text-xs text-zinc-300 leading-relaxed">{t('profile.deleteWarning')}</p>
            <label className="block text-[10px] font-black uppercase tracking-widest text-zinc-400">
              {t('profile.type')} <span className="text-rose-400">{t('profile.typeConfirm')}</span> {t('profile.toConfirm')}
            </label>
            <input
              type="text"
              value={deleteText}
              onChange={(e) => setDeleteText(e.target.value)}
              placeholder={t('profile.typeConfirm')}
              className="w-full bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-3 text-sm text-white placeholder:text-zinc-600 focus:border-rose-500 outline-none uppercase tracking-widest font-bold"
            />
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => { setShowDeleteConfirm(false); setDeleteText(""); }}
                disabled={isDeleting}
                className="flex-1 py-3 rounded-xl bg-zinc-800 hover:bg-zinc-700 text-zinc-300 text-xs font-black uppercase italic cursor-pointer transition-colors disabled:opacity-50"
              >
                {t('common.cancel')}
              </button>
              <button
                type="button"
                onClick={handleDelete}
                disabled={deleteText !== "EXCLUIR" || isDeleting}
                className="flex-1 py-3 rounded-xl bg-rose-600 hover:bg-rose-700 disabled:bg-zinc-700 text-white text-xs font-black uppercase italic cursor-pointer transition-colors disabled:cursor-not-allowed"
              >
                {isDeleting ? <Loader2 size={16} className="animate-spin mx-auto" /> : t('profile.confirmDeletion')}
              </button>
            </div>
          </div>
        )}

        <Link
          href="/privacy"
          className="w-full rounded-4xl border border-white/5 bg-zinc-950/60 hover:border-white/10 p-4 sm:p-5 flex items-center gap-4 text-left transition-colors"
        >
          <div className="w-12 h-12 rounded-2xl bg-orange-600/20 text-orange-400 flex items-center justify-center shrink-0">
            <Info size={20} />
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500">{t('profile.lgpd')}</p>
            <p className="text-sm font-black italic uppercase text-white tracking-tight truncate">{t('profile.privacyPolicy')}</p>
            <p className="text-[10px] text-zinc-500 mt-0.5 truncate">{t('profile.privacyDescription')}</p>
          </div>
          <ChevronRight size={16} className="text-zinc-500 shrink-0" />
        </Link>
      </div>
    </section>
  );
}
