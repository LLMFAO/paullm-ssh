"use client";

import React from "react";
import { HelpCircle, ArrowLeft } from "lucide-react";

export default function SupportPage() {
  return (
    <main className="min-h-screen bg-white px-4 py-16 dark:bg-[#09090b] sm:px-6 lg:px-8">
      <div className="mx-auto max-w-3xl">
        <div className="mb-8">
          <a
            href="/"
            className="inline-flex items-center gap-1.5 font-mono text-xs font-semibold text-slate-500 hover:text-slate-900 dark:text-zinc-400 dark:hover:text-zinc-50 transition"
          >
            <ArrowLeft className="size-3.5" />
            <span>Back to Home</span>
          </a>
        </div>

        <article className="rounded-xl border border-slate-200 bg-white p-6 dark:border-zinc-800 dark:bg-[#0c0c0e] sm:p-10">
          <header className="border-b border-slate-100 pb-6 dark:border-zinc-800/80">
            <div className="flex items-center gap-2.5">
              <div className="flex size-9 items-center justify-center rounded-lg border border-slate-200 bg-slate-50 dark:border-zinc-800 dark:bg-zinc-900">
                <HelpCircle className="size-4.5 text-slate-800 dark:text-zinc-200" />
              </div>
              <div>
                <h1 className="text-2xl font-extrabold tracking-tight text-slate-950 dark:text-white sm:text-3xl">Customer Support</h1>
                <p className="mt-1 text-xs text-slate-500 dark:text-zinc-500">We’re here to help with any questions about paullm-ssh.</p>
              </div>
            </div>
          </header>

          <div className="mt-8 space-y-8 text-[14px] leading-relaxed text-slate-600 dark:text-zinc-300">
            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">Contact</h2>
              <p>
                Email us directly at{" "}
                <a href="mailto:vvterm@vivy.company" className="font-semibold text-slate-950 hover:underline dark:text-white">
                  vvterm@vivy.company
                </a>
                . We typically respond within 1 to 2 business days.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">App Support & Diagnostics</h2>
              <p>Please include the following details so we can assist you faster:</p>
              <ul className="list-disc pl-5 space-y-1.5 font-medium text-slate-800 dark:text-zinc-100">
                <li>Device model and OS version</li>
                <li>paullm-ssh app version</li>
                <li>Clear steps to reproduce the issue</li>
                <li>Any relevant screenshots, terminal flags, or logs</li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">Billing and Subscriptions</h2>
              <p>
                All purchases are processed securely by Apple through the App Store. If you have billing questions, you can contact us or
                manage subscriptions in your Apple ID account settings directly.
              </p>
            </section>
          </div>
        </article>
      </div>
    </main>
  );
}
