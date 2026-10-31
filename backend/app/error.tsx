"use client";

import React from "react";

export default function Error({
  error,
  reset,
  message,
}: {
  error: Error;
  reset: () => void;
  message: string;
}) {
  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 p-8 flex items-center justify-center font-sans">
      <div className="bg-zinc-900/50 rounded-3xl border border-white/5 p-8 max-w-md text-center">
        <h2 className="text-2xl font-black italic uppercase tracking-tighter text-orange-500 mb-4">
          Algo deu errado
        </h2>
        <p className="text-zinc-400 text-sm leading-relaxed mb-6">
          {message}
        </p>
        <button
          onClick={reset}
          className="bg-orange-600 hover:bg-orange-700 text-white font-black uppercase italic text-xs rounded-xl px-6 py-3 transition-colors"
        >
          Tentar novamente
        </button>
      </div>
    </div>
  );
}