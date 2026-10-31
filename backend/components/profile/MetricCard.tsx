"use client";

import React from "react";

interface MetricCardProps {
  label: string;
  unit: string;
  unitClass?: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  accentClass: string;
  display: string;
}

export function MetricCard({ label, unit, unitClass, icon: Icon, accentClass, display }: MetricCardProps) {
  return (
    <div className="bg-zinc-950/60 border border-white/5 rounded-3xl p-5 flex flex-col gap-3">
      <div className="flex items-center gap-2">
        <Icon size={16} className={accentClass} />
        <span className="text-[10px] font-black text-zinc-500 uppercase tracking-widest">
          {label}
        </span>
      </div>
      <div>
        <p className="text-3xl font-black italic text-white leading-none">{display}</p>
        <p className={`text-[10px] font-black uppercase tracking-widest mt-2 ${unitClass}`}>
          {unit}
        </p>
      </div>
    </div>
  );
}
