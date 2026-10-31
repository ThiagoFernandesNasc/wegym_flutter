"use client";

import React, { useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Mail, Loader2, CheckCircle, ArrowLeft } from "lucide-react";
import { motion } from "framer-motion";
import Link from "next/link";

export default function ForgotPasswordPage() {
  const { t } = useTranslations();
  const [email, setEmail] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMsg, setErrorMsg] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setStatus("loading");
    try {
      const res = await fetch("/api/auth/forgot-password", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "Erro ao enviar e-mail");
      }
      setStatus("success");
    } catch (err) {
      setErrorMsg((err as Error).message);
      setStatus("error");
    }
  };

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 flex items-center justify-center px-4">
        <div className="max-w-md w-full">
          <Link href="/login" className="flex items-center gap-2 text-zinc-500 hover:text-white mb-8 transition-colors">
            <ArrowLeft size={16} /> <span className="text-sm font-bold">{t("common.back")}</span>
          </Link>

          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-zinc-900/50 border border-white/10 rounded-3xl p-8">
            <h1 className="text-2xl font-black italic uppercase text-white mb-2">{t("login.forgotPassword")}</h1>
            <p className="text-zinc-500 text-sm mb-6">{t("login.forgotPasswordDescription")}</p>

            {status === "success" ? (
              <div className="text-center py-8">
                <CheckCircle size={48} className="mx-auto text-emerald-500 mb-4" />
                <p className="text-sm text-zinc-300">{t("login.forgotPasswordSuccess")}</p>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-4">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-zinc-400 uppercase ml-1 flex items-center gap-1">
                    <Mail className="w-3 h-3" /> {t("login.emailLabel")} <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder={t("login.emailPlaceholder")}
                    className="w-full px-4 py-3 rounded-xl border border-zinc-800 bg-zinc-800/50 text-white focus:border-orange-500 outline-none transition-all"
                    required
                  />
                </div>

                {status === "error" && (
                  <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="bg-red-500/10 border border-red-500/50 text-red-500 text-sm p-3 rounded-xl text-center font-bold">
                    {errorMsg}
                  </motion.div>
                )}

                <button
                  type="submit"
                  disabled={status === "loading"}
                  className="w-full bg-orange-500 hover:bg-orange-600 disabled:bg-zinc-700 text-black font-black py-4 rounded-xl shadow-lg uppercase italic tracking-tighter flex items-center justify-center cursor-pointer disabled:cursor-not-allowed"
                >
                  {status === "loading" ? <Loader2 className="w-6 h-6 animate-spin" /> : t("login.sendResetLink")}
                </button>
              </form>
            )}
          </motion.div>
        </div>
      </div>
    </AuthGuard>
  );
}
