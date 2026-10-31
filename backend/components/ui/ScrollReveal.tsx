"use client";

import React from "react";
import { motion, useReducedMotion } from "framer-motion";

type ScrollRevealProps = {
  children: React.ReactNode;
  className?: string;
  delay?: number;
  y?: number;
  rotateX?: number;
  once?: boolean;
};

export function ScrollReveal({
  children,
  className,
  delay = 0,
  y = 28,
  rotateX = 12,
  once = true,
}: ScrollRevealProps) {
  const reduceMotion = useReducedMotion();

  return (
    <motion.div
      className={className}
      initial={
        reduceMotion
          ? { opacity: 0 }
          : { opacity: 0, y, rotateX, transformPerspective: 800 }
      }
      whileInView={
        reduceMotion ? { opacity: 1 } : { opacity: 1, y: 0, rotateX: 0 }
      }
      viewport={{ once, margin: "-60px" }}
      transition={{ duration: 0.6, delay, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}
