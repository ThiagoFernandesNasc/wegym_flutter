"use client";

import { WeeklyClass } from "@/types/personal";

interface AgendaItemProps {
  item: WeeklyClass;
  studentName: string;
  onOpenStudent: () => void;
}

export function AgendaItem({ item, studentName, onOpenStudent }: AgendaItemProps) {
  return (
    <button onClick={onOpenStudent}
      className="w-full text-left bg-zinc-900/30 hover:bg-zinc-900/60 border border-white/5 rounded-2xl p-4 flex items-center justify-between transition-colors">
      <div>
        <p className="text-sm font-black italic uppercase text-white">{studentName}</p>
        <p className="text-[11px] text-zinc-400">{item.day} · {item.time} · {item.type}</p>
      </div>
      <div className="text-xs text-zinc-500">{item.status}</div>
    </button>
  );
}
