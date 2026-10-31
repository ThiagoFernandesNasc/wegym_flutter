"use client";

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import Link from 'next/link';
import { useTranslations } from '@/lib/i18n/hook';
import { useRouter } from 'next/navigation';
import { toast } from 'sonner';

const LGPD_CONSENT_KEY = 'wegym_lgpd_consent';

export function ConsentBanner() {
  const { t } = useTranslations();
  const router = useRouter();
  const [mounted, setMounted] = useState(false);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    setMounted(true);
    setVisible(!localStorage.getItem(LGPD_CONSENT_KEY));
  }, []);

  const accept = async () => {
    try {
      await fetch('/api/user/consent', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ termsAccepted: true, privacyAccepted: true, dataConsent: true }),
      });
      localStorage.setItem(LGPD_CONSENT_KEY, new Date().toISOString());
      setVisible(false);
      toast.success(t('consent.accepted'));
    } catch (err) {
      toast.error(t('consent.error'));
    }
  };

  if (!mounted) return null;

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          initial={{ y: 100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 100, opacity: 0 }}
          className="fixed bottom-0 left-0 right-0 z-200 p-4 sm:p-6"
        >
          <div className="max-w-4xl mx-auto bg-zinc-900 border border-zinc-800 rounded-2xl shadow-2xl p-5 sm:p-6 flex flex-col sm:flex-row items-start sm:items-center gap-4">
            <div className="flex-1 space-y-2">
              <p className="text-sm font-black uppercase italic text-white">
                {t('consent.title')}
              </p>
              <p className="text-xs text-zinc-400 leading-relaxed">
                {t('consent.description')}{' '}
                <strong className="text-orange-500">{t('consent.lgpd')}</strong>.
                {' '}{t('consent.privacyPolicy')}{' '}
                <Link
                  href="/terms"
                  className="text-orange-500 underline hover:text-orange-400"
                  onClick={() => localStorage.setItem(LGPD_CONSENT_KEY, new Date().toISOString())}
                >
                  {t('consent.privacyPolicy')}
                </Link>.
              </p>
            </div>
            <div className="flex items-center gap-3 shrink-0">
              <Link
                href="/privacy"
                className="text-xs text-zinc-400 hover:text-white underline underline-offset-2 transition-colors"
                onClick={() => localStorage.setItem(LGPD_CONSENT_KEY, new Date().toISOString())}
              >
                {t('consent.learnMore')}
              </Link>
              <button
                type="button"
                onClick={accept}
                className="px-6 py-2.5 bg-orange-600 hover:bg-orange-700 text-white text-xs font-black uppercase italic rounded-xl transition-colors cursor-pointer"
              >
                {t('consent.accept')}
              </button>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
