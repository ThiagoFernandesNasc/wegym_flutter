"use client";

import { createPortal } from "react-dom";
import { memo, useEffect, useCallback, useRef } from "react";
import { X } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { useTranslations } from "@/lib/i18n/hook";

interface ExerciseModalProps {
  ex: {
    name: string;
    muscle: string;
    sets: string | number;
    reps: string | number;
  };
  gifUrl: string;
  isOpen: boolean;
  onClose: () => void;
}

const ExerciseModalInner = memo(function ExerciseModalInner({
  ex,
  gifUrl,
  isOpen,
  onClose,
}: ExerciseModalProps) {
  const { t } = useTranslations();
  const modalRef = useRef<HTMLDivElement>(null);

  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if (e.key === "Escape") onClose();
  }, [onClose]);

  const handleBackdropClick = useCallback((e: React.MouseEvent) => {
    if (e.target === e.currentTarget) onClose();
  }, [onClose]);

  const handleCloseClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    onClose();
  }, [onClose]);

  useEffect(() => {
    if (!isOpen) return;
    window.addEventListener("keydown", handleKeyDown);
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = "";
    };
  }, [isOpen, handleKeyDown]);

  if (!isOpen) return null;

  const muscleColors: Record<string, string> = {
    Peito: "bg-rose-500/20 text-rose-300 border-rose-500/30",
    Costas: "bg-sky-500/20 text-sky-300 border-sky-500/30",
    Ombros: "bg-amber-500/20 text-amber-300 border-amber-500/30",
    "Bíceps": "bg-pink-500/20 text-pink-300 border-pink-500/30",
    Tríceps: "bg-purple-500/20 text-purple-300 border-purple-500/30",
    Antebraço: "bg-orange-500/20 text-orange-300 border-orange-500/30",
    Pernas: "bg-emerald-500/20 text-emerald-300 border-emerald-500/30",
    Glúteos: "bg-fuchsia-500/20 text-fuchsia-300 border-fuchsia-500/30",
    Core: "bg-cyan-500/20 text-cyan-300 border-cyan-500/30",
    Cardio: "bg-red-500/20 text-red-300 border-red-500/30",
    "Corpo Todo": "bg-indigo-500/20 text-indigo-300 border-indigo-500/30",
    Panturrilha: "bg-lime-500/20 text-lime-300 border-lime-500/30",
  };

  const muscleClass = muscleColors[ex.muscle] || "bg-zinc-500/20 text-zinc-300 border-zinc-500/30";

  return createPortal(
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.18 }}
        className="fixed inset-0 z-[9999] flex items-center justify-center p-4"
        onClick={handleBackdropClick}
        role="dialog"
        aria-modal="true"
        aria-labelledby="exercise-modal-title"
      >
        <div className="absolute inset-0 bg-black/85 backdrop-blur-md" />

        <motion.div
          ref={modalRef}
          initial={{ scale: 0.92, opacity: 0, y: 24 }}
          animate={{ scale: 1, opacity: 1, y: 0 }}
          exit={{ scale: 0.95, opacity: 0, y: -12 }}
          transition={{ type: "spring", stiffness: 320, damping: 28 }}
          className="relative w-full max-w-[480px] max-h-[85vh] overflow-hidden bg-[#121214] border border-zinc-800 rounded-[20px] shadow-[0_25px_50px_-12px_rgba(0,0,0,0.7)] flex flex-col"
        >
          <header className="flex items-start justify-between gap-4 p-5 border-b border-zinc-800 bg-gradient-to-b from-zinc-900/80 to-transparent">
            <div className="min-w-0 flex-1 pr-2">
              <h2
                id="exercise-modal-title"
                className="font-bold text-lg text-white tracking-tight leading-snug"
              >
                {ex.name}
              </h2>
              <div className="flex flex-wrap items-center gap-2 mt-3">
                <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-medium border ${muscleClass}`}>
                  {ex.muscle}
                </span>
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-white/5 text-zinc-300 border border-white/10">
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="text-orange-400">
                    <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
                    <path d="M12 7v5l3 3" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                  {ex.sets} x {ex.reps}
                </span>
              </div>
            </div>

            <motion.button
              whileHover={{ scale: 1.1, rotate: 90 }}
              whileTap={{ scale: 0.9 }}
              onClick={handleCloseClick}
              className="flex-shrink-0 w-9 h-9 rounded-xl bg-white/5 hover:bg-white/10 flex items-center justify-center transition-colors"
              aria-label={t("exercise.closeModal")}
            >
              <X size={18} className="text-zinc-400 hover:text-white transition-colors" />
            </motion.button>
          </header>

          <div className="flex-1 overflow-y-auto p-4 bg-zinc-900">
            <div className="relative rounded-xl overflow-hidden bg-zinc-900">
              <motion.img
                initial={{ scale: 1.03, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.45, ease: "easeOut" }}
                src={gifUrl}
                alt={ex.name}
                loading="lazy"
                className="w-full h-auto max-h-[320px] object-contain"
                style={{
                  backgroundColor: "#18181B",
                  mixBlendMode: "multiply" as const,
                }}
                onError={(e) => {
                  const target = e.target as HTMLImageElement;
                  target.src = `data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300" viewBox="0 0 400 300"><rect width="400" height="300" fill="%2318181b"/><text x="200" y="150" font-family="system-ui, sans-serif" font-size="14" fill="%2352525b" text-anchor="middle" dominant-baseline="middle">${t("exercise.gifUnavailable")}</text></svg>`;
                  target.style.mixBlendMode = "normal";
                }}
              />
            </div>
          </div>

          <footer className="p-5 border-t border-zinc-800 bg-zinc-950/80 backdrop-blur-sm">
            <motion.button
              whileHover={{ scale: 1.02, boxShadow: "0 4px 20px -4px rgba(249, 115, 22, 0.5)" }}
              whileTap={{ scale: 0.98 }}
              onClick={handleCloseClick}
              className="w-full py-3.5 px-6 rounded-xl bg-orange-500 font-bold text-sm uppercase tracking-wider text-zinc-950 hover:bg-orange-400 transition-all shadow-lg shadow-orange-500/30"
            >
              {t("exercise.closeModal")}
            </motion.button>
          </footer>
        </motion.div>
      </motion.div>
    </AnimatePresence>,
    document.body
  );
});

ExerciseModalInner.displayName = "ExerciseModal";

export function ExerciseModal({ ex, gifUrl, isOpen, onClose }: ExerciseModalProps) {
  return <ExerciseModalInner ex={ex} gifUrl={gifUrl} isOpen={isOpen} onClose={onClose} />;
}