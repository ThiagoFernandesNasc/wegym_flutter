// src/components/LeftPanel.tsx
"use client";

import React from "react";
import { motion } from 'framer-motion';
import { Dumbbell } from 'lucide-react';
import { useTranslations } from '@/lib/i18n/hook';
import { FloatingDumbbell3D } from './FloatingDumbbell3D';
import dynamic from 'next/dynamic';

const FloatingDumbbell3DDynamic = dynamic(
  () => import('./FloatingDumbbell3D').then(mod => mod.FloatingDumbbell3D),
  { ssr: false }
);

export const LeftPanel = React.memo(() => {
  const { t } = useTranslations();

  return (
    <div className="hidden md:flex md:w-1/3 bg-zinc-900 p-12 flex-col justify-between relative overflow-hidden">
      <div className="absolute inset-0 opacity-10 bg-[radial-gradient(circle,#fff_1px,transparent_1px)] bg-size-[30px_30px]" />

      <div className="relative z-10">
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          whileHover={{ rotateZ: -2, scale: 1.02 }}
          className="flex items-center space-x-2 mb-8 origin-left"
        >
          <div
            className="w-10 h-10 bg-orange-500 rounded-lg flex items-center justify-center rotate-3 shadow-lg shadow-orange-500/30"
            style={{ transformStyle: 'preserve-3d' }}
          >
            <motion.div
              animate={{ rotateZ: [3, -3, 3], y: [0, -2, 0] }}
              transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
            >
              <Dumbbell className="text-white w-6 h-6" />
            </motion.div>
          </div>
          <h1 className="text-2xl font-black text-white tracking-tighter italic">WEGYM</h1>
        </motion.div>

        <motion.h2
          initial={{ y: 24, opacity: 0, rotateX: 18, transformPerspective: 700 }}
          animate={{ y: 0, opacity: 1, rotateX: 0 }}
          transition={{ duration: 0.6, delay: 0.15, ease: [0.22, 1, 0.36, 1] }}
          className="text-5xl font-black text-white mb-6 leading-none uppercase italic"
        >
          {t('login.panelTitle1')} <br />
          <span className="text-orange-500 underline decoration-zinc-700">{t('login.panelTitle2')}</span>.
        </motion.h2>
        <motion.p
          initial={{ y: 18, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.3, ease: [0.22, 1, 0.36, 1] }}
          className="text-zinc-400 text-lg leading-relaxed"
        >
          {t('login.panelDescription')}
        </motion.p>
      </div>

      <div className="relative z-10 mt-10 flex justify-center">
        <FloatingDumbbell3DDynamic />
      </div>
    </div>
  );
});

LeftPanel.displayName = 'LeftPanel';
