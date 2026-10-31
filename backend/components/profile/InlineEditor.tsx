"use client";

import React, { useRef, useEffect } from "react";
import { CheckCircle2, X } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";

interface InlineEditorProps {
  value: string;
  onChange: (v: string) => void;
  onSave: () => void;
  onCancel: () => void;
  placeholder?: string;
  maxLength?: number;
  size?: "md" | "lg";
  type?: "text" | "number";
  step?: string;
  suffix?: string;
}

export function InlineEditor({
  value,
  onChange,
  onSave,
  onCancel,
  placeholder,
  maxLength,
  size = "md",
  type = "text",
  step,
  suffix,
}: InlineEditorProps) {
  const { t } = useTranslations();
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
    inputRef.current?.select();
  }, []);

  const inputClass =
    size === "lg"
      ? "text-2xl sm:text-3xl font-black italic uppercase tracking-tighter"
      : "text-2xl font-black italic";

  return (
    <div className="flex items-center gap-2 w-full">
      <div className="relative flex-1 min-w-0">
        <input
          ref={inputRef}
          type={type}
          inputMode={type === "number" ? "decimal" : undefined}
          step={step}
          value={value}
          maxLength={maxLength}
          onChange={(e) => onChange(e.target.value)}
          onBlur={onSave}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              e.preventDefault();
              onSave();
            } else if (e.key === "Escape") {
              e.preventDefault();
              onCancel();
            }
          }}
          placeholder={placeholder}
          className={`bg-zinc-950/60 border border-orange-500/40 rounded-xl px-3 py-2 outline-none w-full text-white placeholder:text-zinc-600 focus:border-orange-500 ${inputClass} ${
            suffix ? "pr-10" : ""
          }`}
        />
        {suffix && (
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] font-black uppercase tracking-widest text-zinc-500">
            {suffix}
          </span>
        )}
      </div>
      <button
        type="button"
        onMouseDown={(e) => {
          e.preventDefault();
          onSave();
        }}
        aria-label={t('common.save')}
        className="p-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white cursor-pointer shrink-0 transition-colors"
      >
        <CheckCircle2 size={16} />
      </button>
      <button
        type="button"
        onMouseDown={(e) => {
          e.preventDefault();
          onCancel();
        }}
        aria-label={t('common.cancel')}
        className="p-2 rounded-xl bg-white/5 hover:bg-white/10 text-zinc-300 cursor-pointer shrink-0 transition-colors"
      >
        <X size={16} />
      </button>
    </div>
  );
}
