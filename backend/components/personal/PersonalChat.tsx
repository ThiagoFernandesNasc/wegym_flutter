"use client";

import { motion, AnimatePresence } from "framer-motion";
import { useTranslations } from "@/lib/i18n/hook";
import { Bot, Send, X } from "lucide-react";

interface PersonalChatProps {
  isOpen: boolean;
  messages: { role: string; content: string }[];
  input: string;
  loading: boolean;
  onSetInput: (v: string) => void;
  onSend: () => void;
  onClose: () => void;
}

export function PersonalChat({ isOpen, messages, input, loading, onSetInput, onSend, onClose }: PersonalChatProps) {
  const { t } = useTranslations();
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: 20 }}
          className="fixed bottom-24 right-6 w-95 h-125 bg-zinc-900 border border-white/10 rounded-3xl shadow-2xl flex flex-col z-100 overflow-hidden backdrop-blur-xl">
          <div className="p-4 bg-orange-600 flex justify-between items-center">
            <div className="flex items-center gap-2 text-white">
              <Bot size={20} />
              <span className="font-black italic uppercase text-xs">{t('personal.geminiCopilot')}</span>
            </div>
            <button type="button" onClick={onClose} className="text-white/80 cursor-pointer"><X size={20} /></button>
          </div>
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {messages.map((msg, i) => (
              <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div className={`max-w-[85%] p-3 rounded-2xl text-[11px] ${msg.role === 'user' ? 'bg-orange-600 text-white' : 'bg-zinc-800 text-zinc-300'}`}>
                  {msg.content}
                </div>
              </div>
            ))}
          </div>
          <div className="p-4 border-t border-white/5 flex gap-2">
            <input value={input} onChange={(e) => onSetInput(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && onSend()}
              placeholder={t('personal.chatPlaceholder')} className="flex-1 bg-zinc-900 rounded-xl px-4 text-xs text-white outline-none" />
            <button onClick={onSend} disabled={loading} className="bg-orange-600 p-2.5 rounded-xl text-white cursor-pointer disabled:cursor-not-allowed">
              <Send size={18} />
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
