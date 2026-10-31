"use client";

import React from "react";

interface PillProps {
  icon: React.ComponentType<{ size?: number; className?: string }>;
  label: string;
  accent?: "neutral" | "orange";
}

export function Pill({ icon: Icon, label, accent = "neutral" }: PillProps) {
  const cls =
    accent === "orange"
      ? "bg-orange-600/15 border-orange-500/30 text-orange-200"
      : "bg-white/5 border-white/10 text-zinc-300";
  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border text-[10px] font-black uppercase italic tracking-wider ${cls}`}
    >
      <Icon size={11} className="opacity-80" />
      {label}
    </span>
  );
}
