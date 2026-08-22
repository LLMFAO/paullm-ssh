"use client";

import React from "react";
import { Shield, ArrowLeft } from "lucide-react";

export default function PrivacyPage() {
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
                <Shield className="size-4.5 text-slate-800 dark:text-zinc-200" />
              </div>
              <div>
                <h1 className="text-2xl font-extrabold tracking-tight text-slate-950 dark:text-white sm:text-3xl">Privacy Policy</h1>
                <p className="mt-1 text-xs text-slate-400 dark:text-zinc-500">Last Updated: January 15, 2026</p>
              </div>
            </div>
          </header>

          <div className="mt-8 space-y-8 text-[14px] leading-relaxed text-slate-600 dark:text-zinc-300">
            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">1. Introduction</h2>
              <p>
                Vivy Technologies Co., Limited ("we", "our", or "us") operates paullm-ssh, an SSH terminal
                application for iOS and macOS. This Privacy Policy explains how we collect, use, and protect
                your information.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">2. Information We Collect</h2>
              
              <div className="space-y-4 pl-1">
                <div>
                  <h3 className="font-semibold text-slate-900 dark:text-zinc-100">Server Configurations</h3>
                  <p className="mt-1">
                    paullm-ssh stores your server configurations (host, port, username) locally and syncs them via
                    iCloud to your other devices. This data is encrypted in transit and at rest by Apple's iCloud
                    infrastructure.
                  </p>
                </div>

                <div>
                  <h3 className="font-semibold text-slate-900 dark:text-zinc-100">Credentials</h3>
                  <p className="mt-1">
                    SSH passwords and private keys are stored in Apple Keychain. If iCloud sync is enabled,
                    credentials sync via iCloud Keychain across your devices. We never receive these credentials,
                    and they are protected by your device's security.
                  </p>
                </div>

                <div>
                  <h3 className="font-semibold text-slate-900 dark:text-zinc-100">Analytics Data</h3>
                  <p className="mt-1">
                    We use Umami Analytics, a privacy-focused analytics service, to collect anonymous usage
                    statistics on our website. No personal information is collected or stored.
                  </p>
                </div>

                <div>
                  <h3 className="font-semibold text-slate-900 dark:text-zinc-100">Purchase Information</h3>
                  <p className="mt-1">
                    If you purchase paullm-ssh Pro, your purchase is processed through the App Store. We receive
                    confirmation of your purchase but do not have access to your payment details.
                  </p>
                </div>
              </div>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">3. How We Use Your Information</h2>
              <ul className="list-disc pl-5 space-y-1.5">
                <li>To provide and maintain the app functionality</li>
                <li>To sync server configurations across your devices via iCloud</li>
                <li>To verify Pro subscription status</li>
                <li>To improve our website and application</li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">4. Data Storage and Security</h2>
              <p>
                Server configurations are synced via Apple iCloud, subject to Apple's security measures.
                Credentials are stored in Apple Keychain and may sync via iCloud Keychain when enabled. We do
                not operate our own servers to store your data. We do not sell or share your personal
                information with third parties.
              </p>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">5. Your Rights</h2>
              <p>You have the right to:</p>
              <ul className="list-disc pl-5 space-y-1.5">
                <li>Delete all app data by removing paullm-ssh from your devices</li>
                <li>Disable iCloud sync in Settings to keep data local only</li>
                <li>Remove stored credentials from Keychain at any time</li>
                <li>Request information about data we may have collected</li>
              </ul>
            </section>

            <section className="space-y-3">
              <h2 className="text-lg font-bold text-slate-950 dark:text-white">6. Contact Us</h2>
              <p>
                If you have questions about this Privacy Policy, contact us via email at{" "}
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
