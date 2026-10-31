"use client";

import { useTranslations } from '@/lib/i18n/hook';

export default function TrainingError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const { t } = useTranslations();
  const isGPS = error.message?.includes('GPS') || error.message?.includes('geolocation');
  const isBluetooth = error.message?.includes('Bluetooth') || error.message?.includes('bluetooth');

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 p-4">
      <div className="rounded-full bg-red-900/20 p-4">
        <svg className="size-8 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      </div>
      <h2 className="text-lg font-semibold text-zinc-100">
        {isGPS ? t('training.gpsError') : isBluetooth ? t('training.bluetoothError') : t('error.title')}
      </h2>
      <p className="text-sm text-zinc-500 text-center max-w-sm">
        {isGPS
          ? t('training.gpsErrorDesc')
          : isBluetooth
            ? t('training.bluetoothErrorDesc')
            : t('error.description')}
      </p>
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
