# PAULLM SSH App Store Readiness Review

- Date: 2026-08-16
- Repository: `/Users/paul/Documents/paullmssh/paullm-ssh`
- Branch: `remediation/full-ship`
- App Store Connect app: `PAULLM SSH` (`6775278799`)
- Bundle ID: `app.paullm.ssh`
- Audit scope: iOS client, release build configuration, TestFlight state, App Store Connect record, legal/privacy surfaces, and current uncommitted remediation work

## Executive Decision

The iOS app has been refreshed for internal TestFlight as version `1.0` build `2026.817.0008`, but it is not ready for public App Store review. The device and simulator builds pass, the full unit suite passes, the focused simulator UI smoke test passes, and the Ghostty artifacts now support the app's iOS 16 deployment target. The public listing and compliance setup remain largely empty, and several product, legal, and hands-on device-validation items still need completion.

Do not submit the current App Store version for review.

## Verified Current State

- Generic iOS device Debug compile/link: passed with `** BUILD SUCCEEDED **` and no newer-iOS Ghostty linker warnings.
- arm64 simulator build and launch: passed on iPhone 17 Pro / iOS 26.5.
- Tests discovered: approximately 297 test declarations across unit and UI test targets.
- Focused simulator UI smoke test on iPhone 17 Pro / iOS 26.5: passed for onboarding, empty-server state, Settings, About/contact, and Add Server.
- Tests executed: the complete `paullm-sshTests` unit suite passed with `** TEST SUCCEEDED **`. Two stale/asynchronous expectations were updated to match the current remote-shell and liveness-probe behavior. UI coverage remains the focused manual smoke test.
- Current local marketing version: `1.0`.
- Current local build number: `2026.817.0008`.
- TestFlight upload: version `1.0`, local build `2026.817.0008` (normalized by App Store Connect to `2026.817.8`) uploaded successfully on 2026-08-17 and reached `VALID`. Its internal state is `IN_BETA_TESTING` with automatic tester notification enabled.
- Current App Store version: `1.0`, state `PREPARE_FOR_SUBMISSION`.
- Current working tree: substantial pre-existing uncommitted app, documentation, and website work. This audit did not reset or overwrite it.
- App Store submission: not performed. The user approved only the internal TestFlight refresh.
- Release-facing fixes made during the audit: corrected invalid support email links and replaced the About screen's generic `#` tile with the compiled app icon.
- Release scope: iOS only. macOS validation and release work are explicitly deferred.

## Release Blockers

### P0 — Product and App Store Connect

1. **Choose one business model and make every surface agree.**
   - The client intentionally removed StoreKit and sets every user to Pro/lifetime access.
   - App Store Connect contains no in-app purchases or subscription groups.
   - The website/marketing draft still advertises monthly, yearly, and lifetime Pro tiers and free-tier limits.
   - Recommended decision for the first release: ship the app fully free, remove the stale Pro/pricing claims, and delete dormant product-ID/store-state code in a later cleanup. Reintroducing subscriptions now expands review and testing risk.

2. **Complete the App Store listing.** The live record currently has:
   - no description;
   - no keywords;
   - no subtitle or promotional text;
   - no support URL;
   - no privacy policy URL;
   - no screenshots;
   - no selected build;
   - no review contact or review notes;
   - no completed age-rating answers;
   - no base price territory.

3. **Restore public support/legal URLs.**
   - `paullm.dev` currently has no A or AAAA DNS record from this Mac.
   - The app links to `https://paullm.dev`, `/privacy`, and `/terms`.
   - App Review requires functional URLs and accurate support contact information.
   - The in-app invalid `mailto:support.dev` links were corrected during this audit to the address already used by the website draft, `vvterm@vivy.company`.

4. **Complete App Privacy in App Store Connect.**
   - Apple requires a privacy-policy URL and published data-handling answers.
   - The local privacy manifest declares UserDefaults required-reason API use and no collected data; this does not replace the App Store Connect privacy questionnaire.
   - Review CloudKit metadata sync, iCloud Keychain credential sync, Hugging Face/OpenAI model downloads, and every third-party dependency before answering.
   - The draft policy incorrectly says uninstalling deletes all app data. Keychain and CloudKit data may persist after uninstall; document the real deletion workflow or add one.

5. **Make and document the export-compliance determination.**
   - This SSH client embeds libssh2 and OpenSSL and therefore uses standard encryption.
   - `ITSAppUsesNonExemptEncryption` is currently `false`.
   - That value may be correct only if the app's encryption use is exempt. Complete Apple's export-compliance questions and obtain the appropriate legal/compliance determination before public submission; do not interpret `false` as “the app does not use encryption.”

6. **Provide App Review a working review path.**
   - The app's core experience requires an SSH endpoint.
   - Provide a stable demo SSH server/account with non-sensitive sample data, or obtain approval for a built-in demo mode.
   - Review notes should explain SSH, SFTP, remote tmux/tool installation, Cloudflare/Tailscale paths, microphone/speech permissions, iCloud sync, and that Toolkit commands execute on the user's remote host—not on iOS.

### P0 — Binary and Runtime

7. **Complete real-device functional smoke testing.**
   - The Ghostty iOS device and simulator artifacts were rebuilt from fork commit `91fe505e60bbe72ff08c881d2882acad6a56cb9f` with minimum iOS 16.0, resolving the prior deployment-target mismatch.
   - The Xcode unit-test runner now executes successfully and the full unit suite passes.
   - Exercise onboarding, server creation, password/key auth, host-key prompts, reconnect, tmux attach/create/close, tabs/splits, SFTP operations, local discovery permission, Cloudflare/Tailscale connection modes, voice permissions/model downloads, app lock, iCloud sync, and cold launch.
   - Test on at least one real iPhone before App Review.

## High-Priority Gaps

1. **iPhone/iPad scope is inconsistent.** The target is universal (`TARGETED_DEVICE_FAMILY = 1,2`) and marketing claims iPad support, while the general runbook calls the product iPhone-only. Keep iPad only if it receives full layout QA and iPad screenshots; otherwise change the target and claims together.

2. **Third-party notices are incomplete.** `THIRD_PARTY_NOTICES.md` covers Ghostty, libssh2, and OpenSSL, but the shipped Swift packages also include MLX Swift, Swift Cloudflared, Swift Mosh, Swift Numerics, TweetNacl, and ZIPFoundation. Add their license notices and verify all transitive licenses are compatible with distribution.

3. **The App Store binary license document is stale.** `LICENSE-APPSTORE.md` still names VVTerm and links to `vvterm.com/terms`. Align it with PAULLM SSH, the actual legal entity, and a live terms URL.

4. **Two input-buffer actions are explicit no-ops.** `InputBufferSheet` contains TODO closures for voice transcription and snippet selection. Wire them completely or remove/hide the controls before submission.

5. **Brand strings are inconsistent.** App Store Connect says `PAULLM SSH`, the icon label is `paullmssh`, in-app copy uses `paullm-ssh`, and legal/support content retains VVTerm/Vivy references. Choose a display brand and legal attribution, then scrub all user-facing surfaces.

6. **Marketing/privacy text contradicts the binary.** The website draft discusses Pro purchases even though StoreKit is removed, and its privacy policy describes purchase verification that the app does not perform.

7. **Submission-account checks remain.** Confirm active agreements, tax/banking setup if the app will be paid, distribution territories, EU DSA trader status, category, content-rights declaration, and accessibility nutrition labels in App Store Connect.

## TestFlight Refresh Gate

Completed for build `2026.817.0008`:

1. Selected the fully free first-release direction and version `1.0`.
2. Rebuilt Ghostty for iOS 16 and verified device/simulator linking.
3. Passed the complete unit suite and simulator UI smoke test.
4. Reviewed the release diff, bumped the build, archived, and uploaded with explicit approval.

Still required before relying on this beta for App Store acceptance:

1. Run the real-iPhone SSH/SFTP/tmux/reconnect smoke matrix above. App Store Connect processing and internal beta availability are confirmed.

## Recommended Shipping Sequence

1. Ship a fully free first release and remove all Pro/subscription claims.
2. Fix Ghostty's minimum-version build and complete the no-op input-buffer actions.
3. Run automated tests, simulator UX review, and real-device SSH/SFTP regression testing.
4. Upload a fresh internal TestFlight build for hands-on acceptance.
5. Deploy the support/privacy/terms site and validate every in-app URL publicly.
6. Complete App Store metadata, screenshots, privacy, age rating, export compliance, pricing/availability, and review credentials.
7. Select the accepted TestFlight build and submit only after a final clean-archive validation.

## Apple References

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App privacy: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- Export compliance: https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance
- Current submission toolchain requirements: https://developer.apple.com/news/upcoming-requirements/
