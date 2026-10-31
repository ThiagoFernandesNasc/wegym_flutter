"use client";

import React from "react";
import { motion } from "framer-motion";
import { MessageCircle } from "lucide-react";

interface FloatingChatButtonProps {
  onClick: () => void;
}

export function FloatingChatButton({ onClick }: FloatingChatButtonProps) {
  return (
    <div className="fixed bottom-6 right-6 z-120">
      <motion.div
        aria-hidden
        className="absolute inset-0 rounded-full bg-orange-600/50"
        animate={{ scale: [1, 1.45, 1], opacity: [0.45, 0, 0.45] }}
        transition={{ duration: 2.2, repeat: Infinity, ease: 'easeOut' }}
      />
      <button
        type="button"
        role="button"
        tabIndex={0}
        onClick={onClick}
        onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); onClick(); } }}
        className="relative w-16 h-16 rounded-full bg-orange-600 border border-orange-400 shadow-2xl shadow-orange-600/40 flex items-center justify-center hover:scale-105 transition-all btn-fab"
      >
        <MessageCircle className="text-white" size={28} />
      </button>
    </div>
  );
}
