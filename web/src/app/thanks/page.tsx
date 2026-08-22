"use client";

import React from "react";
import { CheckCircle2, ArrowLeft, MessageSquare, Cloud, Sparkles } from "lucide-react";

export default function ThanksPage() {
  return (
    <main className="min-h-screen bg-white px-4 py-16 dark:bg-[#09090b] sm:px-6 lg:px-8 flex items-center justify-center">
      <div className="w-full max-w-xl">
        <div className="mb-8 text-center">
          <a
            href="/"
            className="inline-flex items-center gap-1.5 font-mono text-xs font-semibold text-slate-500 hover:text-slate-900 dark:text-zinc-400 dark:hover:text-zinc-50 transition"
          >
            <ArrowLeft className="size-3.5" />
            <span>Back to Home</span>
          </a>
        </div>

        <article className="rounded-2xl border border-slate-200 bg-white p-8 dark:border-zinc-800 dark:bg-[#0c0c0e] shadow-xl text-center">
          <header className="flex flex-col items-center">
            <div className="relative mb-5 flex size-16 items-center justify-center rounded-2xl bg-emerald-500/10 text-emerald-500 dark:bg-emerald-400/10 dark:text-emerald-400">
              <CheckCircle2 className="size-8" />
            </div>
            <h1 className="text-3xl font-extrabold tracking-tight text-slate-950 dark:text-white sm:text-4xl">Thank You!</h1>
            <p className="mt-2.5 text-[14.5px] text-slate-500 dark:text-zinc-400">Welcome to paullm-ssh Pro. Your purchase is complete.</p>
          </header>

          <div className="mt-10 border-t border-slate-100 pt-8 dark:border-zinc-800/80 text-left space-y-6">
            <div className="flex gap-4">
              <div className="flex size-9 items-center justify-center rounded-lg border border-slate-200 bg-slate-50 dark:border-zinc-800 dark:bg-zinc-900 shrink-0 text-slate-800 dark:text-zinc-200">
                <Sparkles className="size-4.5" />
              </div>
              <div>
                <h2 className="text-sm font-bold text-slate-950 dark:text-white sm:text-base">Features Unlocked</h2>
                <p className="mt-1 text-[13px] leading-relaxed text-slate-500 dark:text-zinc-400">
                  Your Pro features are unlocked automatically on all iPhone, iPad, and Mac devices signed in with your Apple ID.
                </p>
              </div>
            </div>

            <div className="flex gap-4">
              <div className="flex size-9 items-center justify-center rounded-lg border border-slate-200 bg-slate-50 dark:border-zinc-800 dark:bg-zinc-900 shrink-0 text-slate-800 dark:text-zinc-200">
                <Cloud className="size-4.5" />
              </div>
              <div>
                <h2 className="text-sm font-bold text-slate-950 dark:text-white sm:text-base">Metadata Sync Active</h2>
                <p className="mt-1 text-[13px] leading-relaxed text-slate-500 dark:text-zinc-400">
                  Add unlimited workspaces and servers. The list syncs via iCloud to all your devices automatically. Credentials remain secured locally in Keychain.
                </p>
              </div>
            </div>
          </div>

          <div className="mt-10 flex flex-col items-center justify-center gap-4">
            <a
              className="inline-flex h-10 items-center justify-center gap-2 rounded-lg bg-slate-950 px-5 text-xs font-semibold text-white transition hover:bg-slate-800 dark:bg-zinc-50 dark:text-slate-950 dark:hover:bg-zinc-200"
              href="https://discord.gg/zemMZtrkSb"
              target="_blank"
              rel="noopener noreferrer"
            >
              <MessageSquare className="size-3.5" />
              <span>Join Discord Community</span>
            </a>
            <p className="text-[11px] text-slate-400 dark:text-zinc-500">
              Need technical assistance? Contact us at <a href="mailto:vvterm@vivy.company" className="underline">vvterm@vivy.company</a>
            </p>
          </div>
        </article>
      </div>
    </main>
  );
}
