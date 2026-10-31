"use client";

import React from "react";
import { Pencil } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import { InlineEditor } from "./InlineEditor";

interface EditableMetricProps {
  label: string;
  unit: string;
  icon: React.ComponentType<{ size?: number; className?: string }>;
  accentClass: string;
  editing: boolean;
  draft: string;
  setDraft: (v: string) => void;
  onStartEdit: () => void;
  onCommit: () => void;
  onCancel: () => void;
  display: string;
  step: string;
}

export function EditableMetric({
  label,
  unit,
  icon: Icon,
  accentClass,
  editing,
  draft,
  setDraft,
  onStartEdit,
  onCommit,
  onCancel,
  display,
  step,
}: EditableMetricProps) {
  const { t } = useTranslations();
  return (
    <div className="bg-zinc-950/60 border border-white/5 rounded-3xl p-5 flex flex-col gap-3 hover:border-white/10 transition-colors">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Icon size={16} className={accentClass} />
          <span className="text-[10px] font-black text-zinc-500 uppercase tracking-widest">
            {label}
          </span>
        </div>
        {!editing && (
          <button
            type="button"
            onClick={onStartEdit}
            aria-label={`${t('common.edit')} ${label}`}
            className="p-1.5 rounded-lg text-zinc-600 hover:text-orange-500 hover:bg-white/5 cursor-pointer transition-colors"
          >
            <Pencil size={12} />
          </button>
        )}
      </div>

      {editing ? (
        <InlineEditor
          value={draft}
          onChange={setDraft}
          onSave={onCommit}
          onCancel={onCancel}
          type="number"
          step={step}
          suffix={unit}
        />
      ) : (
        <button
          type="button"
          onClick={onStartEdit}
          className="text-left cursor-pointer"
          aria-label={`${t('common.edit')} ${label}`}
        >
          <p className="text-3xl font-black italic text-white leading-none">
            {display}
            {display !== "\u2014" && (
              <span className="text-sm font-bold text-zinc-500 ml-1.5">{unit}</span>
            )}
          </p>
        </button>
      )}
    </div>
  );
}
