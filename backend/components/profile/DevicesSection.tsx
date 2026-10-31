"use client";

import React from "react";
import { Bluetooth, Watch, HeartPulse, Battery, ChevronRight, Loader2 } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import type { HRData, DeviceInfo, ConnectionState } from "@/lib/bluetooth";
import { SectionHeader } from "./SectionHeader";

interface DevicesSectionProps {
  bleState: ConnectionState;
  bleDevice: DeviceInfo | null;
  lastHR: HRData | null;
  onSync: () => void;
  isSyncing: boolean;
}

export function DevicesSection({ bleState, bleDevice, lastHR, onSync, isSyncing }: DevicesSectionProps) {
  const { t } = useTranslations();
  const stateLabel: Record<ConnectionState, string> = {
    idle: t('profile.connectSmartwatch'),
    scanning: t('profile.scanning'),
    connecting: t('profile.connecting'),
    connected: t('profile.disconnect'),
    disconnected: t('profile.connectionLost'),
    unsupported: t('profile.unsupported'),
  };

  const isBusy = bleState === "scanning" || bleState === "connecting" || isSyncing;
  const isConnected = bleState === "connected";

  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <SectionHeader eyebrow={t('profile.devices')} title={t('profile.smartwatchSensors')} icon={Watch} />
      <div className="mt-6 space-y-3">
        <button
          type="button"
          onClick={onSync}
          disabled={isBusy}
          className={`w-full rounded-4xl border p-4 sm:p-5 flex items-center gap-4 text-left cursor-pointer transition-colors disabled:cursor-wait disabled:opacity-80 ${
            isConnected
              ? "bg-emerald-600/10 border-emerald-500/30 hover:border-emerald-500/50"
              : "bg-zinc-950/60 border-white/5 hover:border-white/10"
          }`}
        >
          <div className={`w-12 h-12 rounded-2xl flex items-center justify-center shrink-0 ${
            isConnected ? "bg-emerald-600/20 text-emerald-400" : "bg-white/5 text-zinc-200"
          }`}>
            {isBusy ? (
              <Loader2 size={20} className="animate-spin text-orange-500" />
            ) : isConnected ? (
              <Bluetooth size={20} />
            ) : (
              <Watch size={20} />
            )}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500">{t('profile.bluetoothLE')}</p>
            <p className="text-sm font-black italic uppercase text-white tracking-tight truncate">
              {isConnected && bleDevice ? bleDevice.name : stateLabel[bleState]}
            </p>
            {isConnected && lastHR && (
              <p className="text-[10px] text-emerald-400 mt-0.5 font-bold">
                {lastHR.bpm} BPM &middot; {bleDevice?.battery != null ? `${bleDevice.battery}%` : t('profile.connected')}
              </p>
            )}
            {!isConnected && (
              <p className="text-[10px] text-zinc-500 mt-0.5 truncate">
                {bleState === "unsupported" ? t('bluetooth.unsupported') : isBusy ? t('profile.waitingForDevices') : t('profile.compatibleDescription')}
              </p>
            )}
          </div>
          <div className="flex items-center gap-2 shrink-0">
            {isConnected && lastHR && (
              <span className="text-2xl font-black italic text-emerald-400 tabular-nums">{lastHR.bpm}</span>
            )}
            <ChevronRight size={16} className="text-zinc-600" />
          </div>
        </button>

        <div className="bg-zinc-950/60 border border-white/5 rounded-3xl p-4">
          <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500 mb-2">{t('profile.compatibleDevices')}</p>
          <div className="flex flex-wrap gap-2">
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/5 border border-white/10 text-[10px] font-black uppercase italic tracking-wider text-zinc-300">
              <HeartPulse size={10} className="text-rose-400" /> {t('profile.appleWatch')}
            </span>
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/5 border border-white/10 text-[10px] font-black uppercase italic tracking-wider text-zinc-300">
              <HeartPulse size={10} className="text-emerald-400" /> {t('profile.googleFit')}
            </span>
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/5 border border-white/10 text-[10px] font-black uppercase italic tracking-wider text-zinc-300">
              <HeartPulse size={10} className="text-blue-400" /> {t('profile.garmin')}
            </span>
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/5 border border-white/10 text-[10px] font-black uppercase italic tracking-wider text-zinc-300">
              <HeartPulse size={10} className="text-orange-400" /> {t('profile.polar')}
            </span>
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/5 border border-white/10 text-[10px] font-black uppercase italic tracking-wider text-zinc-300">
              <Battery size={10} className="text-purple-400" /> {t('profile.hrBand')}
            </span>
          </div>
        </div>
      </div>
    </section>
  );
}
