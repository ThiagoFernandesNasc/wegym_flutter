"use client";

import React from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { ArrowLeft, FileText } from "lucide-react";
import Link from "next/link";

export default function TermsPage() {
  const { t } = useTranslations();
  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4 flex items-center gap-3">
          <Link href="/privacy" className="text-zinc-500 hover:text-white transition-colors">
            <ArrowLeft size={20} />
          </Link>
          <FileText size={20} className="text-orange-500" />
          <h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("terms.title")}</h1>
        </header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-6 text-sm text-zinc-400 leading-relaxed">
          <p><strong>{t("terms.lastUpdated")}</strong></p>

          <section>
            <h2 className="text-white font-black italic uppercase text-base mb-3">1. {t("terms.acceptanceTitle")}</h2>
            <p>{t("terms.acceptance")}</p>
          </section>

          <section>
            <h2 className="text-white font-black italic uppercase text-base mb-3">2. {t("terms.serviceTitle")}</h2>
            <p>{t("terms.service")}</p>
          </section>

          <section>
            <h2 className="text-white font-black italic uppercase text-base mb-3">3. {t("terms.accountTitle")}</h2>
            <p>{t("terms.account")}</p>
          </section>

          <section>
            <h2 className="text-white font-black italic uppercase text-base mb-3">4. {t("terms.userResponsibilitiesTitle")}</h2>
            <p>{t("terms.userResponsibilities")}</p>
          </section>

          <section>
            <h2 className="text-white font-black italic uppercase text-base mb-3">5. {t("terms.intellectualPropertyTitle")}</h2>
            <p>{t("terms.intellectualProperty")}</p>
          </section>

          <section>
            <h2 className="text-white font-black italic uppercase text-base mb-3">6. {t("terms.limitationTitle")}</h2>
            <p>{t("terms.limitation")}</p>
          </section>

          <section>
            <h2 className="text-white font-black italic uppercase text-base mb-3">7. {t("terms.changesTitle")}</h2>
            <p>{t("terms.changes")}</p>
          </section>

          <section>
            <h2 className="text-white font-black italic uppercase text-base mb-3">8. {t("terms.contactTitle")}</h2>
            <p>{t("terms.contact")}</p>
          </section>
        </main>
      </div>
    </AuthGuard>
  );
}
