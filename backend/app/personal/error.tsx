"use client";

import { useTranslations } from '@/lib/i18n/hook';

export default function PersonalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const { t } = useTranslations();
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 p-4">
      <div className="rounded-full bg-red-900/20 p-4">
        <svg className="size-8 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
      </div>
      <h2 className="text-lg font-semibold text-zinc-100">{t('personal.loadError')}</h2>
      <p className="text-sm text-zinc-500 text-center max-w-sm">{t('error.description')}</p>
      {error.digest && <p className="text-xs text-zinc-600">Código: {error.digest}</p>}
      <button
        onClick={reset}
        className="rounded-lg bg-orange-600 px-6 py-2 text-sm font-medium text-white transition-colors hover:bg-orange-500"
      >
        {t('error.retry')}
      </button>
    </div>
  );
}
