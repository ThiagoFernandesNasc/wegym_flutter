"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  motion,
  useMotionValue,
  useSpring,
  useMotionTemplate,
  useReducedMotion,
} from "framer-motion";

type Tilt3DProps = {
  children: React.ReactNode;
  className?: string;
  intensity?: number;
  scale?: number;
  glare?: boolean;
  glareOpacity?: number;
  disabled?: boolean;
};

export function Tilt3D({
  children,
  className,
  intensity = 10,
  scale = 1.02,
  glare = true,
  glareOpacity = 0.16,
  disabled = false,
}: Tilt3DProps) {
  const ref = useRef<HTMLDivElement>(null);
  const reduceMotion = useReducedMotion();
  const [isCoarse, setIsCoarse] = useState(false);

  useEffect(() => {
    const mq = window.matchMedia("(pointer: coarse)");
    setIsCoarse(mq.matches);
    const onChange = (e: MediaQueryListEvent) => setIsCoarse(e.matches);
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);

  const rx = useMotionValue(0);
  const ry = useMotionValue(0);
  const gx = useMotionValue(50);
  const gy = useMotionValue(50);

  const springRx = useSpring(rx, { stiffness: 260, damping: 20, mass: 0.6 });
  const springRy = useSpring(ry, { stiffness: 260, damping: 20, mass: 0.6 });
  const springGx = useSpring(gx, { stiffness: 200, damping: 24 });
  const springGy = useSpring(gy, { stiffness: 200, damping: 24 });

  const glareBackground = useMotionTemplate`radial-gradient(circle at ${springGx}% ${springGy}%, rgba(255,255,255,${glareOpacity}), transparent 55%)`;

  const onPointerMove = useCallback(
    (e: React.PointerEvent<HTMLDivElement>) => {
      if (reduceMotion || disabled || !ref.current) return;
      const rect = ref.current.getBoundingClientRect();
      const px = (e.clientX - rect.left) / rect.width;
      const py = (e.clientY - rect.top) / rect.height;
      ry.set((px - 0.5) * intensity * 2);
      rx.set((0.5 - py) * intensity * 2);
      gx.set(px * 100);
      gy.set(py * 100);
    },
    [reduceMotion, disabled, intensity, rx, ry, gx, gy],
  );

  const onPointerLeave = useCallback(() => {
    rx.set(0);
    ry.set(0);
    gx.set(50);
    gy.set(50);
  }, [rx, ry, gx, gy]);

  const interactive = !reduceMotion && !isCoarse;

  return (
    <motion.div
      ref={ref}
      onPointerMove={interactive ? onPointerMove : undefined}
      onPointerLeave={interactive ? onPointerLeave : undefined}
      className={className}
      style={{
        rotateX: springRx,
        rotateY: springRy,
        transformStyle: "preserve-3d",
        transformPerspective: 900,
        position: "relative",
      }}
      whileHover={interactive ? { scale } : undefined}
      transition={{ type: "spring", stiffness: 300, damping: 22 }}
    >
      {children}
      {glare && interactive && (
        <motion.div
          aria-hidden
          className="pointer-events-none absolute inset-0 z-20 rounded-[inherit] mix-blend-overlay"
          style={{ background: glareBackground }}
        />
      )}
    </motion.div>
  );
}
