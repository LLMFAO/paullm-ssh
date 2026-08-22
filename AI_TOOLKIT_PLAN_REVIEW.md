# AI Toolkit Plan Review

Review date: 2026-05-31

Scope: review of the expanded tmux-backed AI/general session and Vibe Toolkit work against the original plan.

## Summary

The expanded direction is good: the work separates the Toolkit into its own feature area, keeps remote actions tmux-oriented, adds catalog metadata, and starts covering AI CLI install/setup flows with tests.

The main problems are not conceptual. They are implementation alignment issues:

- Toolkit actions appear to create their own tmux sessions even though the app already wraps custom startups in tmux.
- Installer metadata differs between the normal AI session startup repair flow and the Toolkit catalog.
- Setup commands are inconsistent between flows.
- The current test expectations conflict with the new sudo guidance.
- Confirmation/status behavior needs tightening before the feature feels safe and predictable.

## Findings

### P1: Toolkit actions will likely create nested tmux sessions

File: `paullm-ssh/Features/Toolkit/Infrastructure/RemoteToolkitRunner.swift`

Relevant lines:

- `makeRunScript` creates and attaches a tmux session internally around lines 54-56.
- `makeRunStartup` then returns `TerminalSessionStartup.custom(...)` around lines 82-86.

Why this matters:

`TerminalSessionStartup.custom(...)` is already opened through the app's normal terminal session flow, which uses the app-managed tmux startup path. The Toolkit runner then creates another tmux session inside that tmux-backed startup. That can lead to nested tmux behavior, attach failures, or confusing terminal state.

Expected direction:

The Toolkit runner should write and run the temp script, then rely on the existing app session startup path to own tmux. If the runner needs to own tmux for some reason, the outer startup flow needs an explicit way to skip tmux wrapping.

## P1: Tests now contradict the sudo guidance change

File: `paullm-sshTests/TerminalSessionStartupTests.swift`

Relevant lines:

- Lines 338-341 assert that the generated AI startup commands do not contain `"sudo"`.

File: `paullm-ssh/Core/SSH/RemoteTerminalBootstrap.swift`

Relevant lines:

- Lines 337-340 intentionally print guidance mentioning sudo when npm permission errors happen.

Why this matters:

The product behavior changed to guide users when they hit sudo/permission errors, but the test still asserts that the generated command text contains no `sudo` at all. Once the test runner actually boots, this test should fail.

Expected direction:

Update the test to assert that the install path does not execute sudo, while allowing user-facing guidance text that mentions sudo. For example, assert no `sudo npm`, `sudo bash`, or `sudo curl`, instead of banning the word globally.

## P2: Installer metadata is inconsistent between startup repair and Toolkit

File: `paullm-ssh/Core/SSH/RemoteTerminalBootstrap.swift`

Relevant lines:

- OpenCode startup repair uses npm package `opencode-ai` around line 307.
- Antigravity startup repair uses `https://antigravity.google/cli/install.sh` around line 314.

File: `paullm-ssh/Features/Toolkit/Domain/ToolkitCatalog.swift`

Relevant lines:

- OpenCode Toolkit install uses `@opencode-ai/opencode` around line 97.
- Antigravity Toolkit install uses `https://install.antigravity.ai | bash` around line 119.

Why this matters:

The app should not teach two installation sources for the same tool. Even if one path is currently correct, this needs one shared source of truth or a deliberate explanation for why the flows differ.

Expected direction:

Reconcile installer metadata between `RemoteTerminalBootstrap.CLIInstaller` and `ToolkitCatalog`. Ideally, use a shared definition for supported AI CLIs so launch, install, verify, setup, and uninstall all agree.

## P2: Setup commands are weaker in Toolkit than in startup repair

File: `paullm-ssh/Core/SSH/RemoteTerminalBootstrap.swift`

Relevant lines:

- Claude setup uses `claude auth login` around line 294.
- Codex setup uses `codex login --device-auth` around line 301.
- OpenCode setup uses `opencode auth login` around line 308.

File: `paullm-ssh/Features/Toolkit/Domain/ToolkitCatalog.swift`

Relevant lines:

- Claude Toolkit setup uses bare `claude` around line 55.
- Codex Toolkit setup uses bare `codex` around line 77.
- OpenCode Toolkit setup uses bare `opencode` around line 99.

Why this matters:

The original plan wanted the app to help configure CLIs in a secure way, while letting users handle auth in the CLI itself. The startup repair flow is closer to that. The Toolkit flow is less explicit and may simply relaunch the CLI instead of guiding the user into setup/auth.

Expected direction:

Use explicit setup/auth commands where they are known, and make the UI clear that credentials remain owned by the external CLI.

## P2: Confirmation behavior is too broad for risky entries and too light for normal entries

File: `paullm-ssh/Features/Toolkit/UI/ToolkitEntryDetailView.swift`

Relevant lines:

- `maybeConfirm(phase:)` computes risk from the entry around lines 201-209.

Why this matters:

The confirmation is based on the entry's install script, not necessarily the selected phase. A curl-pipe installer can trigger an install-style confirmation even when the user taps verify/setup, while low/medium commands can run immediately.

The original plan emphasized inspectable, explicit command execution. The current UI shows script text, which is good, but the final confirmation behavior is uneven.

Expected direction:

Confirm the exact phase command that is about to run. For high-risk commands, include the exact command in the confirmation. For low-risk commands, a lighter confirmation may be fine, but the user should still understand when a remote command is about to execute.

## P3: Toolkit status detection only works with an already-active SSH client

File: `paullm-ssh/Features/Toolkit/Application/ToolkitManager.swift`

Relevant lines:

- `refreshStatus()` returns "No active connection to server" when there is no active client around lines 44-46.

Why this matters:

Clicking an existing server should show useful AI/toolkit state. If detection only works when another terminal/stats SSH client already exists, the Toolkit screen may show unknown or error state even though the app has enough saved server metadata to initiate a check.

Expected direction:

Either create a temporary SSH client for status detection using the same credential path as other server actions, or make the UI clearly require an active connection before detection.

## Verification

Commands run:

```sh
git diff --check
xcodebuild build -project paullm-ssh.xcodeproj -scheme paullm-ssh -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project paullm-ssh.xcodeproj -scheme paullm-ssh -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -only-testing:paullm-sshTests/ToolkitCatalogTests -only-testing:paullm-sshTests/ToolkitTrustWarningTests -only-testing:paullm-sshTests/TerminalSessionStartupTests
```

Results:

- `git diff --check` passed.
- macOS app build passed.
- Focused tests did not complete because the macOS test runner exited before bootstrapping with exit 65. The observed failure was infrastructure/bootstrap, not a test assertion result.

Important note:

Even though tests did not reach assertions, the sudo-string test appears stale by inspection and should be updated before relying on a future green run.

## Recommended Next Steps

1. Remove internal tmux creation from `RemoteToolkitRunner`, or explicitly prevent double wrapping.
2. Centralize AI CLI install/setup metadata so startup repair and Toolkit agree.
3. Update setup commands in Toolkit to match the more explicit startup repair setup flow.
4. Fix the sudo guidance test to distinguish "does not run sudo" from "does not mention sudo."
5. Make Toolkit command confirmation phase-specific.
6. Decide whether Toolkit status detection should open its own temporary SSH client or require an active connection with clearer UI.

## Resolution (2026-05-31, follow-up session)

**Design decision taken: the Toolkit is the single install mechanism.** The inline
launch-path installer (`RemoteTerminalBootstrap.configuredCLIStartupScript` +
`CLIInstaller` + `firstExecutable`) was confirmed to be **dead code** — defined and
unit-tested but never called from any launch path (`createSessionCommand` →
`loginShellCommand` runs the bare CLI and drops to a shell if missing). It was removed
rather than reconciled. This dissolves the "two installation sources" problem (P2) by
deletion: `ToolkitCatalog` is now the only source of truth. (`loginEnvironmentImportScript`
was left in place — it has its own passing test and was out of scope.)

Status of each item:

1. **Done.** `RemoteToolkitRunner.makeRunScript` no longer creates a tmux session. It
   writes a user-owned temp script, runs it, then `exec`s an interactive login shell so
   output stays inspectable. The app's `tmuxStartupPlan` owns tmux for the `.custom`
   startup, so there is no longer any nesting.
2. **Done (by deletion).** Inline `CLIInstaller` removed; catalog is the sole source.
   While reconciling, the catalog's divergent values were corrected to the
   previously-shipped (vetted) forms: OpenCode npm package `@opencode-ai/opencode` →
   `opencode-ai` (install + uninstall); Antigravity installer `https://install.antigravity.ai`
   → `https://antigravity.google/cli/install.sh`.
3. **Done.** Toolkit `setupScript`s are now explicit auth commands: Claude
   `claude auth login`, Codex `codex login --device-auth`, OpenCode `opencode auth login`
   (Antigravity stays `agy`).
4. **Superseded.** The two working-tree tests it referenced
   (`recognizedAIStartupCommandsInstallMissingCLIsWithoutSudo`,
   `recognizedAIStartupCommandsOfferSetupAfterFastFailure`) asserted installer/auth text
   in `attachCommand` output that the current launch path **never produces** — they were
   wholly stale, not just on the `sudo` line, and were removed. A third stale test was
   also caught and fixed: `tmuxStartupCommandRunsInitialCommandThroughLoginShell` asserted
   `-ic` (interactive) but the launch path deliberately uses `-lc` (non-interactive login);
   the assertion was corrected to `-lc` / `!-ic`.
5. **Done.** `ToolkitEntryDetailView.maybeConfirm` now keys risk and the confirmation
   off the *exact phase command* about to run (not always the install script), and the
   single confirmation alert shows that exact command. Low/medium phases run directly
   after the explicit action-button tap; curl-pipe, sudo, or high-risk phases confirm.
6. **Done (clearer UI).** `ToolkitManager` exposes `requiresConnection`; `ToolkitScreen`
   shows a "Connect to detect status" banner when no terminal/stats SSH client is active,
   instead of leaving entries in an unexplained "unknown" state. (Opening a temporary SSH
   client for detection was deferred as the heavier option.)

**Verification:** full macOS app build passes (`xcodebuild build … platform=macOS`), and
`build-for-testing` passes (test target type-checks, no dangling refs after the deletions).
The macOS/iOS-Simulator **test runner still crashes with SIGTRAP before bootstrapping** —
a pre-existing host-startup issue (also seen in the original review as exit 65), unrelated
to these changes, so assertions could not be executed in this environment.

