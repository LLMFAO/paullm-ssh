"use client";

import React from "react";
import { CreditCard, ArrowLeft } from "lucide-react";

export default function RefundPage() {
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
                <CreditCard className="size-4.5 text-slate-800 dark:text-zinc-200" />
              </div>
              <div>
                <h1 className="text-2xl font-extrabold tracking-tight text-slate-950 dark:text-white sm:text-3xl">Refund Policy</h1>
                <p className="mt-1 text-xs text-slate-400 dark:text-zinc-500">Last Updated: January 15, 2026</p>
              </div>
            </div>
          </header>

          <div className="mt-8 space-y-8 text-[14px] leading-relaxed text-slate-600 dark:text-zinc-300">
            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">Refunds for App Store Purchases</h2>
              <p>
                paullm-ssh Pro is sold through Apple’s App Store. Apple handles billing and refunds, and eligibility
                is determined by Apple’s policies.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">How to Request a Refund</h2>
              <p>To request a refund, use Apple’s official process:</p>
              <ol className="list-decimal pl-5 space-y-1.5 font-medium text-slate-800 dark:text-zinc-100">
                <li>Go to <a href="https://reportaproblem.apple.com" target="_blank" rel="noopener noreferrer" className="text-slate-900 underline dark:text-white">reportaproblem.apple.com</a></li>
                <li>Sign in with your Apple ID</li>
                <li>Find your paullm-ssh Pro purchase</li>
                <li>Select "Request a refund" and follow the prompts</li>
              </ol>
              <p className="mt-4 text-slate-500 dark:text-zinc-400">
                We’re unable to issue refunds directly, but if you’re having trouble using the app, contact us
                and we’ll do our best to help.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">Subscription Cancellation</h2>
              <p>If you subscribed to paullm-ssh Pro Monthly or Yearly, you can cancel at any time:</p>
              <ol className="list-decimal pl-5 space-y-1.5 font-medium text-slate-800 dark:text-zinc-100">
                <li>Open Settings on your iPhone or iPad, or System Settings on Mac</li>
                <li>Tap your Apple ID, then Subscriptions</li>
                <li>Find paullm-ssh and tap "Cancel Subscription"</li>
              </ol>
              <p className="mt-4">Upon cancellation:</p>
              <ul className="list-disc pl-5 space-y-1.5">
                <li>You'll retain Pro access until the end of your current billing period</li>
                <li>No further charges will be made</li>
                <li>Pro features will be disabled after the period ends</li>
                <li>Your servers and workspaces will remain, but free tier limits will apply</li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">Lifetime Purchases</h2>
              <p>
                Lifetime Pro purchases are one-time and do not require cancellation. Refunds are handled by
                Apple using the same process above.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">Contact Us</h2>
              <p>
                Questions or technical issues? Contact us at{". "}
                <a href="mailto:vvterm@vivy.company" className="font-semibold text-slate-950 hover:underline dark:text-white">
                  vvterm@vivy.company
                </a>.
              </p>
            </section>
          </div>
        </article>
      </div>
    </main>
  );
}
