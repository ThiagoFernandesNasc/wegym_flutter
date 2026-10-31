"use client";

import React from "react";

interface SectionHeaderProps {
  eyebrow: string;
  title: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
}

export function SectionHeader({ eyebrow, title, icon: Icon }: SectionHeaderProps) {
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
