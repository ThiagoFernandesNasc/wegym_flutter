"use client";
export const dynamic = 'force-dynamic';
import React, { useCallback, useEffect, useRef, useState } from "react";
import { useTranslations } from "@/lib/i18n/hook";
import { AuthGuard } from "@/components/auth/AuthGuard";
import { Send, MessageSquare, Loader2, User } from "lucide-react";
import { toast } from "sonner";

export default function ChatPage() {
  const { t } = useTranslations();
  const [conversations, setConversations] = useState<{ sent: any[]; received: any[] }>({ sent: [], received: [] });
  const [activeUser, setActiveUser] = useState<string | null>(null);
  const [messages, setMessages] = useState<any[]>([]);
  const [text, setText] = useState("");
  const [loading, setLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  const loadConversations = useCallback(async () => {
    try { const r = await fetch("/api/messages", { credentials: "include" }); if (r.ok) { const d = await r.json(); setConversations(d.conversations || { sent: [], received: [] }); } } finally { setLoading(false); }
  }, []);

  useEffect(() => { loadConversations(); }, [loadConversations]);

  const loadMessages = async (userId: string) => {
    setActiveUser(userId);
    const r = await fetch(`/api/messages/${userId}`, { credentials: "include" });
    if (r.ok) setMessages(await r.json());
  };

  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: "smooth" }); }, [messages]);

  const send = async () => {
    if (!text.trim() || !activeUser || isSending) return;
    setIsSending(true);
    try {
      const res = await fetch("/api/messages", { method: "POST", credentials: "include", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ receiverId: activeUser, text }) });
      if (!res.ok) throw new Error("Erro ao enviar");
      setText(""); loadMessages(activeUser);
    } catch {
      toast.error("Erro ao enviar mensagem. Tente novamente.");
    } finally {
      setIsSending(false);
    }
  };

  const contactList = [...new Map<string, any>([...conversations.sent.map((c: any) => [c.receiver.id, c.receiver] as [string, any]), ...conversations.received.map((c: any) => [c.sender.id, c.sender] as [string, any])]).values()];

  return (
    <AuthGuard>
      <div className="min-h-screen bg-zinc-950 text-zinc-100 pb-20 font-sans antialiased">
        <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4"><h1 className="text-lg sm:text-xl font-black italic uppercase tracking-tighter text-white">{t("chat.title")}</h1></header>
        <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 flex gap-4 h-[calc(100vh-140px)]">
          <div className="w-1/3 space-y-2 overflow-y-auto">
            {loading ? <Loader2 size={20} className="animate-spin text-orange-500 mx-auto mt-8" /> : contactList.length === 0 ? <p className="text-zinc-500 text-xs text-center mt-8">{t("chat.emptyConversation")}</p> : contactList.map((u: any) => (
              <button key={u.id} onClick={() => loadMessages(u.id)} className={`w-full text-left p-3 rounded-2xl transition-colors cursor-pointer ${activeUser === u.id ? "bg-orange-600/20 border border-orange-500/30" : "bg-zinc-900/40 border border-white/5 hover:border-white/10"}`}>
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-orange-600/20 flex items-center justify-center text-orange-500 text-xs font-bold">{u.displayName?.charAt(0) || "?"}</div>
                  <p className="text-xs font-bold text-white truncate">{u.displayName || "Usuário"}</p>
                </div>
              </button>
            ))}
          </div>
          <div className="flex-1 flex flex-col bg-zinc-900/40 border border-white/5 rounded-4xl overflow-hidden">
            {activeUser ? (
              <>
                <div className="flex-1 overflow-y-auto p-4 space-y-3">
                  {messages.map((m: any, i: number) => (
                    <div key={i} className={`flex ${m.senderId === activeUser ? "justify-start" : "justify-end"}`}>
                      <div className={`max-w-[75%] rounded-2xl px-4 py-2.5 ${m.senderId === activeUser ? "bg-zinc-800 text-zinc-300" : "bg-orange-600 text-white"}`}>
                        <p className="text-sm">{m.text}</p>
                        <p className="text-[9px] opacity-60 mt-1">{new Date(m.createdAt).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })}</p>
                      </div>
                    </div>
                  ))}
                  <div ref={bottomRef} />
                </div>
                <div className="border-t border-white/5 p-3 flex gap-2">
                  <input value={text} onChange={(e) => setText(e.target.value)} onKeyDown={(e) => e.key === "Enter" && send()} placeholder={t("chat.inputPlaceholder")} className="flex-1 bg-zinc-950 border border-zinc-700 rounded-xl px-4 py-2.5 text-sm text-white placeholder:text-zinc-600 outline-none focus:border-orange-500" />
                  <button onClick={send} disabled={!text.trim() || isSending} className="bg-orange-600 hover:bg-orange-700 disabled:bg-zinc-700 text-white p-2.5 rounded-xl cursor-pointer transition-colors disabled:cursor-not-allowed flex items-center justify-center">{isSending ? <Loader2 size={16} className="animate-spin" /> : <Send size={16} />}</button>
                </div>
              </>
            ) : (
              <div className="flex-1 flex items-center justify-center text-zinc-600">
                <div className="text-center"><MessageSquare size={40} className="mx-auto mb-3 opacity-50" /><p className="text-sm">{t("chat.emptyConversation")}</p></div>
              </div>
            )}
          </div>
        </main>
      </div>
    </AuthGuard>
  );
}
