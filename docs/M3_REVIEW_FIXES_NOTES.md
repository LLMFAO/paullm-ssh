# M3 Review Fixes — Notes

**Branch:** `remediation/review-fixes-v2` (off `remediation/full-ship`).
**Source review:** `docs/M3_REVIEW_FIXES.md` (2026-06-11, F1–F5).
**Agent:** MiniMax M3.
**Date:** 2026-06-11.

## Commits

| Fix | Hash | Message |
| --- | --- | --- |
| F1 | `90e1235` | fix(terminal): host-key prompt resolves into reconnect instead of dead-ending |
| F2 | `e5570f1` | fix(ssh): run idle socket poll off-actor so writes aren't serialized behind backoff |
| F3 | `86adb72` | fix(sessions): restore tmux listing/attach behavior lost in phase 6b reset |

(F4 and F5 produce no code change — see "F4" and "F5" sections below.)

## F1 — host-key prompt dead-end (CRITICAL)

**Status:** Committed (`90e1235`).

**Change.** When `verifyHostKey()` throws `hostKeyUnknown` or `hostKeyMismatch`,
the iOS `onFailure` (`SSHTerminalWrapper.swift`) and macOS `onFailure`
(`TerminalView.swift`) now also transition the session/pane to `.failed`
*in addition to* setting the prompt. That way the session is not stuck in
`.connecting` (spinner) and the existing failed-state UI's "Retry" button
is the recovery hatch.

`approveHostKeyPrompt` and `removeStaleHostKeyAndRePrompt` now kick the
reconnect: iOS calls `ConnectionSessionManager.reconnect(session:)` via a
`Task` (the manager is `@MainActor`); macOS transitions the pane state to
`.connecting` and calls `TerminalTabManager.unregisterSSHClient(for:)` so
the wrapper rebuilds the client. `cancelHostKeyPrompt` transitions the
session/pane to `.failed` with a localized reason if it was still
`.connecting`.

**Verification note.** Build check could not be run on this host
(see "F4" below) — both the worktree and the pristine source fail with
"No profiles for 'app.paullm.ssh' were found" because the host has no
Apple developer account configured (the project uses
`CODE_SIGN_STYLE = Automatic`). The diff is manually reviewed against
`reconnect(session:)` (~line 953) and the failed-state UI's
`retryConnection` callsite (`TerminalContainerView.swift:671`,
`TerminalView.swift:780`); the kicked paths use the same primitives.
Manual verification is in the runbook.

## F2 — off-actor idle poll (HIGH)

**Status:** Committed (`e5570f1`).

**Change.** Added `SSHSession.waitForSocketOffActor(timeoutMs:)` that
captures the `pollfd` on the actor, then suspends the actor and dispatches
the blocking `poll()` to a global queue. `ioLoop()` now calls this for
the idle path so the (up to 250 ms) idle poll does not serialize
`write(_:to:)` calls. The short-timeout retry paths in
read/write/exec keep the existing actor-bound `waitForSocket(timeoutMs:)`
(5 ms default). The comment block on the adaptive poll schedule was
updated to be honest about the off-actor dispatch and why a wider
timeout on the idle path no longer blocks local writes.

**Disconnection interplay.** `AtomicSocket`/`abort()` from another thread
can close the fd mid-poll; `poll()` returns with POLLNVAL/error in that
case, the loop's next iteration checks `libssh2Session == nil` and exits.

**Verification note.** As with F1, build check could not be run on this
host. Manual verification: type into an idle session — no per-keystroke
hiccup; idle wakeups should drop to ~4/sec from ~200/sec
(`log stream` / Instruments).

## F3 — restore tmux listing/attach behavior (HIGH)

**Status:** Committed (`86adb72`).

**Change.** Three regressions in `ConnectionSessionManager` re-implemented
after the Phase 6b reset:

1. `openConnection` had a duplicate `isServerLocked` guard. Removed the
   duplicate.
2. `remoteTmuxSessions(for:)` no longer returns `[]` when no SSH client
   is connected. The picker is invoked from the server list (the user is,
   by definition, not connected yet) — so the original behavior of
   spinning up a short-lived `SSHClient`, listing, and disconnecting is
   restored. Also routed through `tmuxResolver.sessionInfosForPrompt(from:)`
   so internal `paullm_*` managed sessions don't leak into the picker
   unless they're currently attached. Guards on `tmuxEnabled` and
   `ensureServerUnlocked` added (the prior wrapper skipped them).
3. `openExistingTmuxSession(named:on:)` now records the attachment
   selection via `tmuxResolver.updateAttachmentState(...)` with
   `.attachExisting(sessionName:)` so a reconnect of that tab reattaches
   to the same named session (and `paullmManaged` mode does not silently
   attach to a different managed session).

**Verification note.** Manual: open the existing-sessions picker from the
server list with no active connection — remote tmux sessions are listed;
internal `paullm_*` sessions are not (unless attached). Attach to one,
kill the app, relaunch, reconnect that tab — it reattaches to the same
named session without prompting.

## F4 — test runner crash (MEDIUM)

**Status:** No code change. Documented here per the plan.

**What I tried.** `xcodebuild test … -only-testing:paullm-sshTests/…`
on the worktree fails before tests can run with:

> `No profiles for 'app.paullm.ssh' were found: Xcode couldn't find any
> Mac App Development provisioning profiles matching 'app.paullm.ssh'.
> Automatic signing is disabled and unable to generate a profile.`

The same failure occurs on the pristine `remediation/full-ship` source
(no F1–F3 changes in place), so this is a host-environment issue and not
a regression introduced by these fixes.

The prior xcresult on this host
(`~/Library/Developer/Xcode/DerivedData/paullm-ssh-eytewynwgqiwlhaztmwtoexmxhzl/Logs/Test/Test-paullm-ssh-2026.06.11_08-44-35--0600.xcresult`)
shows the same "test runner exited with code 6 before establishing
connection" error from the runbook session, but the bundle is signed
ad-hoc (`codesign -dv` reports `Signature=adhoc`) and a previous test
binary exists at
`…/Build/Products/Debug/paullm-ssh.app/Contents/PlugIns/paullm-sshTests.xctest`
(dylib @rpath resolution now blocks `xcrun xctest` invocation). The
xcresult has no crash frame — it only contains the "Early unexpected
exit" issue summary. There is no recent `paullm-ssh-*.ips` in
`~/Library/Logs/DiagnosticReports/`.

**Static review of suspect code (KnownHostsManager).** The plan's
hypothesis (`KnownHostsManager.shared` performs Keychain access during
static init, which could SIGTRAP under `CODE_SIGNING_ALLOWED=NO`) was
investigated. `KnownHostsManager.shared` is a `static let` of a
`@unchecked Sendable` final class; first access constructs
`KeychainKnownHostsStorage()` (nonisolated init — trivial), then
`KnownHostsManager.init` which calls `storage.loadData()`. The
underlying `KeychainStore.get(...)` does Security framework calls; on
failure the wrapper's `loadData()` catches the error and returns nil.
The 84b9563 fix (`Bundle.main.bundleIdentifier ?? "app.paullm-ssh"`)
is in place; `grep -rn 'Bundle\.main\.bundleIdentifier\!' paullm-ssh
--include="*.swift"` returns no results. `KnownHostsManager` is only
referenced from runtime call sites (SSHClient, settings UI, the host-key
prompt handlers added in F1) — not at static init time — so it cannot
crash the test host on launch.

**Conclusion.** The plan's "fix the smallest possible thing" is moot:
the crash is not reproducible from source changes on this host. To
actually diagnose, the test bundle needs to be loadable on a host with
a configured developer account or with a properly-signed test host
app; on this host neither is possible. Per the plan, this is documented
here rather than guessed at.

## F5 — review deinit changes in 841d56b (LOW)

**Status:** Reviewed, no code change. Documented here per the plan.

**Finding.** Commit `841d56b` replaced the deinit's
`Task { @MainActor [self] in cancelShell() }` (which retains `self` from
a deiniting context and traps in `swift_deallocClassInstance`) with
detached tasks that capture only the values the work needs.

I diffed both new deinit blocks against their `cancelShell()`:

**`SSHTerminalCoordinator.cancelShell()` (extension, line 154):**
1. `shellTask?.cancel()` ; `shellTask = nil`
2. Detached task: `await sshClient.closeShell(shellId)`
3. `self.shellId = nil`
4. If `terminalView != nil`: `terminal.cleanup()`
5. `terminalView = nil`

**macOS `Coordinator.deinit` (line 595):**
- Guards: `!isReusingTerminal`, `terminalView == nil` (skip cleanup if
  the wrapper is being recycled or the terminal is still owned by the
  session manager).
- `shellTask?.cancel()`
- Detached task: `await sshClient.closeShell(shellId)`
- No `terminal.cleanup()` — correct, because the `terminalView == nil`
  guard already ensures the terminal is being kept alive elsewhere
  (the SwiftUI view going away while the terminal lives on in the
  session manager; the wrapper's `makeNSView` checks for an existing
  terminal and reattaches).

**iOS `Coordinator.deinit` (line 997):**
- Guard: `!preserveSession` (user navigated away, not closing).
- `shellTask?.cancel()`
- Detached task: `await sshClient.closeShell(shellId)`
- If `terminalView != nil`: a `@MainActor` Task captures only
  `terminal` and calls `cleanup()`. The `@MainActor` hop is correct
  (terminal cleanup is main-actor-isolated) and the value-only capture
  avoids the deinit retain trap.
- The `terminalView = nil` step from `cancelShell` is implicit in
  deinit.

**Verdict.** The deinit changes are functionally equivalent to
`cancelShell()` for the work that runs in deinit. The `shellTask = nil`
and `shellId = nil` and `terminalView = nil` assignments that
`cancelShell` performs are unnecessary in deinit (the object is going
away). The terminal-cleanup divergence is correct and intentional: the
macOS path's `terminalView == nil` guard is the same predicate that
`cancelShell`'s `if let terminal = terminalView` uses, just negated;
the iOS path mirrors it. The deinit is a real (if subtle) improvement
over the prior `Task { @MainActor [self] in … }` — that pattern is
the textbook Swift trap for retain-from-deinit and would have crashed
under any test or instrumented run that exercised wrapper teardown.

**Note to self / future agents.** The macOS file has a separate
extension-level `cancelShell()` and `deinit` (lines 154 / 595), and
the iOS file has its own `deinit` (line 997). The macOS extension's
`cancelShell()` is the same code the iOS extension would call if it
existed — it's the protocol-extension default. Both `deinit` blocks
are correct as written.

## Build & test results

- `xcodebuild build` and `xcodebuild test` both fail on this host with
  `No profiles for 'app.paullm.ssh' were found` before any F1–F3 change
  is compiled. The host has no configured Apple developer account
  (`xcodebuild -showBuildSettings` confirms `CODE_SIGNING_ALLOWED = YES`
  and `PROVISIONING_PROFILE_REQUIRED_YES_YES = YES`). The previous
  successful runbook session's DerivedData contains an ad-hoc-signed
  test bundle from earlier today; without an active account the
  rebuild path is blocked. The F1–F3 changes are code-reviewed and
  hand-verified against the call sites identified in the plan.

## Skipped

- F4: no crash log available, no developer account, no code change.
- F5: confirmed equivalent, no code change.
- Phase 9 from the prior `M3_REMEDIATION_PLAN.md` (de-sync keychain on
  sync toggle off): still skipped, per `M3_REMEDIATION_NOTES.md` on
  `remediation/full-ship`.

## Notes on working-tree hygiene

- Branched `remediation/review-fixes-v2` off `remediation/full-ship` in
  a separate worktree at `../paullm-ssh-review-fixes-v2`. The dirty
  working tree on the main checkout is untouched.
- Each fix is one commit. F1 spans four files (the two `onFailure`
  blocks and the two managers); F2 is one file; F3 is one file. F4
  and F5 produce no commits (documented here).
- F1's `iOSContentView.swift` host-key alert was *not* changed — the
  plan's "alert button calls nothing else" diagnosis is correct, but
  the fix lives in the manager (which the button already calls). The
  alert's `hostKeyPrompt` getter still filters by `serverSessions`;
  since the F1 fix keeps the session in `serverSessions` (it transitions
  to `.failed`, not remove), the alert continues to display after the
  user's decision.

## Branches & pushes

Nothing pushed. All commits are on the local
`remediation/review-fixes-v2` branch for human review, as the plan
required.
