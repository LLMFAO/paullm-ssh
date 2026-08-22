# Feature Plan — Composer Maturation + Deterministic Tmux Connect Flow

**Audience:** an AI coding agent (MiniMax M3) executing this plan autonomously.
**Repo:** `paullm-ssh` — iOS/macOS SSH terminal app, Swift, Xcode project at repo root.
**Companion:** `docs/M3_REMEDIATION_PLAN.md` — its **Phase 0 ground rules apply
verbatim here** (dirty working tree, never `git add .`/`-A`/`commit -a`, stage
exact paths only, atomic commits, build/test commands, locate code by symbol
not line number, skip-and-document when blocked). Read that file's Phase 0 and
`CLAUDE.md` before starting. Work on branch `feature/composer-and-tmux-flow`
off the current branch.

This plan has three independent workstreams. Execute in this order:
**C first** (smallest, one commit), then **A fully**, then **B**. Within each
workstream the phases are ordered and each phase is one commit.

**Platform scope: iOS only.** Per CLAUDE.md, iOS is the primary platform. Do
no macOS-specific UI/UX work in this plan. Shared SwiftUI changes will reach
macOS for free and the macOS target must keep compiling (the `platform=macOS`
build command in the ground rules remains the compile check), but do not add
macOS entry points, shortcuts, or parity features, and do not manually test
macOS flows.

---

# Workstream A — Local composer for slow connections

## User problem

Typing directly into the terminal on a high-latency connection echoes each
keystroke over SSH, so typing feels broken. Termius solves this with a local
input box: type/paste/dictate locally, then send the whole line at once.

## What already exists (do not rebuild)

`paullm-ssh/Features/InputBuffer/` already implements most of this:

- `Application/InputBufferManager.swift` — `@MainActor ObservableObject`
  singleton with a **single global** `draftText` persisted under one
  UserDefaults key, `isPresented` flag, `sendAndClear(via:)`, and a
  `Notification.Name.openInputBuffer`.
- `UI/InputBufferInlineComposer.swift` — full composer UI: multiline editor,
  char count, paste button, snippet menu, newline button, Clear, Send,
  optional mic button (`onVoice` closure).
- Wiring in `Features/TerminalSessions/UI/Terminal/TerminalContainerView.swift`:
  listens for `.openInputBuffer`, shows the composer as a bottom
  `safeAreaInset`, sends via
  `ConnectionSessionManager.shared.sendText(text, to: session.id)`, and the
  voice overlay's `onSendToBuffer` already appends transcription to the
  composer.
- iOS trigger: accessory-bar action `.openInputBuffer` ("Compose",
  `text.bubble` icon) — present in
  `TerminalAccessoryModels.defaultActiveItems` but **12th of 19 items**, so
  it is far off-screen in the accessory strip.

## Actual gaps (verified)

1. **macOS has no way to open the composer at all.** The only posters of
   `.openInputBuffer` are in `GhosttyTerminalView+iOS.swift`
   (`grep -rn "openInputBuffer" paullm-ssh --include="*.swift"` to confirm
   this is still true).
2. **One global draft shared by every session.** `InputBufferManager.shared`
   has a single `draftText`; open the composer in two tabs and they show and
   clobber the same text. `isPresented` is also global, so opening the
   composer in one session opens it in all visible sessions.
3. **Poor discoverability on iOS** — the entry point is buried in the
   accessory strip.

## Phase A1 — Per-session drafts and presentation

**Files:** `paullm-ssh/Features/InputBuffer/Application/InputBufferManager.swift`,
`UI/InputBufferInlineComposer.swift`,
`Features/TerminalSessions/UI/Terminal/TerminalContainerView.swift`.

1. Rework `InputBufferManager` to key state by session:
   ```swift
   @Published private(set) var drafts: [UUID: String] = [:]
   @Published private(set) var presentedSessions: Set<UUID> = []
   func draftText(for sessionId: UUID) -> String
   func setDraftText(_ text: String, for sessionId: UUID)
   func appendText(_ text: String, for sessionId: UUID)
   func isPresented(for sessionId: UUID) -> Bool
   func setPresented(_ presented: Bool, for sessionId: UUID)
   func sendAndClear(for sessionId: UUID, via sender: (String) -> Void, withNewline: Bool = true)
   func clearDraft(for sessionId: UUID)
   func removeSession(_ sessionId: UUID)   // call from session-close cleanup
   ```
   Persist drafts as one JSON-encoded `[String: String]` (UUID string → draft)
   under the key `"inputBufferDrafts"`. Migrate: if the legacy
   `"inputBufferDraft"` string key has a non-empty value, drop it into the
   first session that opens the composer is NOT acceptable (ambiguous) —
   instead discard it and delete the key; a one-line code comment may note
   drafts were reset once. Keep `Notification.Name.openInputBuffer` but add
   `object: sessionId` (UUID?) — `nil` means "the active session".
2. `InputBufferInlineComposer` gains a `let sessionId: UUID` parameter and
   reads/writes through the new per-session API. Keep the UI identical.
3. `TerminalContainerView`: pass `session.id` through; the `.openInputBuffer`
   listener only presents when the notification's `object` is `nil`-or-equal
   to `session.id` **and** this container is the foreground one (it already
   knows the selected session via `ConnectionSessionManager.shared`).
   Call `removeSession` wherever the container/session teardown happens
   (find `handleOnDisappearCleanup` / session-close paths).
4. Find every existing caller of the old API
   (`grep -rn "InputBufferManager" paullm-ssh --include="*.swift"`) — at
   minimum `TerminalContainerView` uses `appendText`/`isPresented` in the
   voice overlay (`onSendToBuffer`) — and update them.
5. **Tests:** new `paullm-sshTests/Features/InputBuffer/InputBufferManagerTests.swift`
   (inject a scratch `UserDefaults(suiteName:)`): independent drafts for two
   session IDs, persistence round-trip, sendAndClear clears only its session,
   removeSession drops the draft, legacy key is deleted on init.

**Acceptance:** build + new tests pass; two terminal tabs hold different
composer drafts.

**Commit:** `refactor(inputbuffer): per-session drafts and presentation state`

## Phase A2 — iOS discoverability

1. In `TerminalAccessoryModels.defaultActiveItems` move
   `.system(.openInputBuffer)` from its current position to **second position**
   (right after `.escape`). This only affects fresh installs/new profiles —
   existing users' saved profiles are untouched; that is acceptable.
2. Existing users: add a one-time hint. When a terminal session has been
   connected for 3 seconds and the user has never opened the composer
   (`UserDefaults` bool `"inputBuffer.hasOpenedOnce"`, set true on first
   present), show the existing notice/banner mechanism — reuse the
   `operationNotice` pattern visible in `TerminalContainerView`
   (search `operationNotice =` there for the shape) with title
   "Compose without lag", message "Tap Compose to type locally and send when
   ready.", auto-dismissing. Show it at most once ever
   (`"inputBuffer.hintShown"` bool). Keep it out of the way of existing
   notices: if another notice is active, skip silently.
3. Do NOT attempt latency detection / RTT measurement. Out of scope.

**Acceptance:** build passes; fresh-profile accessory bar shows Compose second;
hint appears once on a clean install's first session and never again.

**Commit:** `feat(inputbuffer): surface composer earlier in accessory bar with one-time hint`

---

# Workstream B — Deterministic tmux session flow

## User problem

Connecting to a host is unpredictable: sometimes the app restores and
reconnects a pile of previous tabs, sometimes it silently creates a fresh
session, sometimes a tmux prompt appears mid-connection. Desired behavior:
**after tapping a host on the main screen, show a picker of that host's tmux
sessions (and other options) and connect to exactly what the user chooses.**

## How it works today (verified — reconfirm each point before changing it)

- App launch: `ConnectionSessionManager.restoreSnapshot()` recreates all
  previously open tabs as `.disconnected` `ConnectionSession`s (see
  `SessionSnapshot.toSession()`), with `autoReconnect` persisted per tab.
- Tapping a server on iOS (`onServerSelected` in `iOSContentView.swift` ~line
  47) navigates **straight** into the terminal area: if restored tabs exist it
  selects one and the terminal views start appearing, each triggering its own
  reconnect (`attemptAutoReconnectIfNeeded`, reconnect tokens); if none exist,
  a connect flow starts elsewhere. The user never gets a choice.
- tmux attach choice is resolved *per tab, mid-connection* by
  `TmuxAttachResolver.resolveSelection(...)` based on
  `TmuxStartupBehavior` (`paullmManaged` / `askEveryTime` / `skipTmux`,
  global default + per-server override `server.tmuxStartupBehaviorOverride`).
  With `askEveryTime` and several restored tabs, prompts **queue up** one
  after another (`promptQueue` in `TmuxAttachResolver`) — this is the
  "reconnect to all sessions" mess.
- A good picker UI already exists:
  `Features/TerminalSessions/UI/NewSession/NewTerminalSessionPicker.swift`
  (existing remote tmux sessions with attached-client/window/path details,
  AI-CLI session types, custom command). It is currently used for the
  **new-tab "+"** flow on both platforms (`iOSContentView.swift` ~line 1109,
  `ConnectionTabsView.swift` ~line 236) — and helper functions
  `attachOrFocusExistingTmuxSession`, `createNewTerminalSession`,
  `loadedTmuxSessionNames`, `refreshRemoteTmuxSessions` already exist in
  `iOSContentView`.
- `ConnectionSessionManager.remoteTmuxSessions(for:)` (~line 311) can list a
  server's tmux sessions, creating a throwaway SSH connection if none is
  active. `openExistingTmuxSession(named:on:)` (~line 297) opens a tab
  attached to a named session.

So Workstream B is mostly **rerouting the host-tap entry point through the
existing picker** and **stopping the restored-tab reconnect storm** — not new
machinery.

## Phase B1 — Domain: host-connect behavior + decision logic

1. New file `paullm-ssh/Features/TerminalSessions/Domain/HostConnectFlow.swift`:
   ```swift
   enum HostConnectBehavior: String, Codable, CaseIterable, Identifiable {
       case askEveryTime      // default: show the session picker on host tap
       case restorePrevious   // old behavior: jump into restored tabs / first session
       case alwaysNew         // skip picker, open a fresh default session
   }

   enum HostConnectDecision: Equatable {
       case showPicker
       case enterExistingTabs(selectedSessionId: UUID?)
       case openNewDefaultSession
   }

   struct HostConnectResolver {
       static func decide(
           behavior: HostConnectBehavior,
           hasOpenTabs: Bool,            // any ConnectionSession for this server, connected or restored
           preferredSessionId: UUID?     // selectedSessionByServer value if still alive
       ) -> HostConnectDecision
   }
   ```
   Rules: `askEveryTime` → always `.showPicker`. `restorePrevious` →
   `.enterExistingTabs` when `hasOpenTabs`, else `.openNewDefaultSession`.
   `alwaysNew` → `.openNewDefaultSession`. Pure function, no singletons.
2. Persistence: global default in UserDefaults key
   `"terminalHostConnectBehaviorDefault"` (default `.askEveryTime`) read the
   same way `TmuxAttachResolver.tmuxStartupBehaviorDefault` reads its key.
   Per-server override: add `var hostConnectBehaviorOverride: HostConnectBehavior?`
   to `Server` ONLY IF adding a Codable optional field is proven
   backward-compatible with existing persisted/CloudKit data — check how
   `tmuxStartupBehaviorOverride` was added to `Server` and its CloudKit
   record mapping in `Core/Sync`/`ServerManager`, and mirror it exactly. If
   that mapping is entangled with uncommitted in-flight work, skip the
   per-server override (global only) and document it.
3. Settings UI: add a picker for the default under the existing tmux startup
   behavior control — find where `TmuxStartupBehavior` is offered in
   `Features/Settings/UI/TerminalSettingsView.swift` and add "When opening a
   host" alongside, same style. If a per-server override landed in step 2,
   mirror the per-server tmux override UI in `ServerFormSheet.swift`.
4. **Tests:** `paullm-sshTests/Features/TerminalSessions/HostConnectResolverTests.swift`
   covering the full behavior × state matrix (at least 6 cases).

**Commit:** `feat(sessions): host-connect behavior setting and decision domain`

## Phase B2 — iOS: route host tap through the picker

**File:** `paullm-ssh/App/iOS/iOSContentView.swift`.

1. In `onServerSelected` (~line 47): instead of unconditionally setting
   `showingTerminal = true`, call `HostConnectResolver.decide(...)`:
   - `.enterExistingTabs` → current behavior, unchanged code path.
   - `.openNewDefaultSession` → existing default-connect path (whatever runs
     today when there are no sessions — trace it before touching it).
   - `.showPicker` → set `selectedServer`, call `refreshRemoteTmuxSessions()`
     (already exists), and present `NewTerminalSessionPicker` as a sheet
     **without navigating to the terminal yet**. Reuse the exact sheet wiring
     at ~line 1109 — extract it into a helper so the "+" flow and the host-tap
     flow share one implementation. Navigation to the terminal happens only
     after the picker callbacks fire (they already do this via
     `createNewTerminalSession` / `attachOrFocusExistingTmuxSession`).
2. Extend the picker content for the host-tap context with an **"Open tabs"
   section at the top**: the server's existing `ConnectionSession`s
   (restored/disconnected and connected), each row showing title +
   connection state, tapping = select that tab and navigate (the
   `.enterExistingTabs` path for one session). Add this as an optional
   parameter (`openTabs: [ConnectionSession]`, default `[]`) on
   `NewTerminalSessionPicker` so the "+" flow is unaffected. Remote tmux
   sessions that are already loaded as tabs must not appear twice —
   `loadedTmuxSessionNames(for:)` already exists for exactly this.
3. The picker must appear instantly with a loading row while
   `remoteTmuxSessions(for:)` resolves (it may dial a throwaway SSH
   connection). Check how the existing "+" flow handles the async refresh
   (`refreshRemoteTmuxSessions` + `remoteTmuxSessionsByServer`) and reuse it;
   do not add a new loading mechanism. A "Skip — connect without tmux" row
   must exist (maps to the picker's existing plain-shell/new-session option).
4. Cancel dismisses the sheet and stays on the server list, with no
   connection attempt left running (verify the throwaway listing client is
   disconnected — `remoteTmuxSessions(for:)` already disconnects in both
   paths; just don't introduce a leak).

**Acceptance:** build passes. With default settings, tapping a host always
shows the picker listing remote tmux sessions + open tabs + new-session
options; choosing connects to exactly that; cancel connects to nothing.
Setting behavior to `restorePrevious` restores today's behavior exactly.

**Commit:** `feat(sessions/iOS): session picker on host tap`

## Phase B3 — Stop the restored-tab reconnect storm

**Goal:** restored (snapshot) tabs must not reconnect en masse; a tab
reconnects only when the user selects it (or chose it in the picker).

1. Audit first, then change: trace how a restored `.disconnected` session with
   `autoReconnect == true` comes back to life — start at
   `attemptAutoReconnectIfNeeded` (`TerminalContainerView`), the
   `reconnectTokenBySession` map and `shouldShowTerminalBySession` gating in
   `iOSContentView`, and `ConnectionSessionManager.reconnect(session:)`
   (~line 965). Write down (in the notes file) which views instantiate
   terminal wrappers for non-selected tabs.
2. Enforce one rule: **only the currently selected session of the currently
   viewed server may auto-(re)connect.** Non-selected restored tabs stay
   `.disconnected` and show their existing disconnected UI until selected.
   Implement at the narrowest point the audit found (likely the
   `shouldShowTerminalBySession`/`prepareTerminal` gating plus an
   `attemptAutoReconnectIfNeeded` guard on
   `ConnectionSessionManager.shared.selectedSessionId == session.id`).
   Do not change snapshot/restore encoding.
3. tmux prompt queue: with B2 + this phase, mid-connection `askEveryTime`
   prompts should become rare (the choice was already made in the picker).
   When a session was opened from the picker, its attach selection is already
   recorded (`openExistingTmuxSession` calls
   `tmuxResolver.updateAttachmentState`), so `resolveSelection` short-circuits
   on reconnect — verify with a log statement during manual testing, then
   remove the log. Do not redesign `TmuxAttachResolver`.
4. **Tests:** extend `paullm-sshTests/Features/TerminalSessions/ConnectionSessionDomainTests.swift`
   (or a new file matching its style) with any pure logic you extracted for
   the "may this session auto-reconnect?" decision — make that decision a
   pure function so it is testable:
   `static func shouldAutoReconnect(session:isSelected:isServerViewed:) -> Bool`.

**Acceptance:** build + tests pass. Manual scenario (document the steps you
used in the notes file): open 3 tabs on a host → kill app → relaunch → tap
host → picker appears; choose one tab → only that tab reconnects; the other
two stay disconnected until tapped.

**Commit:** `fix(sessions): reconnect only the selected restored tab`

---

# Workstream C — Correct About/Support contact info

## User problem

The About and Support screens still show the upstream project's contacts
(this codebase forked from wiedymi/VivyTerm): an X link to `@wiedymi`, a
"follow" link to `x.com/vivytech`, the upstream Discord invite, a literally
broken email link `mailto:support.dev`, and `paullm.dev` URLs. They must
reflect the current owner: **paullm.com** and **me@pauljpettit.com**.

## Phase C1 — Replace contact and link info

**Files (verified locations):**
- `paullm-ssh/Features/Settings/UI/AboutSettingsView.swift` (~lines 27–29,
  110, 128, 134, 189)
- `paullm-ssh/Features/Settings/UI/AboutView.swift` (~lines 89, 110, 117)
- `paullm-ssh/Features/Support/UI/SupportSheet.swift` (two `ContactOption`
  arrays, ~lines 25–28 and 157–160, plus ~lines 113 and 211)
- `paullm-ssh/Features/Settings/UI/ProSettingsView.swift` (find its
  `paullm.dev` links)

**Replacements (apply consistently in all files above):**

| Current | Replace with |
|---|---|
| `https://paullm.dev` | `https://paullm.com` |
| `https://paullm.dev/privacy` | `https://paullm.com/privacy` |
| `https://paullm.dev/terms` | `https://paullm.com/terms` |
| `mailto:support.dev` + subtitle `support.dev` | `mailto:me@pauljpettit.com` + subtitle `me@pauljpettit.com` |
| Developer row: `@wiedymi` / `https://x.com/wiedymi` | title "Developer", subtitle `paullm.com`, globe icon (`safari` SF Symbol or the row's existing icon style), url `https://paullm.com` |
| Discord row (`discord.gg/zemMZtrkSb`) | delete the row (upstream community) |
| `https://x.com/vivytech` follow links/buttons (~AboutSettingsView 189, SupportSheet 113 & 211) | delete the button/link and any now-dead supporting layout |

**Rules:**
1. Do NOT touch `paullm-ssh/Core/Security/DeviceIdentity.swift` — its
   `paullm.dev` string is an identifier, not display text; changing it can
   break device identity.
2. GitHub links (`github.com/LLMFAO/paullm-ssh`) are correct (matches
   `git remote -v`) — leave them.
3. After editing, sweep for leftovers:
   `grep -rn "wiedymi\|vivytech\|support\.dev\|discord.gg\|paullm\.dev" paullm-ssh --include="*.swift"`
   — the only remaining hit must be `DeviceIdentity.swift`. Also check
   `paullm-ssh/Resources/en.lproj/Localizable.strings` for any of those
   strings and fix the en strings only.
4. The `SupportSheet` has duplicated `ContactOption` arrays (iOS/macOS
   variants) — update every copy.

**Acceptance:** build passes; the grep sweep is clean; About and Support show
paullm.com / me@pauljpettit.com on both platforms.

**Commit:** `fix(about): replace upstream contact info with paullm.com / me@pauljpettit.com`

---

## Explicitly OUT of scope (all workstreams)

- Latency/RTT detection, predictive echo, or any "smart" composer triggering.
- Redesigning `TmuxAttachResolver`, the prompt queue, or snapshot encoding.
- Changing managed tmux session naming (`paullm_<device>_<uuid>`), cleanup
  logic, or `RemoteTmuxManager` commands.
- CloudKit schema changes beyond mirroring the existing
  `tmuxStartupBehaviorOverride` pattern (and only if it's clean — see B1.2).
- Touching the uncommitted Toolkit/web/marketing work on the branch.
- Any UI redesign beyond the specific additions named above.

## Final deliverable

Append to (or create) `docs/M3_REMEDIATION_NOTES.md`: commits made (hash +
message), test results, the B3 audit notes, manual-test steps performed, and
any skipped items with reasons. Do not push; leave the branch local for human
review.
