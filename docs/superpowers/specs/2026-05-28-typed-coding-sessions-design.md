# Typed Coding Sessions Design

## Problem

New terminal sessions are currently generic. Users who run agentic coding CLIs need to distinguish several live sessions per host and often start each session with a known command. Custom Actions already exist, but they are buried under Terminal keyboard accessory settings and are not tied to session creation.

## Goals

- Let users choose a session type when starting a new terminal session.
- Support at least Claude CLI, Antigravity CLI, Codex CLI, OpenCode CLI, and generic TMUX sessions.
- Allow multiple sessions of the same type on one host.
- Show existing sessions with their session type icon and label when the app knows how they were created.
- Show unknown or externally-created tmux sessions as generic "TMUX Session" with an Ubuntu-style fallback mark.
- Use Custom Actions as the editable source of startup commands.
- Move Custom Actions to a top-level Settings section.
- Seed default Custom Actions for the discussed startup tools.

## Non-Goals

- Do not add CloudKit sync for live terminal sessions. Sessions remain local.
- Do not require users to configure Cloudflare or any server-side service for this feature.
- Do not redesign the terminal screen.
- Do not make startup commands mandatory. Generic tmux sessions must still work.

## Startup Action Defaults

The app should seed these Custom Actions idempotently:

| Type | Title | Base command | Permission bypass command |
| --- | --- | --- | --- |
| Claude CLI | Claude CLI | `claude` | `claude --dangerously-skip-permissions` |
| Antigravity CLI | Antigravity CLI | `agy` | `agy --dangerously-skip-permissions` |
| Codex CLI | Codex CLI | `codex` | `codex --yolo` |
| OpenCode CLI | OpenCode CLI | `opencode` | none for first version |

The Antigravity command is based on Google's CLI docs, which use `agy` as the command. The permission bypass flag is documented in Antigravity CLI settings and command examples.

## UX Shape

Starting a new terminal session opens a picker. The picker shows:

- Generic TMUX Session.
- Claude CLI.
- Antigravity CLI.
- Codex CLI.
- OpenCode CLI.

Each typed CLI option uses the matching Custom Action. If the user edited the Custom Action command, the picker uses the edited command. For tools with a permission bypass command, the picker shows a checkbox. When selected, the app runs the bypass command instead of the base command.

Session rows, tabs, and attach prompts should display:

- icon
- type label
- user-visible session title
- connection state where currently shown

Unknown remote tmux sessions should not be misclassified. They display as:

- title: existing remote tmux session name where available
- type: TMUX Session
- icon: Ubuntu fallback mark

## Data Model

Add a local-only startup metadata model:

```swift
enum TerminalSessionKind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case tmux
    case claude
    case antigravity
    case codex
    case opencode

    var id: String { rawValue }
}

struct TerminalSessionStartup: Codable, Equatable, Hashable, Sendable {
    var kind: TerminalSessionKind
    var actionID: UUID?
    var displayTitle: String
    var iconSystemName: String
    var command: String?
    var bypassPermissions: Bool
}
```

The command stored on a session is a snapshot. This makes existing sessions stable even if the user later edits a Custom Action.

## Custom Action Ownership

Custom Actions stay owned by `Features/TerminalAccessories`. Startup action definitions can live in `Features/TerminalSessions/Domain` only if they are pure session metadata. The actual action records should still be `TerminalAccessoryCustomAction` values.

Use a pure profile merge helper so seeding is testable without CloudKit:

```swift
extension TerminalAccessoryProfile {
    func ensuringDefaultStartupActions(now: Date) -> TerminalAccessoryProfile
}
```

Rules:

- Add missing startup actions by stable UUID.
- Do not overwrite existing active actions.
- Do not resurrect deleted actions unless a future explicit reset flow is added.
- Do not automatically add startup actions to the keyboard accessory toolbar layout.

## Settings

Add `Custom Actions` as a peer of General, Terminal, Transcription, SSH Keys, Sync, and About.

Keep Terminal settings focused on terminal behavior and keyboard accessory settings. Remove the nested "Manage Custom Actions" link from Terminal settings.

## Execution

Startup command plumbing already exists:

- `RemoteEnvironmentResolver.launchPlan(startupCommand:)`
- `RemoteTerminalBootstrap.launchPlan(startupCommand:environment:)`
- `SSHClient.startShell(cols:rows:startupCommand:)`
- `SSHTerminalWrapper` uses a `startupPlan` closure

The feature should wire selected session metadata into that existing path rather than creating a second command execution path.

## Compatibility

Existing local sessions and tabs decode with `startup == nil` and render as generic TMUX sessions. Existing server and workspace records are unchanged.

## Risks

- Running bypass flags has security implications. The UI must make the checkbox explicit and default it off.
- Reconnect behavior must avoid creating duplicate CLI processes for an already-running tmux session.
- Stable action IDs must avoid collisions with user-created actions.
