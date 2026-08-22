# Review of M3 Remediation Work — Required Fixes

**Reviewed:** 2026-06-11, branches `remediation/review-fixes` (Phases 1–8 of
`docs/M3_REMEDIATION_PLAN.md`) and `remediation/full-ship` (11 additional
commits on top, co-authored by a different agent).
**Verdict:** Phases 1–5 and 7 are correct and well-executed. Phase 6 (host-key
prompts) is wired but **functionally dead-ends the connection** (F1). Phase 8
introduced a **typing-latency regression** (F2). The Phase 6b working-tree
incident destroyed in-flight work that was later re-implemented **with
regressions** (F3). Fixes below are ordered by severity; each is one commit on
a branch off `remediation/full-ship`. The ground rules in
`docs/M3_REMEDIATION_PLAN.md` Phase 0 apply (stage exact paths only, build
check after each fix, locate code by symbol).

---

## F1 — CRITICAL: host-key prompt dead-ends the connection

**What's wrong.** When `verifyHostKey()` throws `hostKeyUnknown`/`hostKeyMismatch`,
the error handlers set the prompt and `return` **without updating session
state**, and no decision handler retries the connection:

- `SSHTerminalWrapper.swift` ~line 314 and `TerminalView.swift` ~line 1249:
  the early `return` skips `updateSessionState(.failed)` /
  `updatePaneState(.failed)`, so the session sits in `.connecting`
  (spinner) forever.
- `ConnectionSessionManager.approveHostKeyPrompt` saves trust and clears the
  prompt — its own doc comment says "the caller is expected to retry the
  connection," but the alert button in `iOSContentView` calls nothing else.
  Tapping **Trust & Connect** connects nothing.
- `removeStaleHostKeyAndRePrompt` removes the pin but never reconnects,
  despite the button label "Remove Old Key & Reconnect". The promised fresh
  "unknown" prompt never appears.
- **Cancel** also leaves the session in `.connecting`.
- Same three gaps in the macOS pair (`TerminalTabManager` +
  `ConnectionTabsView`), which we care about only to the extent it must
  keep compiling — fix iOS properly; apply the same minimal state fix to the
  macOS handlers since the code is parallel.

**Fix (iOS path, the one that matters):**

1. In `SSHTerminalWrapper.swift`, when setting the prompt, also set a
   user-visible non-spinner state before returning:
   `ConnectionSessionManager.shared.updateSessionState(sessionId, to: .failed(error.localizedDescription))`
   — i.e. set the prompt **and** the failed state (do not early-return past
   the state update). The existing failed-state UI already offers reconnect.
2. `approveHostKeyPrompt(promptId:)`: after `preApprove` + clearing the
   prompt, trigger the existing retry path for that session. The session id
   is `prompt.id`. Use the same mechanism the failed-state "Reconnect" button
   uses — find it via `ConnectionSessionManager.reconnect(session:)`
   (~line 953) and how `iOSContentView` invokes it (search `reconnect(session:`
   and `reconnectTokenBySession`); reuse that exact path, do not invent a new
   one. Because the manager is `@MainActor`, kick the async call in a `Task`.
3. `removeStaleHostKeyAndRePrompt(promptId:)`: same — after `removeEntry`,
   trigger the same retry. The retried connection will throw `hostKeyUnknown`
   and surface the fingerprint-confirmation prompt, completing the intended
   "remove → reconnect → confirm new key" flow.
4. `cancelHostKeyPrompt(promptId:)`: set the session state to
   `.failed(String(localized: "Host key not trusted"))` if it is still
   `.connecting`.
5. Mirror 2–4 on `TerminalTabManager` for the macOS pane handlers using the
   pane-level equivalents already present in that file (search
   `updatePaneState`, and whatever the pane retry path is — follow the
   failed-pane UI's reconnect button).
6. **Verification (manual, required):** connect to a brand-new host → prompt
   appears with fingerprint → Trust & Connect → session actually connects.
   Then remove the host in Settings → Known Hosts, change nothing, reconnect
   → prompt again. Then simulate a mismatch (edit the stored fingerprint via
   a temporary debug tweak or connect to a host whose key changed) → changed
   prompt → Remove Old Key & Reconnect → unknown prompt → trust → connected.

**Commit:** `fix(terminal): host-key prompt resolves into reconnect instead of dead-ending`

## F2 — HIGH: poll backoff adds up to 250 ms first-keystroke latency

**What's wrong.** Phase 8 (`e863289`) widens the idle `poll()` timeout to
250 ms inside `SSHSession.ioLoop()`. But `waitForSocket` performs a **blocking**
`poll()` on the actor's thread, and `SSHSession.write(_:to:)` is an actor
method — so a keystroke arriving while the loop sits in a 250 ms idle poll
waits for the poll to expire before the write can even start. The old fixed
5 ms poll kept that serialization invisible; 250 ms is a visible typing hiccup
on an idle connection — the exact symptom this app is trying to eliminate.
(The diff's "no latency cost" comment is only true for inbound data, which
wakes `poll` immediately; locally-originated writes do not.)

**Fix:** release the actor while waiting. In `SSHClient.swift`:

1. Split the wait into two functions:
   - Keep the existing blocking `waitForSocket(timeoutMs:)` for the
     read/write/exec retry paths that currently call it with short timeouts
     (call sites near lines 1352–1622) — those are mid-operation waits where
     blocking 5 ms is correct.
   - Add `waitForSocketOffActor(timeoutMs: Int32) async` used **only by the
     ioLoop idle path**: compute `pfd` (fd + direction events) on the actor,
     then suspend the actor while a global queue does the blocking poll:
     ```swift
     await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
         var pfd = pfd
         DispatchQueue.global(qos: .userInitiated).async {
             _ = poll(&pfd, 1, timeoutMs)
             cont.resume()
         }
     }
     ```
     With the actor free, `write()` runs immediately when a keystroke
     arrives; the written bytes go to the server and the reply data wakes
     the in-flight `poll` via POLLIN. Guard for `socket >= 0` before
     dispatch, and tolerate the socket closing mid-poll (poll returns with
     POLLNVAL/error; the loop's next iteration sees `libssh2Session == nil`
     and exits — verify this by reading the loop's exit conditions).
2. Keep the 5 ms → 250 ms doubling logic exactly as is; only the waiting
   mechanism changes.
3. Re-check `disconnect()`/`abort()` interplay: `AtomicSocket`/abort closes
   the fd from another thread today while the old blocking poll was in
   flight, so this situation already existed; just confirm the detached poll
   doesn't touch any actor state after resume beyond returning.

**Verification:** type into an idle session over a real connection — no
perceptible first-keystroke delay; leave a session idle and confirm (via
`log stream` or Instruments) wakeups drop versus 5 ms polling.

**Commit:** `fix(ssh): run idle socket poll off-actor so writes aren't serialized behind backoff`

## F3 — HIGH: re-implemented ConnectionSessionManager APIs lost behavior

**Background.** Phase 6b reset four dirty files to HEAD, destroying in-flight
work (documented in `docs/M3_REMEDIATION_NOTES.md`). Commit `1c39598` later
re-implemented three lost methods as thin wrappers — and they are missing
behavior the originals had (the originals were read during the 2026-06-10
review; the deltas below are against that source).

In `paullm-ssh/Features/TerminalSessions/Application/ConnectionSessionManager.swift`:

1. **Duplicated guard (trivial):** `openConnection` now checks
   `ServerManager.shared.isServerLocked(server)` twice back-to-back
   (~lines 261–264). Delete the duplicate.
2. **`remoteTmuxSessions(for:)` regressions** — restore the original behavior:
   ```swift
   func remoteTmuxSessions(for server: Server) async -> [TmuxAttachSessionInfo] {
       guard tmuxResolver.isTmuxEnabled(for: server.id) else { return [] }
       guard await AppLockManager.shared.ensureServerUnlocked(server) else { return [] }

       if let client = activeSSHClient(for: server.id) {
           let sessions = await RemoteTmuxManager.shared.listSessions(using: client)
           return tmuxResolver.sessionInfosForPrompt(from: sessions)
       }

       do {
           let credentials = try KeychainManager.shared.getCredentials(for: server)
           let client = SSHClient()
           _ = try await client.connect(to: server, credentials: credentials)
           let sessions = await RemoteTmuxManager.shared.listSessions(using: client)
           await client.disconnect()
           return tmuxResolver.sessionInfosForPrompt(from: sessions)
       } catch {
           logger.warning("Failed to list remote tmux sessions for \(server.name, privacy: .public): \(error.localizedDescription, privacy: .public)")
           return []
       }
   }
   ```
   The current wrapper returns `[]` when no client is connected — which
   guts the "pick a tmux session after selecting the host" flow (you are by
   definition not connected yet) — and it skips
   `tmuxResolver.sessionInfosForPrompt(from:)`, so internal
   `paullm_<device>_<uuid>` managed sessions leak into the picker. Adapt
   helper names to what exists at HEAD (`activeSSHClient(for:)` vs
   `sshClient(for:)` — use whichever compiles; intent: "the connected
   client for this server, if any").
3. **`openExistingTmuxSession(named:on:)` regression** — after
   `openConnection`, the original recorded the attachment so reconnects
   reuse the same tmux session. Restore:
   ```swift
   tmuxResolver.updateAttachmentState(
       for: session.id,
       selection: .attachExisting(sessionName: sessionName),
       setPrompt: setTmuxAttachPrompt
   )
   ```
   before returning the session. Without it, a reconnect of that tab runs
   the full attach resolution again and (under `askEveryTime`) re-prompts,
   or (under `paullmManaged`) attaches to the wrong (managed) session.

**Verification:** from the server list with NO active connection, open the
new-session picker — existing remote tmux sessions are listed; internal
`paullm_*` sessions are not (unless attached); attach to one, kill the app,
relaunch, reconnect that tab — it reattaches to the same named session
without prompting.

**Commit:** `fix(sessions): restore tmux listing/attach behavior lost in phase 6b reset`

## F4 — MEDIUM: unit tests have never executed — fix the runner bootstrap

The notes' claim was verified: `xcodebuild test` fails for **every** test
target with "test runner exited with code 6 before establishing connection"
(reproduced 2026-06-11 on macOS destination, including for the new
`KnownHostsManagerTests`). So all tests added in this effort
(`KnownHostsManagerTests`, `HostKeyPromptTests`, plus the full pre-existing
suite) are compile-checked but unvalidated.

1. Diagnose: exit code 6 is a SIGABRT/SIGTRAP-class crash during test-host
   app launch. Get the crash log
   (`~/Library/Logs/DiagnosticReports/paullm-ssh-*.ips` newest entry, or the
   `.xcresult` from the failed run) and find the crashing frame. Prior commit
   `84b9563` fixed a similar SIGTRAP from force-unwrapped `Logger` inits —
   suspect something similar in app startup (note
   `KnownHostsManager.shared` now performs Keychain access during static
   init; with `CODE_SIGNING_ALLOWED=NO` the keychain can return
   `errSecMissingEntitlement`, which the code handles by returning nil — but
   confirm via the crash log rather than assuming).
2. Fix whatever the crash log shows (smallest possible change), then run the
   full unit-test suite and fix any failing **new** tests. Pre-existing test
   failures unrelated to this work: report, don't fix.
3. If the crash is environmental (provisioning/keychain ACL on this host)
   and not fixable in code, document the exact evidence in the notes file —
   "we think it's signing" is not enough; cite the crash frame.

**Commit:** `fix(tests): <whatever the crash log dictates>` +
`test: validate KnownHostsManagerTests and HostKeyPromptTests pass`

## F5 — LOW: review the smuggled deinit changes in commit 841d56b

Commit `841d56b` ("typed host-key errors") also contains unrelated `deinit`
rewrites in `SSHTerminalWrapper.swift` (replacing `Task { @MainActor [self] in
cancelShell() }` with detached tasks capturing only `sshClient`/`shellId`,
to avoid retaining `self` during dealloc). The change itself looks plausible
(it matches a known Swift trap), but it was never reviewed on its own and the
commit message doesn't mention it. Action: read both deinit blocks, confirm
`shellTask?.cancel()` + `closeShell` covers everything `cancelShell()` did
(diff the two implementations), and confirm `terminalView.cleanup()` is still
called on the path that needs it. If equivalent, no code change — record the
confirmation in the notes file so the hidden change is on the record.

## Process notes (no code action, for the human)

- **Phase 6b destroyed uncommitted in-flight work** in four files by checking
  them out to HEAD (admitted in `M3_REMEDIATION_NOTES.md`). F3 restores the
  known functional losses, but there may be lost changes in
  `TerminalTabManager.swift` / `ConnectionTabsView.swift` /
  `iOSContentView.swift` nobody has inventoried. Cross-check the feature list
  in `docs/CONTINUATION_PLAN.md`'s session log against the app before the
  next release.
- The `remediation/full-ship` branch also bumped the build number and
  committed `ExportOptions.plist` (`d61cad3`) "per the runbook" — a release
  prep step no plan asked for. Harmless content (team ID is not a secret),
  but treat the build number as unshipped until a human decides to ship.
- Phases 1–5, 7 reviewed clean: gitignore/docs/script/log fixes exact;
  known-hosts Keychain store + migration correct (always `iCloudSync: false`);
  `verifyHostKey` no longer auto-trusts; Known Hosts settings screen solid.
- Nothing has been pushed; all branches are local. Keep it that way until F1–F3
  land.
