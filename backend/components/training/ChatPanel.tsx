"use client";

import React from "react";
import { motion } from "framer-motion";
import { BrainCircuit, X, Send } from "lucide-react";
import { useTranslations } from "@/lib/i18n/hook";
import type { AIChatMessage } from "@/types/training";

interface ChatPanelProps {
  isOpen: boolean;
  onClose: () => void;
  messages: AIChatMessage[];
  chatInput: string;
  chatLoading: boolean;
  onInputChange: (v: string) => void;
  onSend: () => void;
}

export function ChatPanel({ isOpen, onClose, messages, chatInput, chatLoading, onInputChange, onSend }: ChatPanelProps) {
  const { t } = useTranslations();

  if (!isOpen) return null;

  return (
    <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 20 }} className="fixed bottom-24 right-6 w-95 h-125 bg-zinc-900 border border-white/10 rounded-3xl shadow-2xl flex flex-col z-100 overflow-hidden backdrop-blur-xl">
      <div className="p-4 bg-orange-600 flex justify-between items-center">
        <div className="flex items-center gap-2 text-white">
          <BrainCircuit size={20} />
          <span className="font-black italic uppercase text-xs">{t('training.wegymAssistant')}</span>
        </div>
        <button type="button" onClick={onClose} className="text-white/80 cursor-pointer"><X size={20} /></button>
      </div>
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, i) => (
          <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[85%] p-3 rounded-2xl text-xs leading-relaxed ${msg.role === 'user' ? 'bg-orange-600 text-white' : 'bg-zinc-800 text-zinc-300'}`}>{msg.text}</div>
          </div>
        ))}
        {chatLoading && (
          <div className="flex justify-start">
            <div className="bg-zinc-800 p-3 rounded-2xl">
              <div className="flex gap-1">
                <div className="w-2 h-2 bg-zinc-500 rounded-full animate-bounce" style={{ animationDelay: "0ms" }} />
                <div className="w-2 h-2 bg-zinc-500 rounded-full animate-bounce" style={{ animationDelay: "150ms" }} />
                <div className="w-2 h-2 bg-zinc-500 rounded-full animate-bounce" style={{ animationDelay: "300ms" }} />
              </div>
            </div>
          </div>
        )}
      </div>
      <div className="p-4 border-t border-white/5 flex gap-2">
        <input
          value={chatInput}
          onChange={(e) => onInputChange(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter' && !chatLoading) onSend(); }}
          placeholder={t('training.chatPlaceholder')}
          className="flex-1 bg-zinc-800 border border-white/10 rounded-xl px-4 py-2.5 text-xs text-white outline-none focus:border-orange-500/50"
        />
        <button
          type="button"
          onClick={onSend}
          disabled={chatLoading || !chatInput.trim()}
          className="bg-orange-600 hover:bg-orange-700 disabled:opacity-40 p-2.5 rounded-xl text-white cursor-pointer disabled:cursor-not-allowed transition-colors"
        >
          <Send size={18} />
        </button>
      </div>
    </motion.div>
  );
}
