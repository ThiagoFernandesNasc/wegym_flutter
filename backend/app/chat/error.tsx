"use client";

import { useTranslations } from '@/lib/i18n/hook';

export default function ChatError({
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
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
      </div>
      <h2 className="text-lg font-semibold text-zinc-100">{t('chat.loadError')}</h2>
      <p className="text-sm text-zinc-500 text-center max-w-sm">{t('chat.loadErrorDesc')}</p>
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
