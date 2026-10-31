"use client";

import React from "react";
import { AnimatePresence, motion } from "framer-motion";
import { CheckCircle2, Info } from "lucide-react";

type ToastTone = "success" | "info";

export function Toast({ toast }: { toast: { msg: string; tone: ToastTone } | null }) {
  return (
    <div className="fixed bottom-6 right-6 z-60 pointer-events-none">
      <AnimatePresence>
        {toast && (
          <motion.div
            initial={{ y: 16, opacity: 0, scale: 0.96 }}
            animate={{ y: 0, opacity: 1, scale: 1 }}
            exit={{ y: 16, opacity: 0, scale: 0.96 }}
            transition={{ duration: 0.18, ease: "easeOut" }}
            className={`pointer-events-auto flex items-center gap-3 px-4 py-3 rounded-2xl shadow-xl backdrop-blur-md border ${
              toast.tone === "success"
                ? "bg-emerald-600/15 border-emerald-500/30 text-emerald-100"
                : "bg-zinc-900/95 border-white/10 text-zinc-100"
            }`}
            role="status"
            aria-live="polite"
          >
            {toast.tone === "success" ? (
              <CheckCircle2 size={16} className="text-emerald-400 shrink-0" />
            ) : (
              <Info size={16} className="text-zinc-400 shrink-0" />
            )}
            <span className="text-[11px] font-black italic uppercase tracking-wider">
              {toast.msg}
            </span>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
