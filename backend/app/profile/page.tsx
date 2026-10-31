"use client";

export const dynamic = 'force-dynamic';

import React, { useCallback, useEffect, useMemo, useRef, useState, startTransition } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { useRouter } from "next/navigation";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { ScrollReveal } from "@/components/ui/ScrollReveal";
import { ParallaxField } from "@/components/ui/ParallaxField";
import {
  Activity,
  Camera,
  CheckCircle2,
  Heart,
  Info,
  Loader2,
  Mail,
  MapPin,
  Pencil,
  Ruler,
  ShieldCheck,
  Trophy,
  User as UserIcon,
  Weight,
  X,
  IdCard,
} from "lucide-react";
import { BluetoothManager, type HRData, type DeviceInfo, type ConnectionState } from "@/lib/bluetooth";
import { usePWAInstall } from "@/hooks/use-pwa-install";
import IntegrationsSection from "@/components/integrations/IntegrationsSection";

import { Toast } from "@/components/profile/Toast";
import { SectionHeader } from "@/components/profile/SectionHeader";
import { Pill } from "@/components/profile/Pill";
import { InlineEditor } from "@/components/profile/InlineEditor";
import { EditableMetric } from "@/components/profile/EditableMetric";
import { MetricCard } from "@/components/profile/MetricCard";
import { AccountSection } from "@/components/profile/AccountSection";
import { CredentialSection } from "@/components/profile/CredentialSection";
import { DevicesSection } from "@/components/profile/DevicesSection";
import { PwaSection } from "@/components/profile/PwaSection";
import { ResourcesSection } from "@/components/profile/ResourcesSection";
import { ProfileSkeleton } from "@/components/profile/ProfileSkeleton";
import { DataPrivacySection } from "@/components/profile/DataPrivacySection";

const EXPERIENCE_LABEL: Record<string, string> = {
  iniciante: "experienceLevel.beginner",
  intermediario: "experienceLevel.intermediate",
  avancado: "experienceLevel.advanced",
};

type ApiProfile = {
  id: string;
  email: string;
  role: "atleta" | "personal";
  createdAt: string;
  avatarPlaceholder: string;
  athlete: {
    name: string;
    city: string;
    state: string;
    age: number;
    heightCm: number;
    weightKg: number;
    experienceLevel: string;
  } | null;
  personal: { name: string; cref: string } | null;
};

type LocalUser = {
  userId: string;
  nome: string;
  foto: string;
  pesoKg: number;
  alturaCm: number;
  email: string;
  role: "atleta" | "personal";
  memberSinceLabel: string;
  experienceLabel: string;
  cityState: string;
  cref: string;
};

type LoadState = "loading" | "error" | "ready";
type EditableField = "name" | "weight" | "height" | null;
type ToastTone = "success" | "info";

function formatMemberSince(iso: string) {
  try {
    return new Date(iso).toLocaleDateString(undefined, {
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  } catch {
    return "";
  }
}

function mapApiToLocal(data: ApiProfile, t: (key: string) => string): LocalUser {
  const since = formatMemberSince(data.createdAt);
  if (data.role === "atleta" && data.athlete) {
    const a = data.athlete;
    return {
      userId: data.id,
      nome: a.name,
      foto: data.avatarPlaceholder,
      pesoKg: a.weightKg,
      alturaCm: a.heightCm,
      email: data.email,
      role: "atleta",
      memberSinceLabel: since,
      experienceLabel: (EXPERIENCE_LABEL[a.experienceLevel] && t(EXPERIENCE_LABEL[a.experienceLevel])) || a.experienceLevel,
      cityState: `${a.city} \u00b7 ${a.state}`,
      cref: "",
    };
  }
  if (data.role === "personal" && data.personal) {
    const p = data.personal;
    return {
      userId: data.id,
      nome: p.name,
      foto: data.avatarPlaceholder,
      pesoKg: 0,
      alturaCm: 0,
      email: data.email,
      role: "personal",
      memberSinceLabel: since,
      experienceLabel: t('profile.rolePersonal'),
      cityState: "",
      cref: p.cref,
    };
  }
  return {
    userId: data.id,
    nome: t('profile.defaultName'),
    foto: data.avatarPlaceholder,
    pesoKg: 0,
    alturaCm: 0,
    email: data.email,
    role: data.role,
    memberSinceLabel: since,
    experienceLabel: "",
    cityState: "",
    cref: "",
  };
}

function imcCategory(imc: number, t: (key: string) => string): { label: string; tone: string } {
  if (imc < 18.5) return { label: t('profile.imcUnderweight'), tone: "text-blue-400" };
  if (imc < 25) return { label: t('profile.imcHealthy'), tone: "text-emerald-400" };
  if (imc < 30) return { label: t('profile.imcOverweight'), tone: "text-amber-400" };
  return { label: t('profile.imcObese'), tone: "text-rose-400" };
}

function IdentityCard({
  userData,
  isAtleta,
  editing,
  draft,
  setDraft,
  onStartEdit,
  onCommit,
  onCancel,
  onAvatarChange,
}: {
  userData: LocalUser;
  isAtleta: boolean;
  editing: boolean;
  draft: string;
  setDraft: (v: string) => void;
  onStartEdit: () => void;
  onCommit: () => void;
  onCancel: () => void;
  onAvatarChange: () => void;
}) {
  const { t } = useTranslations();
  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
        <div className="relative shrink-0">
          <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-3xl bg-zinc-950 border border-white/10 overflow-hidden">
            <img
              src={userData.foto}
              alt={userData.nome}
              loading="lazy"
              width={250}
              height={250}
              className="w-full h-full object-cover"
            />
          </div>
          <label
            className="absolute -bottom-1.5 -right-1.5 bg-orange-600 hover:bg-orange-700 p-2 rounded-2xl border-4 border-zinc-950 text-white cursor-pointer transition-colors"
            aria-label={t('profile.changePhoto')}
          >
            <Camera size={14} />
            <input type="file" accept="image/*" className="hidden" onChange={onAvatarChange} />
          </label>
        </div>

        <div className="flex-1 min-w-0 w-full text-center sm:text-left">
          <p className="text-[9px] font-black uppercase tracking-[0.25em] text-zinc-500 mb-1.5">
            {t('profile.identity')}
          </p>

          {editing ? (
            <InlineEditor
              value={draft}
              onChange={setDraft}
              onSave={onCommit}
              onCancel={onCancel}
              placeholder={t('profile.namePlaceholder')}
              maxLength={64}
              size="lg"
            />
          ) : (
            <button
              type="button"
              onClick={onStartEdit}
              className="group inline-flex items-center gap-2 mx-auto sm:mx-0 cursor-pointer text-left"
              aria-label={t('common.edit')}
            >
              <h2 className="text-2xl sm:text-3xl font-black italic uppercase tracking-tighter text-white leading-tight">
                {userData.nome}
              </h2>
              <Pencil size={14} className="text-zinc-600 group-hover:text-orange-500 transition-colors shrink-0" />
            </button>
          )}

          <p className="text-zinc-400 text-xs mt-2 flex items-center gap-2 justify-center sm:justify-start min-w-0">
            <Mail size={12} className="text-zinc-500 shrink-0" />
            <span className="truncate">{userData.email}</span>
          </p>
          <p className="text-zinc-500 text-[10px] font-bold uppercase tracking-widest mt-1 flex items-center gap-2 justify-center sm:justify-start">
            {t('profile.memberSince')} {userData.memberSinceLabel}
          </p>

          <div className="mt-4 flex flex-wrap gap-2 justify-center sm:justify-start">
            <Pill icon={ShieldCheck} label={isAtleta ? t('profile.roleAthlete') : t('profile.rolePersonal')} accent="orange" />
            {userData.experienceLabel && isAtleta && <Pill icon={Trophy} label={userData.experienceLabel} />}
            {isAtleta && userData.cityState && <Pill icon={MapPin} label={userData.cityState} />}
            {!isAtleta && userData.cref && <Pill icon={IdCard} label={`CREF ${userData.cref}`} />}
          </div>
        </div>
      </div>
    </section>
  );
}

function PhysicalDataSection({
  pesoKg,
  alturaCm,
  imc,
  editingField,
  draft,
  setDraft,
  onStartEdit,
  onCommit,
  onCancel,
}: {
  pesoKg: number;
  alturaCm: number;
  imc: number | null;
  editingField: EditableField;
  draft: string;
  setDraft: (v: string) => void;
  onStartEdit: (field: NonNullable<EditableField>) => void;
  onCommit: () => void;
  onCancel: () => void;
}) {
  const { t } = useTranslations();
  const imcInfo = imc != null ? imcCategory(imc, t) : null;

  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <SectionHeader eyebrow={t('profile.physicalData')} title={t('profile.yourMeasurements')} icon={Activity} />
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mt-6">
        <EditableMetric
          label={t('profile.weight')} unit="kg" icon={Weight} accentClass="text-orange-500"
          editing={editingField === "weight"} draft={draft} setDraft={setDraft}
          onStartEdit={() => onStartEdit("weight")} onCommit={onCommit} onCancel={onCancel}
          display={pesoKg > 0 ? pesoKg.toFixed(1) : "\u2014"} step="0.1"
        />
        <EditableMetric
          label={t('profile.height')} unit="cm" icon={Ruler} accentClass="text-blue-400"
          editing={editingField === "height"} draft={draft} setDraft={setDraft}
          onStartEdit={() => onStartEdit("height")} onCommit={onCommit} onCancel={onCancel}
          display={alturaCm > 0 ? String(alturaCm) : "\u2014"} step="1"
        />
        <MetricCard
          label={t('profile.imc')} unit={imcInfo?.label ?? t('profile.calculated')}
          unitClass={imcInfo?.tone ?? "text-zinc-600"} icon={Heart}
          accentClass="text-emerald-400" display={imc != null ? imc.toFixed(1) : "\u2014"}
        />
      </div>
      <p className="mt-4 text-[10px] text-zinc-600 font-medium leading-relaxed">{t('profile.imcHint')}</p>
    </section>
  );
}

export default function ProfilePage() {
  const { t } = useTranslations();
  const router = useRouter();
  const [loadState, setLoadState] = useState<LoadState>("loading");
  const [loadError, setLoadError] = useState<string | null>(null);
  const [userData, setUserData] = useState<LocalUser | null>(null);
  const [isPro] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const [bleState, setBleState] = useState<ConnectionState>("idle");
  const [bleDevice, setBleDevice] = useState<DeviceInfo | null>(null);
  const [lastHR, setLastHR] = useState<HRData | null>(null);
  const btRef = useRef<BluetoothManager | null>(null);
  const { isInstallable, install, isStandalone } = usePWAInstall();

  const [editingField, setEditingField] = useState<EditableField>(null);
  const [draft, setDraft] = useState("");

  const [toast, setToast] = useState<{ msg: string; tone: ToastTone } | null>(null);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  const triggerToast = useCallback((msg: string, tone: ToastTone = "success") => {
    setToast({ msg, tone });
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(null), 2400);
  }, []);

  useEffect(() => {
    return () => {
      if (toastTimer.current) clearTimeout(toastTimer.current);
    };
  }, []);

  const loadProfile = useCallback(async () => {
    setLoadState("loading");
    setLoadError(null);
    try {
      const res = await fetch("/api/user/profile", { credentials: "include" });
      if (res.status === 401) {
        router.replace("/");
        return;
      }
      if (!res.ok) {
        const j = (await res.json().catch(() => ({}))) as { error?: string };
        setLoadError(j.error || t('profile.loadError'));
        setLoadState("error");
        return;
      }
      const data = (await res.json()) as ApiProfile;
      setUserData(mapApiToLocal(data, t));
      setLoadState("ready");
    } catch {
      setLoadError(t('profile.connectionError'));
      setLoadState("error");
    }
  }, [router, t]);

  useEffect(() => {
    startTransition(() => {
      void loadProfile();
    });
  }, [loadProfile]);

  useEffect(() => {
    ["/pro", "/stats", "/home"].forEach((r) => router.prefetch(r));
  }, [router]);

  const persistField = useCallback(
    async (patch: { name?: string; weightKg?: number; heightCm?: number }) => {
      if (!userData) return;
      const res = await fetch("/api/user/profile", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        credentials: "include",
        body: JSON.stringify(patch),
      });
      if (res.ok) {
        const data = (await res.json()) as ApiProfile;
        setUserData(mapApiToLocal(data, t));
      } else {
        triggerToast(t('profile.saveError'), "info");
      }
    },
    [userData, triggerToast, t],
  );

  const startEdit = useCallback(
    (field: NonNullable<EditableField>) => {
      if (!userData) return;
      if (field === "name") setDraft(userData.nome);
      else if (field === "weight") setDraft(userData.pesoKg > 0 ? String(userData.pesoKg) : "");
      else if (field === "height") setDraft(userData.alturaCm > 0 ? String(userData.alturaCm) : "");
      setEditingField(field);
    },
    [userData],
  );

  const cancelEdit = useCallback(() => setEditingField(null), []);

  const commitEdit = useCallback(async () => {
    if (!editingField || !userData) {
      setEditingField(null);
      return;
    }
    const trimmed = draft.trim();
    if (editingField === "name") {
      if (trimmed && trimmed !== userData.nome) {
        setUserData({ ...userData, nome: trimmed });
        await persistField({ name: trimmed });
        triggerToast(t('profile.nameUpdated'));
      }
    } else if (editingField === "weight") {
      const n = parseFloat(trimmed.replace(",", "."));
      if (Number.isFinite(n) && n > 20 && n < 400 && n !== userData.pesoKg) {
        setUserData({ ...userData, pesoKg: n });
        await persistField({ weightKg: n });
        triggerToast(t('profile.weightUpdated'));
      } else if (trimmed && (!Number.isFinite(n) || n <= 20 || n >= 400)) {
        triggerToast(t('profile.weightRangeError'), "info");
      }
    } else if (editingField === "height") {
      const n = parseFloat(trimmed.replace(",", "."));
      const cm = Math.round(n);
      if (Number.isFinite(cm) && cm > 60 && cm < 250 && cm !== userData.alturaCm) {
        setUserData({ ...userData, alturaCm: cm });
        await persistField({ heightCm: cm });
        triggerToast(t('profile.heightUpdated'));
      } else if (trimmed && (!Number.isFinite(cm) || cm <= 60 || cm >= 250)) {
        triggerToast(t('profile.heightRangeError'), "info");
      }
    }
    setEditingField(null);
  }, [editingField, draft, userData, persistField, triggerToast, t]);

  const imc = useMemo(() => {
    if (!userData || userData.pesoKg <= 0 || userData.alturaCm <= 0) return null;
    const meters = userData.alturaCm / 100;
    const value = userData.pesoKg / (meters * meters);
    if (!Number.isFinite(value)) return null;
    return value;
  }, [userData]);

  const syncHealthData = useCallback(() => {
    if (isSyncing || bleState === "scanning" || bleState === "connecting") return;

    if (bleState === "connected" && btRef.current) {
      btRef.current.disconnect();
      setBleDevice(null);
      setLastHR(null);
      triggerToast(t('profile.disconnected'));
      return;
    }

    setIsSyncing(true);
    setBleState("scanning");

    const manager = new BluetoothManager({
      onHR: (data: HRData) => {
        setLastHR(data);
      },
      onState: (state: ConnectionState) => {
        setBleState(state);
        if (state === "connected" || state === "disconnected" || state === "unsupported" || state === "idle") {
          setIsSyncing(false);
        }
        if (state === "connected") {
          triggerToast(t('profile.smartwatchConnected'));
        }
        if (state === "unsupported") {
          triggerToast(t('profile.bluetoothUnsupported'), "info");
        }
      },
      onDevice: (device: DeviceInfo) => {
        setBleDevice(device);
      },
      onError: (error: string) => {
        triggerToast(error, "info");
      },
    }, t);

    btRef.current = manager;
    manager.scan();
  }, [isSyncing, bleState, triggerToast, t]);

  if (loadState === "error") {
    return (
      <AuthGuard>
        <div className="min-h-screen bg-zinc-950 text-white flex flex-col items-center justify-center gap-5 px-6 font-sans">
          <div className="w-12 h-12 rounded-2xl bg-rose-500/10 border border-rose-500/20 flex items-center justify-center">
            <Info size={22} className="text-rose-400" />
          </div>
          <p className="text-sm text-zinc-400 text-center max-w-sm">{loadError}</p>
          <button
            type="button"
            onClick={() => void loadProfile()}
            className="px-6 py-3 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-black uppercase italic text-xs tracking-wider cursor-pointer transition-colors"
          >
            {t('profile.retry')}
          </button>
        </div>
      </AuthGuard>
    );
  }

  if (loadState === "loading" || !userData) {
    return <AuthGuard><ProfileSkeleton /></AuthGuard>;
  }

  const isAtleta = userData.role === "atleta";

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 relative overflow-hidden antialiased font-sans">
        <ParallaxField variant="subtle" />
        <Toast toast={toast} />

        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4 pl-16 lg:pl-6 flex items-center justify-between gap-3">
          <div className="flex items-center gap-3 min-w-0">
            <UserIcon size={22} className="text-orange-500 shrink-0" />
            <h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white truncate">
              {t('profile.title')}
            </h1>
          </div>
        </header>

        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-6 relative z-10">
          <ScrollReveal>
            <IdentityCard
              userData={userData}
              isAtleta={isAtleta}
              editing={editingField === "name"}
              draft={draft}
              setDraft={setDraft}
              onStartEdit={() => startEdit("name")}
              onCommit={commitEdit}
              onCancel={cancelEdit}
              onAvatarChange={() => triggerToast(t('profile.avatarSoon'), "info")}
            />
          </ScrollReveal>

          {isAtleta ? (
            <ScrollReveal delay={0.06}>
              <PhysicalDataSection
                pesoKg={userData.pesoKg}
                alturaCm={userData.alturaCm}
                imc={imc}
                editingField={editingField}
                draft={draft}
                setDraft={setDraft}
                onStartEdit={startEdit}
                onCommit={commitEdit}
                onCancel={cancelEdit}
              />
            </ScrollReveal>
          ) : (
            <ScrollReveal delay={0.06}>
              <CredentialSection cref={userData.cref} />
            </ScrollReveal>
          )}

          <ScrollReveal delay={0.1}>
            <AccountSection isPro={isPro} onUpgrade={() => router.push("/pro")} />
          </ScrollReveal>
          <ScrollReveal delay={0.14}>
            <DataPrivacySection triggerToast={triggerToast} />
          </ScrollReveal>
          <ScrollReveal delay={0.18}>
            <ResourcesSection />
          </ScrollReveal>
          <ScrollReveal delay={0.22}>
            <DevicesSection
              bleState={bleState}
              bleDevice={bleDevice}
              lastHR={lastHR}
              onSync={syncHealthData}
              isSyncing={isSyncing}
            />
          </ScrollReveal>
          <ScrollReveal delay={0.26}>
            <IntegrationsSection triggerToast={triggerToast} />
          </ScrollReveal>
          <ScrollReveal delay={0.3}>
            <PwaSection isInstallable={isInstallable} isStandalone={isStandalone} onInstall={install} />
          </ScrollReveal>
        </main>
      </div>
    </AuthGuard>
  );
}
