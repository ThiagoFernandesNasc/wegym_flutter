"use client";

import React, { useCallback, useEffect, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import {
  Activity,
  CheckCircle2,
  ChevronRight,
  HeartPulse,
  Loader2,
  Plug,
  RefreshCw,
  X,
} from "lucide-react";

type ProviderId = "strava" | "google_fit";

type IntegrationData = {
  id: string;
  provider: ProviderId;
  enabled: boolean;
  syncEnabled: boolean;
  lastSyncAt: string | null;
  createdAt: string;
  providerData: {
    athleteId?: number;
    firstName?: string;
    lastName?: string;
    avatar?: string;
  } | null;
};

interface IntegrationsSectionProps {
  triggerToast: (msg: string, tone?: "success" | "info") => void;
}

const PROVIDER_CONFIG: Record<ProviderId, {
  icon: React.ComponentType<{ size?: number; className?: string }>;
  nameKey: string;
  descKey: string;
  color: string;
  bgColor: string;
}> = {
  strava: {
    icon: Activity,
    nameKey: "integrations.strava.name",
    descKey: "integrations.strava.description",
    color: "text-orange-500",
    bgColor: "bg-orange-600/20",
  },
  google_fit: {
    icon: HeartPulse,
    nameKey: "integrations.googleFit.name",
    descKey: "integrations.googleFit.description",
    color: "text-blue-400",
    bgColor: "bg-blue-600/20",
  },
};

function ProviderIcon({ providerId, className }: { providerId: ProviderId; className?: string }) {
  const ExternalIcon = providerId === "strava" ? StravaLogo : GoogleFitLogo;
  return <ExternalIcon className={className} />;
}

function StravaLogo({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="currentColor" className={className}>
      <path d="M15.387 17.944l-2.089-4.116h-3.065L15.387 24l5.15-10.172h-3.066m-7.008-5.526l3.958 7.793 3.343-7.793m-8.258 8.5h3.066L7.522 6.772 4.46 13.822Z"/>
    </svg>
  );
}

function GoogleFitLogo({ className }: { className?: string }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" className={className} stroke="currentColor" strokeWidth="1.5">
      <circle cx="12" cy="12" r="9"/>
      <path d="M7.5 12h9M12 7.5v9"/>
    </svg>
  );
}

export default function IntegrationsSection({ triggerToast }: IntegrationsSectionProps) {
  const { t } = useTranslations();
  const [integrations, setIntegrations] = useState<IntegrationData[]>([]);
  const [syncing, setSyncing] = useState<ProviderId | null>(null);
  const [loading, setLoading] = useState(true);

  const loadIntegrations = useCallback(async () => {
    try {
      const res = await fetch("/api/integrations", { credentials: "include" });
      if (res.ok) {
        const data = (await res.json()) as IntegrationData[];
        setIntegrations(data);
      }
    } catch {
      // silent
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadIntegrations();
  }, [loadIntegrations]);

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const provider = params.get("integration") as ProviderId | null;
    const success = params.get("success");
    const error = params.get("error");

    if (provider && success) {
      triggerToast(t("integrations.syncSuccess").replace("{imported}", ""));
      void loadIntegrations();
      window.history.replaceState({}, "", "/profile");
    } else if (provider && error) {
      triggerToast(t("integrations.error.connectFailed"), "info");
      window.history.replaceState({}, "", "/profile");
    }
  }, [triggerToast, t, loadIntegrations]);

  const handleConnect = useCallback(async (provider: ProviderId) => {
    try {
      const res = await fetch("/api/integrations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ provider }),
      });

      if (!res.ok) {
        triggerToast(t("integrations.error.connectFailed"), "info");
        return;
      }

      const { url } = (await res.json()) as { url: string };
      window.location.href = url;
    } catch {
      triggerToast(t("integrations.error.connectFailed"), "info");
    }
  }, [triggerToast, t]);

  const handleDisconnect = useCallback(async (provider: ProviderId) => {
    try {
      const res = await fetch("/api/integrations", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify({ provider }),
      });

      if (res.ok) {
        setIntegrations((prev) => prev.filter((i) => i.provider !== provider));
        triggerToast(t("integrations.disconnect") + "!");
      }
    } catch {
      triggerToast(t("integrations.error.connectFailed"), "info");
    }
  }, [triggerToast, t]);

  const handleSync = useCallback(async (provider: ProviderId) => {
    setSyncing(provider);
    try {
      const res = await fetch(`/api/integrations/${provider}/sync`, {
        method: "POST",
        credentials: "include",
      });

      if (res.ok) {
        const { imported } = (await res.json()) as { imported: number };
        triggerToast(t("integrations.syncSuccess").replace("{imported}", String(imported)));
        void loadIntegrations();
      } else {
        triggerToast(t("integrations.syncFailed"), "info");
      }
    } catch {
      triggerToast(t("integrations.syncFailed"), "info");
    } finally {
      setSyncing(null);
    }
  }, [triggerToast, t, loadIntegrations]);

  const isConnected = (provider: ProviderId) => integrations.some((i) => i.provider === provider);
  const getIntegration = (provider: ProviderId) => integrations.find((i) => i.provider === provider);

  const formatLastSync = (iso: string | null) => {
    if (!iso) return t("integrations.neverSynced");
    try {
      return t("integrations.lastSync").replace("{date}", new Date(iso).toLocaleString());
    } catch {
      return t("integrations.neverSynced");
    }
  };

  const providers: ProviderId[] = ["strava", "google_fit"];

  if (loading) {
    return (
      <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
        <SectionHeader
          eyebrow={t("integrations.title")}
          title={t("integrations.subtitle")}
          icon={Plug}
        />
        <div className="mt-6 space-y-3">
          {[1, 2].map((i) => (
            <div key={i} className="bg-zinc-950/60 border border-white/5 rounded-4xl p-4 sm:p-5 animate-pulse">
              <div className="h-12 w-12 rounded-2xl bg-zinc-800/40" />
              <div className="mt-3 space-y-2">
                <div className="h-4 w-24 bg-zinc-800/40 rounded" />
                <div className="h-3 w-48 bg-zinc-800/30 rounded" />
              </div>
            </div>
          ))}
        </div>
      </section>
    );
  }

  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <SectionHeader
        eyebrow={t("integrations.title")}
        title={t("integrations.subtitle")}
        icon={Plug}
      />

      <div className="mt-6 space-y-3">
        {providers.map((provider) => {
          const cfg = PROVIDER_CONFIG[provider];
          const connected = isConnected(provider);
          const integration = getIntegration(provider);
          const Icon = cfg.icon;
          const isSyncingThis = syncing === provider;

          return (
            <div
              key={provider}
              className={`rounded-4xl border p-4 sm:p-5 transition-colors ${
                connected
                  ? "bg-emerald-600/5 border-emerald-500/20"
                  : "bg-zinc-950/60 border-white/5 hover:border-white/10"
              }`}
            >
              <div className="flex items-start gap-4">
                <div className={`w-12 h-12 rounded-2xl ${cfg.bgColor} ${cfg.color} flex items-center justify-center shrink-0`}>
                  <Icon size={22} />
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-black italic uppercase text-white tracking-tight">
                      {t(cfg.nameKey)}
                    </p>
                    {connected && (
                      <CheckCircle2 size={14} className="text-emerald-400 shrink-0" />
                    )}
                  </div>
                  <p className="text-[10px] text-zinc-500 mt-0.5">
                    {t(cfg.descKey)}
                  </p>
                  {connected && (
                    <p className="text-[9px] text-zinc-600 mt-1 font-medium">
                      {formatLastSync(integration?.lastSyncAt ?? null)}
                    </p>
                  )}
                  {connected && integration?.providerData?.firstName && (
                    <p className="text-[9px] text-zinc-600 mt-0.5 font-medium">
                      {integration.providerData.firstName} {integration.providerData.lastName}
                    </p>
                  )}
                </div>

                <div className="flex items-center gap-2 shrink-0">
                  {connected ? (
                    <>
                      <button
                        type="button"
                        onClick={() => handleSync(provider)}
                        disabled={isSyncingThis}
                        className="p-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-zinc-300 hover:text-white cursor-pointer transition-colors disabled:opacity-50 disabled:cursor-wait"
                        aria-label={t("integrations.sync")}
                      >
                        {isSyncingThis ? (
                          <Loader2 size={14} className="animate-spin" />
                        ) : (
                          <RefreshCw size={14} />
                        )}
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDisconnect(provider)}
                        className="p-2.5 rounded-xl bg-rose-600/10 hover:bg-rose-600/20 text-rose-400 cursor-pointer transition-colors"
                        aria-label={t("integrations.disconnect")}
                      >
                        <X size={14} />
                      </button>
                    </>
                  ) : (
                    <button
                      type="button"
                      onClick={() => handleConnect(provider)}
                      className="px-3 py-2.5 rounded-xl bg-orange-600 hover:bg-orange-700 text-white text-[10px] font-black uppercase italic tracking-wider cursor-pointer transition-colors flex items-center gap-1.5"
                    >
                      {t("integrations.connect")}
                      <ChevronRight size={12} />
                    </button>
                  )}
                </div>
              </div>
            </div>
          );
        })}

        {/* Coming soon */}
        {(["healthConnect", "appleHealth", "garmin"] as const).map((key) => (
          <div
            key={key}
            className="rounded-4xl border border-white/5 bg-zinc-950/40 p-4 sm:p-5 flex items-center gap-4 opacity-50"
          >
            <div className="w-12 h-12 rounded-2xl bg-white/5 text-zinc-500 flex items-center justify-center shrink-0">
              <Plug size={20} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-black italic uppercase text-zinc-500 tracking-tight">
                {t(`integrations.${key}.name`)}
              </p>
              <p className="text-[10px] text-zinc-600 mt-0.5">
                {t(`integrations.${key}.description`)}
              </p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}

function SectionHeader({
  eyebrow,
  title,
  icon: Icon,
}: {
  eyebrow: string;
  title: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
}) {
  return (
    <div className="flex items-start justify-between gap-4">
      <div className="min-w-0">
        <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500 mb-1">
          {eyebrow}
        </p>
        <h2 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white leading-tight">
          {title}
        </h2>
      </div>
      <Icon size={20} className="text-orange-500 opacity-50 shrink-0" />
    </div>
  );
}
