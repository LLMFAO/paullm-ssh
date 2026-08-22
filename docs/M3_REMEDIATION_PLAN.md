# Remediation Plan — Code Review Follow-ups

**Audience:** an AI coding agent (MiniMax M3) executing this plan autonomously.
**Source:** code review of 2026-06-10 (security, performance, hygiene findings).
**Repo:** `paullm-ssh` — iOS/macOS SSH terminal app, Swift, Xcode project at repo root.

Read `CLAUDE.md` at the repo root before starting. Its architecture rules
(feature-first layout, `Domain`/`Application`/`Infrastructure`/`UI` boundaries,
atomic commits) are binding for every phase below.

---

## 0. Ground rules (read first, no commit)

1. **The working tree is dirty on purpose.** The branch
   `codex/typed-coding-sessions` carries ~84 modified/untracked entries of
   unrelated in-progress work. You MUST NOT commit, revert, stash, or reformat
   any file you were not explicitly told to touch.
   - **Never run `git add .`, `git add -A`, or `git commit -a`.**
   - Stage files one by one, by exact path, only the files this plan tells you
     to create or edit.
2. Create a working branch off the current branch:
   `git checkout -b remediation/review-fixes`
3. One phase = one commit (Phase 6 is allowed two). Use the commit message
   given at the end of each phase. Do not bundle phases.
4. **Build verification.** Vendor libraries must exist before the app builds.
   If `Vendor/libghostty/GhosttyKit.xcframework` is missing, run
   `./scripts/build.sh all` once (slow; requires `zig` and `cmake`).
   - Build check: `xcodebuild build -project paullm-ssh.xcodeproj -scheme paullm-ssh -destination 'platform=macOS,arch=arm64' | tail -20`
   - Test check: `xcodebuild test -project paullm-ssh.xcodeproj -scheme paullm-ssh -destination 'platform=macOS,arch=arm64' -only-testing:paullm-sshTests 2>&1 | tail -30`
   - Run the build check after every phase that touches Swift code. Run the
     test check after Phases 5, 6, and 8.
5. Line numbers in this plan are approximate anchors from the review date.
   Always locate code by the quoted symbol/string, not the line number.
6. Preserve existing UI/UX except where a phase explicitly adds a screen or
   alert. No redesigns, no renames beyond what is specified.
7. If a phase turns out to be impossible as written (missing API, conflicting
   in-flight work), skip it, leave the tree clean, and record why in a
   `docs/M3_REMEDIATION_NOTES.md` file. Do not improvise a different design.

---

## Phase 1 — Repo hygiene: ignore build output, evict stray project

**Problem:** `build/` and `build-claude/` contain `.xcarchive`s and logs but are
not gitignored (one `git add .` from being committed). `BlockBlast/` is a
different app's TestFlight deploy scripts living inside this repo (untracked).

**Steps:**
1. Append to `.gitignore` under the `# Xcode` section:
   ```
   build/
   build-claude/
   ```
2. Move `BlockBlast/` out of the repo to the parent directory:
   `mv BlockBlast ../BlockBlast-deploy-scripts`
   (It is untracked, so git is unaffected. Do not delete it.)

**Acceptance:** `git status --porcelain | grep -E "build/|build-claude/|BlockBlast"`
prints nothing.

**Commit:** `chore: gitignore local build output and move BlockBlast scripts out of repo`
(stage only `.gitignore`)

---

## Phase 2 — Fix documentation that contradicts the code

**Problem:** `CLAUDE.md` makes two false claims that will mislead future agents:

1. "Important Notes" item 4 says *"Keychain credentials are NOT synced - only
   server metadata syncs via CloudKit."* This is wrong. See
   `paullm-ssh/Core/Security/KeychainManager.swift`: every `store.set(...)`
   call passes `iCloudSync: isSyncEnabled`, so passwords, private keys,
   passphrases, and Cloudflare secrets sync via **iCloud Keychain**
   (`kSecAttrSynchronizable`, see `KeychainStore.swift`) whenever the user's
   sync setting is on. Server metadata syncs separately via CloudKit.
2. The "Data Sync" section says the CloudKit container is
   `iCloud.app.vivy.VivyTerm`. The entitlements
   (`paullm-ssh-iOS/paullm-ssh.entitlements`) say `iCloud.app.paullm.ssh`.

**Steps:**
1. In `CLAUDE.md`, replace item 4 of "Important Notes" with:
   `4. **Credential sync**: server metadata syncs via CloudKit; credentials (passwords, SSH keys, passphrases, Cloudflare tokens) sync via iCloud Keychain when sync is enabled (see KeychainStore.set's iCloudSync parameter). Nothing credential-shaped goes through CloudKit.`
2. In `CLAUDE.md` "Data Sync", change the container to `iCloud.app.paullm.ssh`.
3. In `paullm-ssh/Core/Security/KeychainManager.swift`, delete the method
   `enableiCloudSync(for:)` (~line 181). It is a no-op that logs success and
   has **zero call sites** (verify with
   `grep -rn "enableiCloudSync" paullm-ssh --include="*.swift"` — if call
   sites appeared since the review, leave the method alone and only do the
   doc edits).

**Acceptance:** build check passes; `grep -n "vivy" CLAUDE.md` prints nothing.

**Commit:** `docs: correct credential-sync and CloudKit container claims; drop no-op enableiCloudSync`

---

## Phase 3 — Setup script: stop creating the AI user as admin

**Problem:** `scripts/setup-ssh-host.sh`, function `step_create_ai_user`
(~line 241): the comment says "Create a standard user" but the command passes
`-admin` to `sysadminctl`. A dedicated SSH account for AI coding tools must not
be an administrator.

**Steps:**
1. Remove the `-admin` flag from the `sysadminctl -addUser` invocation.
2. Add an opt-in flag `--ai-user-admin` (default off) following the existing
   option-parsing style in the script (look at how `--with-ai-user` is
   parsed). When set, append `-admin` to the command. Update the `--help` text
   in the same style as neighboring options.
3. Run `bash -n scripts/setup-ssh-host.sh` to syntax-check.

**Acceptance:** `bash -n` exits 0; default invocation contains no `-admin`.

**Commit:** `fix(scripts): create AI user as standard account; admin requires explicit --ai-user-admin`

---

## Phase 4 — Stop logging remote stderr publicly

**Problem:** `paullm-ssh/Core/SSH/SSHClient.swift`, in `finishExecRequest`
(~line 2086): `logger.debug("Exec command stderr: \(stderr, privacy: .public)")`
writes arbitrary remote command output unredacted to the unified system log.

**Steps:** change `privacy: .public` to `privacy: .private` in that one call.
Do not change other log lines.

**Acceptance:** build check passes;
`grep -n "Exec command stderr" paullm-ssh/Core/SSH/SSHClient.swift` shows
`.private`.

**Commit:** `fix(ssh): redact remote exec stderr in unified log`

---

## Phase 5 — Known hosts: move storage to Keychain, inject it, test it

**Problem:** `paullm-ssh/Core/SSH/KnownHostsManager.swift` stores host-key
fingerprints (the SSH trust anchors) as JSON in `UserDefaults` — a
user-writable plist that any same-user process can tamper with on macOS. It is
also a hard singleton (`KnownHostsManager.shared`) referenced directly inside
`SSHClient.verifyHostKey()`, so nothing about host-key verification is
testable. There are currently no tests for it.

**Design (do exactly this, no more):**
1. In `KnownHostsManager.swift`, add a storage protocol and two impls:
   ```swift
   protocol KnownHostsStorage: Sendable {
       func loadData() -> Data?
       func saveData(_ data: Data)
   }
   ```
   - `KeychainKnownHostsStorage`: uses the existing `KeychainStore`
     (`paullm-ssh/Core/Security/KeychainStore.swift`) with
     `service: "app.paullm.ssh"` and account key `"paullm.knownHosts"`,
     always `iCloudSync: false` (trust anchors must stay per-device).
     `KeychainStore` methods are `nonisolated` and the class is `Sendable` —
     use it directly.
   - `UserDefaultsKnownHostsStorage`: wraps the current
     `UserDefaults.standard.data(forKey: "paullm.knownHosts")` behavior
     (kept for migration only).
2. Change `KnownHostsManager`:
   - `init(storage: KnownHostsStorage)` becomes internal/visible; keep
     `static let shared = KnownHostsManager(storage: KeychainKnownHostsStorage())`.
   - `loadAll()`/`saveAll()` go through `storage`.
   - Add a one-time migration inside `init`: if Keychain storage is empty and
     the UserDefaults key has data, decode it, save it to Keychain, then
     `UserDefaults.standard.removeObject(forKey:)` the old key. Keep the
     existing `NSLock` discipline.
   - Add `func removeEntry(host: String, port: Int)` and
     `func allEntries() -> [Entry]` (sorted by `host`, then `port`) — Phase 6
     and Phase 7 need them.
3. `SSHClient` keeps using `KnownHostsManager.shared` at the call sites but
   route access through one private property
   (`private let knownHosts: KnownHostsManager = .shared`) so tests of future
   refactors have a single seam. Do NOT attempt a full DI refactor of
   `SSHClient` — out of scope.
4. New test file `paullm-sshTests/KnownHostsManagerTests.swift` using an
   in-memory `KnownHostsStorage` fake. Match the style of existing tests in
   `paullm-sshTests/` (look at `TerminalDefaultsTests.swift` for conventions).
   Cover: save/lookup round-trip, `updateSeen` updates `lastSeenAt` only,
   `removeEntry` removes exactly one host:port, migration from a populated
   UserDefaults fake into empty Keychain fake, corrupted JSON returns empty.

**Acceptance:** build + test checks pass, including the new tests.

**Commit:** `refactor(ssh): store known hosts in Keychain with UserDefaults migration; add tests`

---

## Phase 6 — Host-key trust prompt and mismatch recovery (the main feature)

**Problem (two halves):**
- `SSHClient.verifyHostKey()` (~line 1192) silently trusts any unknown host's
  key (logs and pins it). The user never sees a fingerprint, so a
  man-in-the-middle present on first connect is invisible and gets pinned.
- On fingerprint mismatch it throws `SSHError.hostKeyVerificationFailed`,
  which the UI lumps into a generic failure case
  (`paullm-ssh/Features/TerminalSessions/UI/Terminal/SSHTerminalWrapper.swift`
  ~line 289 and
  `paullm-ssh/Features/TerminalSessions/UI/Splits/TerminalView.swift`
  ~line 1223). There is no way to see the fingerprints or to remove the stale
  pin, so a legitimately reinstalled server locks the user out permanently.

**Design — "throw, prompt, retry".** Do not build a callback/delegate from the
actor into SwiftUI. Instead the connection fails fast with a typed error
carrying the fingerprint(s); the UI shows a prompt; on user approval the UI
records the decision in `KnownHostsManager` and retries the connection, which
then verifies cleanly. This mirrors how the codebase already handles
interactive decisions (see `TmuxAttachPrompt` in
`paullm-ssh/Features/TerminalSessions/Domain/TmuxAttachPrompt.swift` and its
flow through `ConnectionSessionManager`).

**Steps:**

1. **Errors.** In `SSHClient.swift`'s `SSHError` enum (~line 2841), replace the
   bare `hostKeyVerificationFailed` with two cases:
   ```swift
   case hostKeyUnknown(host: String, port: Int, fingerprint: String, keyType: Int)
   case hostKeyMismatch(host: String, port: Int, knownFingerprint: String, presentedFingerprint: String, keyType: Int)
   ```
   Keep `hostKeyVerificationFailed` only if other code matches on it that you
   cannot update; otherwise delete it. Give both cases proper
   `errorDescription` strings using `String(localized:)` like the Tailscale
   case does, e.g. mismatch: *"Host key for %@:%d has CHANGED. Known: %@,
   presented: %@. This can indicate a man-in-the-middle attack."*
2. **verifyHostKey.** Change the unknown-host branch: instead of auto-saving,
   `throw SSHError.hostKeyUnknown(...)`. Keep the mismatch branch but throw
   the new `hostKeyMismatch` with both fingerprints. Add a parameter so a
   *pre-approved* first connection can pass:
   the cleanest mechanism is a new method on `KnownHostsManager`,
   `func preApprove(host:port:fingerprint:keyType:)`, which writes the entry —
   then `verifyHostKey` needs no signature change at all: after the user
   approves the prompt, the UI calls `preApprove`, retries, and the existing
   lookup path matches. Use that mechanism (`preApprove` can be an alias for
   `save(entry:)` with fresh dates).
3. **Domain type.** New file
   `paullm-ssh/Features/TerminalSessions/Domain/HostKeyPrompt.swift`:
   ```swift
   struct HostKeyPrompt: Identifiable, Equatable {
       enum Kind: Equatable {
           case unknown                      // first contact
           case changed(knownFingerprint: String)
       }
       let id: UUID            // session/pane id awaiting the decision
       let serverId: UUID
       let serverName: String
       let host: String
       let port: Int
       let presentedFingerprint: String
       let keyType: Int
       let kind: Kind
   }
   ```
4. **Wiring.** Find every place the two new errors surface to the user. Start
   from the two generic `case` lists cited above; trace how
   `TmuxAttachPrompt` gets from the connection layer to a sheet/alert and
   follow the same route (likely via `ConnectionSessionManager` /
   `TerminalTabManager` published state). Behavior:
   - `hostKeyUnknown` → present an alert/sheet titled "Verify Host Key"
     showing server name, `host:port`, and the SHA256 fingerprint in
     monospaced text, with buttons **Trust & Connect** (calls
     `KnownHostsManager.shared.preApprove(...)`, then triggers the same
     reconnect path the existing "Retry/Reconnect" UI uses) and **Cancel**
     (leaves the session disconnected, same as today's failure path).
   - `hostKeyMismatch` → alert titled "Host Key Changed" showing BOTH
     fingerprints and warning text, with a **destructive** button
     "Remove Old Key & Reconnect" (calls
     `KnownHostsManager.shared.removeEntry(host:port:)`, then reconnects — the
     retry will now surface the `unknown` prompt so the user still sees and
     confirms the new fingerprint) and **Cancel**.
   - Strings go through `String(localized:)`; add them to
     `paullm-ssh/Resources/en.lproj/Localizable.strings` only (other locales
     fall back to English).
   - Implement for both iOS and macOS code paths (both files cited above).
     Keep platform parity.
5. **Tests.** New file
   `paullm-sshTests/Features/TerminalSessions/HostKeyPromptTests.swift`:
   construct prompts from both error cases and assert field mapping; test that
   `preApprove` followed by `entry(for:)` returns a matching fingerprint, and
   that `removeEntry` + `entry(for:)` returns nil (reusing the Phase 5 fake).
   UI itself is not unit-tested — matches repo convention.

**Split into two commits:**
- `feat(ssh): typed host-key errors; require explicit trust for unknown host keys`
  (SSHClient + KnownHostsManager + domain type + tests)
- `feat(terminal): host-key trust and changed-key recovery prompts (iOS + macOS)`
  (UI wiring + Localizable.strings)

**Acceptance:** build + test checks pass. `grep -rn "hostKeyUnknown\|hostKeyMismatch"`
shows handling in both `SSHTerminalWrapper.swift` and `TerminalView.swift`.
A first connection can no longer pin a key without a code path through
`preApprove`.

---

## Phase 7 — Known Hosts management screen in Settings

**Problem:** users cannot inspect or remove pinned host keys.

**Steps:**
1. New file `paullm-ssh/Features/Settings/UI/KnownHostsSettingsView.swift`.
   Model it on `KeychainSettingsView.swift` (same folder) for structure and
   styling. Content: a `List` of `KnownHostsManager.shared.allEntries()`
   showing `host:port`, fingerprint (monospaced, line-limited), and
   added/last-seen dates; swipe-to-delete and an Edit/Delete affordance on
   macOS calling `removeEntry`; an empty-state text when there are no entries
   (reuse patterns from `paullm-ssh/Core/UI/EmptyStateViews.swift` if a
   suitable one exists — read it first).
2. Register it in `paullm-ssh/Features/Settings/UI/SettingsView.swift`: add a
   `NavigationLink { KnownHostsSettingsView() }` in the same `Section` as the
   `KeychainSettingsView` link (~line 106), label "Known Hosts", SF Symbol
   `checkmark.shield`. Mirror however `KeychainSettingsView` appears in the
   macOS settings surface (~line 170).
3. Localizable strings for new user-facing labels (en only).

**Acceptance:** build check passes; screen appears in Settings on both
platforms.

**Commit:** `feat(settings): known hosts list with remove support`

---

## Phase 8 — SSH I/O loop: stop waking 200×/sec when idle

**Problem:** `SSHClient.ioLoop()` (~line 1830) spins continuously;
`waitForSocket()` (~line 2093) blocks in `poll(&pfd, 1, 5)` — a fixed 5 ms
timeout. Per idle connection that is ~200 wakeups/sec on a Swift-concurrency
cooperative thread: battery drain and pool starvation.

**Design — adaptive idle backoff, NOT a DispatchSource rewrite:**
1. Change `waitForSocket()` to `waitForSocket(timeoutMs: Int32)` and pass the
   value through to `poll`.
2. In `ioLoop()`, track consecutive idle passes (`didWork == false` and all
   batch buffers empty). Timeout schedule: active (`didWork`) → 5 ms; after
   each idle pass double from 5 ms up to a 250 ms cap; reset to 5 ms the
   moment any byte is read or written. Latency impact is nil: `poll` returns
   immediately when data arrives — the timeout only bounds *empty* waits.
3. Other `waitForSocket()` call sites (read/write/exec paths, ~lines
   1352–1622) keep the old behavior: pass `5`.
4. Add a brief comment in `ioLoop` stating the schedule and the cap, and why
   (battery; poll returns early on readiness).

**Acceptance:** build + full test checks pass. Manually sanity-check the diff:
no behavior change other than the poll timeout value.

**Commit:** `perf(ssh): adaptive poll backoff in I/O loop to cut idle wakeups`

---

## Phase 9 (stretch — only if Phases 1–8 are committed and green)

De-sync credentials when the user turns sync off: in
`KeychainManager`/`KeychainStore`, when `SyncSettings.isEnabled` transitions
to false, rewrite each existing credential item with
`iCloudSync: false` so previously synced items leave iCloud Keychain. Find
where the sync toggle is handled (`grep -rn "SyncSettings" paullm-ssh
--include="*.swift"`) and hook there. If the toggle plumbing is entangled with
the uncommitted in-flight work on this branch, **skip this phase** and note it
in `docs/M3_REMEDIATION_NOTES.md`.

**Commit:** `fix(security): rewrite keychain items as device-only when sync is disabled`

---

## Explicitly OUT of scope (do not attempt)

- Splitting the 2k–3.5k-line files (`GhosttyTerminalView+iOS.swift`,
  `SSHClient.swift`, `iOSContentView.swift`, `RemoteFileBrowserScreen.swift`).
- Replacing the poll loop with `DispatchSource`.
- Full dependency-injection refactor of `SSHClient` or `KeychainManager`.
- Anything touching the uncommitted Toolkit/web/marketing work on this branch.
- Committing, rebasing, or pushing anything beyond the
  `remediation/review-fixes` branch commits listed above.

## Final deliverable

When done, write `docs/M3_REMEDIATION_NOTES.md` containing: the list of
commits made (hash + message), test results for the final run, and any skipped
phases with reasons. Do not push; leave the branch local for human review.
