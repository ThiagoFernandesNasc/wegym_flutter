"use client";

import React from "react";
import { useRouter } from "next/navigation";
import {
  Target,
  ClipboardCheck,
  MessageCircle,
  MessageSquare,
  BookOpen,
  Apple,
  Award,
  Swords,
  Calendar,
  LineChart,
  Grid3X3,
} from "lucide-react";
import { SectionHeader } from "./SectionHeader";

const RESOURCES = [
  { href: "/goals", icon: Target, label: "Metas", desc: "Objetivos SMART", color: "text-emerald-400", bg: "bg-emerald-600/20" },
  { href: "/checkin", icon: ClipboardCheck, label: "Check-in", desc: "Registro diário", color: "text-blue-400", bg: "bg-blue-600/20" },
  { href: "/feed", icon: MessageCircle, label: "Feed", desc: "Compartilhe treinos", color: "text-orange-500", bg: "bg-orange-600/20" },
  { href: "/chat", icon: MessageSquare, label: "Chat", desc: "Fale com personal", color: "text-purple-400", bg: "bg-purple-600/20" },
  { href: "/programs", icon: BookOpen, label: "Programas", desc: "Treinos pré-montados", color: "text-rose-400", bg: "bg-rose-600/20" },
  { href: "/nutrition", icon: Apple, label: "Nutrição", desc: "Diário alimentar", color: "text-lime-400", bg: "bg-lime-600/20" },
  { href: "/achievements", icon: Award, label: "Conquistas", desc: "Badges e medalhas", color: "text-yellow-400", bg: "bg-yellow-600/20" },
  { href: "/challenges", icon: Swords, label: "Desafios", desc: "Compita com amigos", color: "text-cyan-400", bg: "bg-cyan-600/20" },
  { href: "/appointments", icon: Calendar, label: "Agenda", desc: "Agende sessões", color: "text-violet-400", bg: "bg-violet-600/20" },
  { href: "/measurements", icon: LineChart, label: "Evolução", desc: "Gráficos de progresso", color: "text-pink-400", bg: "bg-pink-600/20" },
];

export function ResourcesSection() {
  const router = useRouter();
  return (
    <section className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8">
      <SectionHeader eyebrow="Recursos" title="Todas as funcionalidades" icon={Grid3X3} />
      <div className="mt-6 grid grid-cols-2 sm:grid-cols-3 gap-3">
        {RESOURCES.map((r) => {
          const Icon = r.icon;
          return (
            <button
              key={r.href}
              type="button"
              onClick={() => router.push(r.href)}
              className="bg-zinc-950/60 border border-white/5 hover:border-white/10 rounded-3xl p-4 text-left cursor-pointer transition-colors group"
            >
              <div className={`w-10 h-10 rounded-2xl ${r.bg} ${r.color} flex items-center justify-center mb-3 group-hover:scale-105 transition-transform`}>
                <Icon size={18} />
              </div>
              <p className="text-xs font-black italic uppercase text-white tracking-tight">{r.label}</p>
              <p className="text-[9px] text-zinc-500 mt-1">{r.desc}</p>
            </button>
          );
        })}
      </div>
    </section>
  );
}
