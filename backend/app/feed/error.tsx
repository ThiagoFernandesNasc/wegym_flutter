"use client";

import { useEffect } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="min-h-screen bg-zinc-950 flex items-center justify-center px-4">
      <div className="text-center max-w-md">
        <div className="w-16 h-16 rounded-2xl bg-red-500/10 border border-red-500/20 flex items-center justify-center mx-auto mb-6">
          <AlertTriangle size={28} className="text-red-500" />
        </div>
        <h2 className="text-xl font-black italic uppercase text-white mb-2">
          Algo deu errado
        </h2>
        <p className="text-sm text-zinc-500 mb-6">
          Ocorreu um erro inesperado. Tente novamente.
        </p>
        <button
          onClick={reset}
          className="bg-orange-600 hover:bg-orange-700 text-white px-6 py-3 rounded-xl text-xs font-black uppercase italic cursor-pointer transition-colors inline-flex items-center gap-2"
        >
          <RefreshCw size={14} /> Tentar novamente
        </button>
      </div>
    </div>
  );
}
