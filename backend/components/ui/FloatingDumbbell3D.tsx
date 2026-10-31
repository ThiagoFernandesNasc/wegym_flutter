"use client";

import type { CSSProperties } from "react";
import { motion, useReducedMotion } from "framer-motion";

const PLATE_Z = [-16, -8, 0, 8, 16];

type Side = "left" | "right";

function plateGradient(offset: number) {
  const shade = 1 - Math.abs(offset) / 40;
  const light = `rgba(251,146,60,${0.5 + shade * 0.4})`;
  const mid = `rgba(234,88,12,${0.7 + shade * 0.3})`;
  const dark = `rgba(154,52,18,${0.75 + shade * 0.25})`;
  return {
    background: `linear-gradient(135deg, ${light} 0%, ${mid} 55%, ${dark} 100%)`,
    boxShadow:
      "inset 0 1px 1px rgba(255,255,255,0.35), inset 0 -2px 4px rgba(0,0,0,0.45), 0 0 14px rgba(234,88,12,0.35)",
  };
}

function Plate({ side, offset }: { side: Side; offset: number }) {
  const style: CSSProperties = {
    top: "50%",
    width: 44,
    height: 44,
    borderRadius: 12,
    border: "1px solid rgba(255,255,255,0.18)",
    transform: `translateY(-50%) translateZ(${offset}px)`,
    ...plateGradient(offset),
  };
  if (side === "left") style.left = 24;
  else style.right = 24;
  return <div className="absolute" style={style} />;
}

export function FloatingDumbbell3D({ className = "" }: { className?: string }) {
  const reduceMotion = useReducedMotion();

  const parts = (
    <>
      {/* handle */}
      <div
        className="absolute top-1/2"
        style={{
          left: 56,
          width: 128,
          height: 15,
          borderRadius: 999,
          transform: "translateY(-50%) translateZ(0px)",
          background: "linear-gradient(180deg, #d4d4d8 0%, #71717a 45%, #3f3f46 100%)",
          boxShadow:
            "inset 0 1px 1px rgba(255,255,255,0.5), inset 0 -2px 3px rgba(0,0,0,0.6), 0 2px 8px rgba(0,0,0,0.5)",
        }}
      />
      {/* grip (centro serrilhado) */}
      <div
        className="absolute top-1/2"
        style={{
          left: "50%",
          width: 52,
          height: 34,
          transform: "translate(-50%, -50%) translateZ(0px)",
          borderRadius: 14,
          background:
            "repeating-linear-gradient(90deg, #3f3f46 0px, #52525b 4px, #27272a 6px, #3f3f46 10px)",
          boxShadow:
            "inset 0 1px 1px rgba(255,255,255,0.3), inset 0 -2px 4px rgba(0,0,0,0.6), 0 0 10px rgba(0,0,0,0.45)",
        }}
      />
      {/* anéis de fixação */}
      <div
        className="absolute top-1/2"
        style={{
          left: 70,
          width: 14,
          height: 26,
          borderRadius: 8,
          transform: "translateY(-50%) translateZ(0px)",
          background: "linear-gradient(180deg, #a1a1aa, #52525b)",
          boxShadow: "inset 0 1px 1px rgba(255,255,255,0.35), inset 0 -2px 3px rgba(0,0,0,0.5)",
        }}
      />
      <div
        className="absolute top-1/2"
        style={{
          right: 70,
          width: 14,
          height: 26,
          borderRadius: 8,
          transform: "translateY(-50%) translateZ(0px)",
          background: "linear-gradient(180deg, #a1a1aa, #52525b)",
          boxShadow: "inset 0 1px 1px rgba(255,255,255,0.35), inset 0 -2px 3px rgba(0,0,0,0.5)",
        }}
      />
      {/* placas */}
      {PLATE_Z.map((z) => (
        <Plate key={`l${z}`} side="left" offset={z} />
      ))}
      {PLATE_Z.map((z) => (
        <Plate key={`r${z}`} side="right" offset={z} />
      ))}
    </>
  );

  return (
    <div className={`relative select-none ${className}`}>
      {/* glow ambiente */}
      <div className="absolute bottom-1 left-1/2 -translate-x-1/2 w-48 h-10 rounded-full bg-orange-500/25 blur-2xl" />
      <div className="absolute -top-4 left-1/2 -translate-x-1/2 w-40 h-16 rounded-full bg-orange-400/15 blur-3xl" />

      <motion.div
        className="relative w-60 h-40"
        style={{ perspective: 900 }}
        animate={reduceMotion ? undefined : { y: [0, -10, 0] }}
        transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
      >
        <div
          className="absolute inset-0"
          style={{ transform: "rotateX(16deg)", transformStyle: "preserve-3d" }}
        >
          <motion.div
            className="absolute inset-0"
            style={{ transformStyle: "preserve-3d" }}
            animate={reduceMotion ? undefined : { rotateY: [0, 360] }}
            transition={{ duration: 12, repeat: Infinity, ease: "linear" }}
          >
            {parts}
          </motion.div>
        </div>
      </motion.div>

      {/* sombra no chão */}
      <motion.div
        className="mx-auto w-40 h-3 rounded-full bg-black/50 blur-md"
        animate={reduceMotion ? undefined : { scaleX: [1, 0.82, 1], opacity: [0.5, 0.3, 0.5] }}
        transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
      />
    </div>
  );
}
