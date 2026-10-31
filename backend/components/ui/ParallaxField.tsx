"use client";

import React, { useEffect } from "react";
import {
  motion,
  MotionValue,
  useMotionValue,
  useSpring,
  useTransform,
  useReducedMotion,
} from "framer-motion";

type Orb = {
  className: string;
  depth: number;
  floatDur: number;
  floatY: number;
  delay?: number;
};

type Variant = "login" | "subtle";

const VARIANTS: Record<Variant, Orb[]> = {
  login: [
    {
      className:
        "w-[130vw] md:w-[34rem] h-[130vw] md:h-[34rem] bg-orange-600/15 rounded-full blur-[120px] top-[-12%] right-[-8%]",
      depth: -160,
      floatDur: 11,
      floatY: 34,
    },
    {
      className:
        "w-[150vw] md:w-[40rem] h-[150vw] md:h-[40rem] bg-zinc-700/25 rounded-full blur-[110px] bottom-[-18%] left-[-10%]",
      depth: -70,
      floatDur: 14,
      floatY: 46,
    },
    {
      className:
        "w-64 md:w-80 h-64 md:h-80 bg-orange-500/15 rounded-full blur-[90px] top-[24%] left-[6%]",
      depth: -220,
      floatDur: 9,
      floatY: 26,
    },
    {
      className:
        "w-56 md:w-72 h-56 md:h-72 bg-blue-600/10 rounded-full blur-[80px] bottom-[16%] right-[8%]",
      depth: 90,
      floatDur: 13,
      floatY: 30,
    },
    {
      className:
        "w-40 md:w-52 h-40 md:h-52 bg-fuchsia-600/10 rounded-full blur-[70px] top-[52%] right-[22%]",
      depth: 150,
      floatDur: 10,
      floatY: 22,
    },
  ],
  subtle: [
    {
      className:
        "w-96 md:w-[28rem] h-96 md:h-[28rem] bg-orange-600/10 rounded-full blur-[120px] top-[-8%] right-[-6%]",
      depth: -140,
      floatDur: 12,
      floatY: 30,
    },
    {
      className:
        "w-80 md:w-[24rem] h-80 md:h-[24rem] bg-blue-600/5 rounded-full blur-[100px] bottom-[-10%] left-[-8%]",
      depth: -80,
      floatDur: 15,
      floatY: 40,
    },
    {
      className:
        "w-48 md:w-64 h-48 md:h-64 bg-fuchsia-600/5 rounded-full blur-[80px] top-[38%] right-[14%]",
      depth: 130,
      floatDur: 11,
      floatY: 24,
    },
  ],
};

type ParallaxFieldProps = {
  variant?: Variant;
  className?: string;
};

export function ParallaxField({ variant = "subtle", className = "" }: ParallaxFieldProps) {
  const reduceMotion = useReducedMotion();
  const orbs = VARIANTS[variant];

  const mx = useMotionValue(0);
  const my = useMotionValue(0);
  const sx = useSpring(mx, { stiffness: 38, damping: 16, mass: 0.9 });
  const sy = useSpring(my, { stiffness: 38, damping: 16, mass: 0.9 });

  useEffect(() => {
    if (reduceMotion) return;
    const onMove = (e: PointerEvent) => {
      const nx = (e.clientX / window.innerWidth - 0.5) * 2;
      const ny = (e.clientY / window.innerHeight - 0.5) * 2;
      mx.set(nx);
      my.set(ny);
    };
    window.addEventListener("pointermove", onMove, { passive: true });
    return () => window.removeEventListener("pointermove", onMove);
  }, [reduceMotion, mx, my]);

  return (
    <div
      className={`absolute inset-0 overflow-hidden pointer-events-none z-0 ${className}`}
      aria-hidden
    >
      <div
        className="absolute inset-0"
        style={{ perspective: 900, transformStyle: "preserve-3d" }}
      >
        {orbs.map((orb, i) => (
          <ParallaxOrb key={i} orb={orb} sx={sx} sy={sy} reduceMotion={reduceMotion} />
        ))}
      </div>
    </div>
  );
}

type ParallaxOrbProps = {
  orb: Orb;
  sx: MotionValue<number>;
  sy: MotionValue<number>;
  reduceMotion: boolean | null;
};

function ParallaxOrb({ orb, sx, sy, reduceMotion }: ParallaxOrbProps) {
  const x = useTransform(sx, (v) => v * orb.depth * 0.4);
  const y = useTransform(sy, (v) => v * orb.depth * 0.4);

  if (reduceMotion) {
    return <div className={`absolute pointer-events-none ${orb.className}`} />;
  }

  return (
    <motion.div className={`absolute pointer-events-none ${orb.className}`} style={{ x, y, z: orb.depth }}>
      <motion.div
        className="w-full h-full"
        animate={{ y: [0, -orb.floatY, 0] }}
        transition={{
          duration: orb.floatDur,
          repeat: Infinity,
          ease: "easeInOut",
          delay: orb.delay ?? 0,
        }}
      />
    </motion.div>
  );
}
