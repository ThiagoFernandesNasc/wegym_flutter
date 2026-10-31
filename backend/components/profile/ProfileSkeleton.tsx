"use client";

import React from "react";

export function ProfileSkeleton() {
  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100 font-sans antialiased pb-20">
      <header className="sticky top-0 z-40 bg-zinc-950/40 backdrop-blur-md border-b border-white/5 px-4 sm:px-6 py-4 pl-16 lg:pl-6 flex items-center gap-3">
        <div className="h-5 w-5 rounded bg-zinc-800/60 animate-pulse" />
        <div className="h-5 w-32 rounded bg-zinc-800/60 animate-pulse" />
      </header>
      <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 space-y-6">
        <div className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8 flex flex-col sm:flex-row items-center sm:items-start gap-6">
          <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-3xl bg-zinc-800/50 animate-pulse" />
          <div className="flex-1 space-y-3 w-full">
            <div className="h-3 w-24 bg-zinc-800/40 rounded animate-pulse" />
            <div className="h-8 w-2/3 bg-zinc-800/60 rounded-md animate-pulse" />
            <div className="h-3 w-1/2 bg-zinc-800/40 rounded animate-pulse" />
            <div className="h-3 w-1/3 bg-zinc-800/40 rounded animate-pulse" />
            <div className="flex gap-2 pt-2">
              <div className="h-6 w-20 rounded-full bg-zinc-800/40 animate-pulse" />
              <div className="h-6 w-24 rounded-full bg-zinc-800/40 animate-pulse" />
            </div>
          </div>
        </div>
        <div className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8 space-y-4">
          <div className="h-3 w-24 bg-zinc-800/40 rounded animate-pulse" />
          <div className="h-6 w-40 bg-zinc-800/60 rounded animate-pulse" />
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="h-28 rounded-3xl bg-zinc-800/30 animate-pulse" />
            <div className="h-28 rounded-3xl bg-zinc-800/30 animate-pulse" />
            <div className="h-28 rounded-3xl bg-zinc-800/30 animate-pulse" />
          </div>
        </div>
        <div className="bg-zinc-900/40 border border-white/5 rounded-4xl p-6 sm:p-8 space-y-4">
          <div className="h-3 w-24 bg-zinc-800/40 rounded animate-pulse" />
          <div className="h-6 w-48 bg-zinc-800/60 rounded animate-pulse" />
          <div className="h-20 rounded-3xl bg-zinc-800/30 animate-pulse" />
          <div className="h-20 rounded-3xl bg-zinc-800/30 animate-pulse" />
        </div>
      </main>
    </div>
  );
}
