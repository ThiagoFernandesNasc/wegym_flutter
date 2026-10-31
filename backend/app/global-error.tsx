"use client";

import * as Sentry from "@sentry/react";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  if (typeof window !== "undefined") {
    Sentry.captureException(error);
  }

  return (
    <html lang="pt-BR">
      <body className="bg-zinc-950 text-zinc-100">
        <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-4">
          <h2 className="text-lg font-semibold">Erro crítico</h2>
          <p className="text-sm text-zinc-500">
            Ocorreu um erro inesperado. Tente recarregar a página.
          </p>
          <p className="text-xs text-zinc-600">
            {error.digest && `Código: ${error.digest}`}
          </p>
          <button
            onClick={reset}
            className="rounded-lg bg-orange-600 px-6 py-2 text-sm font-medium text-white transition-colors hover:bg-orange-500"
          >
            Recarregar
          </button>
        </div>
      </body>
    </html>
  );
}
