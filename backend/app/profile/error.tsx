"use client";

import { useTranslations } from '@/lib/i18n/hook';

export default function ProfileError({
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
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        </svg>
      </div>
      <h2 className="text-lg font-semibold text-zinc-100">{t('profile.loadError')}</h2>
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
