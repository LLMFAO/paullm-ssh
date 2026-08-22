"use client";

import React from "react";
import { Scale, ArrowLeft } from "lucide-react";

export default function TermsPage() {
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
                <Scale className="size-4.5 text-slate-800 dark:text-zinc-200" />
              </div>
              <div>
                <h1 className="text-2xl font-extrabold tracking-tight text-slate-950 dark:text-white sm:text-3xl">Terms of Use</h1>
                <p className="mt-1 text-xs text-slate-400 dark:text-zinc-500">Last Updated: April 8, 2026</p>
              </div>
            </div>
          </header>

          <div className="mt-8 space-y-8 text-[13.5px] leading-relaxed text-slate-600 dark:text-zinc-300">
            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">1. Acknowledgement</h2>
              <p>
                These Terms of Use ("EULA") are concluded between you and Vivy Technologies Co., Limited
                ("Vivy", "we", "our", or "us"), and not with Apple. Vivy, not Apple, is solely responsible
                for paullm-ssh ("the App") and its content. By downloading, installing, or using the App, you
                agree to be bound by this EULA. If you do not agree, do not use the App.
              </p>
              <p>
                This EULA does not override any usage rules in the Apple Media Services Terms and Conditions.
                You acknowledge that you have had the opportunity to review those terms.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">2. Scope of License</h2>
              <p>
                Vivy grants you a limited, non-exclusive, non-transferable license to use the App on any
                Apple-branded products that you own or control and as permitted by the applicable App Store
                usage rules, including access via Family Sharing, volume purchasing, or Legacy Contacts where
                allowed by Apple.
              </p>
              <p>
                This EULA applies to official paullm-ssh binaries distributed through Apple's App Store. Source
                code published at{" "}
                <a href="https://github.com/paullm/paullm-ssh" target="_blank" rel="noopener noreferrer" className="underline font-medium text-slate-900 dark:text-white">
                  github.com/paullm/paullm-ssh
                </a>{" "}
                is licensed separately under GPL-3.0.
              </p>
              <h3 className="font-semibold text-slate-900 dark:text-zinc-100">Free Version Limits</h3>
              <p>
                The free version of paullm-ssh may be used without charge, subject to the following limitations:
                1 workspace, 3 servers, and 1 connection tab.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">3. paullm-ssh Pro and Purchases</h2>
              <p>
                paullm-ssh Pro requires a valid in-app purchase through the App Store. Pro unlocks unlimited
                workspaces, servers, and simultaneous connection tabs.
              </p>
              <p>
                Subscription billing and account management are handled by Apple. You can manage and cancel
                subscriptions through your Apple ID settings.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">4. Maintenance and Support</h2>
              <p>
                Vivy is solely responsible for providing any maintenance and support services for the App, to
                the extent required by this EULA or applicable law. Apple has no obligation whatsoever to
                furnish any maintenance or support services with respect to the App.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">5. Warranty</h2>
              <p>
                To the extent any warranty is not effectively disclaimed under applicable law, Vivy is solely
                responsible for such warranty.
              </p>
              <p>
                In the event of any failure of the App to conform to an applicable warranty, you may notify
                Apple, and Apple may refund the purchase price you paid for the App, if any. To the maximum
                extent permitted by applicable law, Apple will have no other warranty obligation whatsoever
                with respect to the App, and any other claims, losses, liabilities, damages, costs, or
                expenses attributable to any failure to conform to a warranty are Vivy's sole responsibility.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">6. Product Claims</h2>
              <p>
                Vivy, not Apple, is responsible for addressing any claims by you or any third party relating
                to the App or your possession or use of the App, including product liability claims, any claim
                that the App fails to conform to any applicable legal or regulatory requirement, and claims
                arising under consumer protection, privacy, or similar legislation.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">7. Intellectual Property Claims</h2>
              <p>
                In the event of any third-party claim that the App or your possession and use of the App
                infringes that third party's intellectual property rights, Vivy, not Apple, will be solely
                responsible for the investigation, defense, settlement, and discharge of any such intellectual
                property infringement claim.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">8. Legal Compliance</h2>
              <p>
                You represent and warrant that you are not located in a country or region that is subject to a
                U.S. Government embargo, or that has been designated by the U.S. Government as a
                "terrorist-supporting" country, and that you are not listed on any U.S. Government list of
                prohibited or restricted parties.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">9. Third-Party Terms and Services</h2>
              <p>
                You must comply with applicable third-party terms when using the App. This includes the terms
                of your network or wireless carrier, Apple services such as iCloud, and any external services
                or infrastructure you access through the App, such as remote servers, Tailscale, Cloudflare,
                or similar providers.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">10. Restrictions</h2>
              <p>You may not:</p>
              <ul className="list-disc pl-5 space-y-1">
                <li>Reverse engineer, decompile, or disassemble the App</li>
                <li>Remove or alter any proprietary notices or labels</li>
                <li>Share or distribute your App Store purchase with others</li>
                <li>Use the App for any unlawful purpose</li>
                <li>Attempt to gain unauthorized access to remote servers</li>
              </ul>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">11. SSH Connections</h2>
              <p>paullm-ssh facilitates SSH connections to servers you configure. You are solely responsible for:</p>
              <ul className="list-disc pl-5 space-y-1">
                <li>Ensuring you have authorization to access the servers you connect to</li>
                <li>Safeguarding your credentials and SSH keys</li>
                <li>Any actions performed through SSH connections made via the App</li>
              </ul>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">12. Disclaimer of Warranties</h2>
              <p className="font-semibold text-slate-950 dark:text-white uppercase text-[12px]">
                THE APP IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT WARRANT
                THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE. SSH CONNECTIONS ARE MADE DIRECTLY
                BETWEEN YOUR DEVICE AND REMOTE SERVERS; WE DO NOT PROXY, TRACK, OR INSPECT THIS TRAFFIC.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">13. Limitation of Liability</h2>
              <p className="font-semibold text-slate-950 dark:text-white uppercase text-[12px]">
                IN NO EVENT SHALL VIVY TECHNOLOGIES CO., LIMITED BE LIABLE FOR ANY INDIRECT, INCIDENTAL,
                SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF YOUR USE OF THE APP, INCLUDING BUT
                NOT LIMITED TO DATA LOSS, UNAUTHORIZED ACCESS, OR SERVER DOWNTIME.
              </p>
            </section>

            <section className="space-y-2.5">
              <h2 className="text-base font-bold text-slate-950 dark:text-white">14. Contact</h2>
              <p>For questions, complaints, or claims regarding the App, contact:</p>
              <div className="border-l-2 border-slate-200 pl-3 py-1 font-mono text-[12px] text-slate-500 dark:border-zinc-800 dark:text-zinc-400">
                Vivy Technologies Co., Limited<br />
                Room 706, Ho King Commercial Centre<br />
                2-16 Fa Yuen Street, Mongkok, Kowloon<br />
                Hong Kong<br />
                Email: <a href="mailto:apple@vivy.company" className="underline">apple@vivy.company</a>
              </div>
            </section>
          </div>
        </article>
      </div>
    </main>
  );
}
