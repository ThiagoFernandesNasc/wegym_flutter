"use client";

import React from "react";

export default function NotFound() {
  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 p-8 flex items-center justify-center font-sans">
      <div className="bg-zinc-900/50 rounded-3xl border border-white/5 p-8 max-w-md text-center">
        <h2 className="text-3xl font-black italic uppercase tracking-tortoise text-zinc-400 mb-4">
          Página não encontrada
        </h2>
        <p className="text-zinc-400 text-sm leading-relaxed mb-6">
          A página que você está procurando não existe ou foi removida.
        </p>
        <div className="flex gap-3 justify-center">
          <a
            href="/"
            onClick={() => window.history.back()}
            className="bg-orange-600 hover:bg-orange-700 text-white font-black uppercase italic text-xs rounded-xl px-6 py-3 transition-colors"
          >
            Ir para o início
          </a>
          <button
            onClick={() => window.history.back()}
            className="bg-zinc-900 hover:bg-zinc-950 text-white font-black uppercase italic text-xs rounded-xl px-6 py-3 transition-colors"
          >
            Voltar
          </button>
        </div>
      </div>
    </div>
  );
}