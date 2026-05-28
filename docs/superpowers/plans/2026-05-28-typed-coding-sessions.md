# Typed Coding Sessions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add typed terminal sessions for Claude CLI, Antigravity CLI, Codex CLI, OpenCode CLI, and generic TMUX sessions, backed by editable Custom Actions and visible session badges.

**Architecture:** Keep session typing in `Features/TerminalSessions`, keep Custom Action storage and editing in `Features/TerminalAccessories`, and wire startup commands through the existing SSH startup command path. Existing sessions decode as generic tmux.

**Tech Stack:** Swift, SwiftUI, Swift Testing, Xcode project `paullm-ssh.xcodeproj`, existing libssh2/Ghostty terminal stack.

---

## File Structure

Files to create:

- `paullm-ssh/Features/TerminalSessions/Domain/TerminalSessionStartup.swift`
- `paullm-ssh/Features/TerminalSessions/UI/NewSession/NewTerminalSessionPicker.swift`
- `paullm-ssh/Features/TerminalSessions/UI/NewSession/TerminalSessionKindBadge.swift`
- `paullm-sshTests/TerminalSessionStartupTests.swift`

Files to modify:

- `paullm-ssh/Features/TerminalAccessories/Domain/TerminalAccessoryModels.swift`
- `paullm-ssh/Features/TerminalAccessories/Application/TerminalAccessoryPreferencesManager.swift`
- `paullm-ssh/Features/Settings/UI/SettingsView.swift`
- `paullm-ssh/Features/Settings/UI/TerminalSettingsView.swift`
- `paullm-ssh/Features/TerminalSessions/Domain/ConnectionSession.swift`
- `paullm-ssh/Features/TerminalSessions/Domain/TerminalTab.swift`
- `paullm-ssh/Features/TerminalSessions/Application/ConnectionSessionManager.swift`
- `paullm-ssh/Features/TerminalSessions/Application/TerminalTabManager.swift`
- `paullm-ssh/Features/TerminalSessions/UI/Terminal/SSHTerminalWrapper.swift`
- `paullm-ssh/Features/TerminalSessions/UI/Tabs/ConnectionTabsView.swift`
- `paullm-ssh/Features/TerminalSessions/UI/Tabs/ConnectionTabComponents.swift`
- `paullm-ssh/Features/TerminalSessions/UI/TmuxAttachPromptSheet.swift`
- `paullm-ssh/App/iOS/iOSContentView.swift`
- `paullm-ssh.xcodeproj/project.pbxproj`

---

## Phase 1: Add Session Startup Domain

- [ ] Create `TerminalSessionStartup.swift`.

Core model:

```swift
import Foundation

enum TerminalSessionKind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case tmux
    case claude
    case antigravity
    case codex
    case opencode

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tmux: "TMUX Session"
        case .claude: "Claude CLI"
        case .antigravity: "Antigravity CLI"
        case .codex: "Codex CLI"
        case .opencode: "OpenCode CLI"
        }
    }

    var iconSystemName: String {
        switch self {
        case .tmux: "terminal"
        case .claude: "sparkles"
        case .antigravity: "atom"
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .opencode: "curlybraces"
        }
    }
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

- [ ] Add stable startup action definitions in the same file.

Use stable UUIDs and keep the command definitions in one place:

```swift
struct TerminalStartupActionDefinition: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: TerminalSessionKind
    let title: String
    let baseCommand: String
    let bypassPermissionsCommand: String?

    func command(bypassPermissions: Bool) -> String {
        if bypassPermissions, let bypassPermissionsCommand {
            return bypassPermissionsCommand
        }
        return baseCommand
    }
}

enum TerminalSessionStartupDefaults {
    static let definitions: [TerminalStartupActionDefinition] = [
        .init(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            kind: .claude,
            title: "Claude CLI",
            baseCommand: "claude",
            bypassPermissionsCommand: "claude --dangerously-skip-permissions"
        ),
        .init(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            kind: .antigravity,
            title: "Antigravity CLI",
            baseCommand: "agy",
            bypassPermissionsCommand: "agy --dangerously-skip-permissions"
        ),
        .init(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
            kind: .codex,
            title: "Codex CLI",
            baseCommand: "codex",
            bypassPermissionsCommand: "codex --yolo"
        ),
        .init(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
            kind: .opencode,
            title: "OpenCode CLI",
            baseCommand: "opencode",
            bypassPermissionsCommand: nil
        )
    ]
}
```

- [ ] Add pure helpers to build startup snapshots from a definition and Custom Action.

Expected helper shape:

```swift
extension TerminalSessionStartupDefaults {
    static func tmuxStartup() -> TerminalSessionStartup {
        TerminalSessionStartup(
            kind: .tmux,
            actionID: nil,
            displayTitle: TerminalSessionKind.tmux.displayName,
            iconSystemName: TerminalSessionKind.tmux.iconSystemName,
            command: nil,
            bypassPermissions: false
        )
    }

    static func startup(
        for definition: TerminalStartupActionDefinition,
        actionCommand: String?,
        bypassPermissions: Bool
    ) -> TerminalSessionStartup {
        let command = bypassPermissions
            ? definition.command(bypassPermissions: true)
            : (actionCommand?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? definition.baseCommand)

        return TerminalSessionStartup(
            kind: definition.kind,
            actionID: definition.id,
            displayTitle: definition.title,
            iconSystemName: definition.kind.iconSystemName,
            command: command,
            bypassPermissions: bypassPermissions
        )
    }
}
```

- [ ] If no local `nilIfEmpty` helper exists, use a private helper in this file instead of adding a global extension.

---

## Phase 2: Seed Default Custom Actions

- [ ] Add a pure merge helper to `TerminalAccessoryModels.swift`.

The helper should add missing startup actions without touching user-edited records:

```swift
extension TerminalAccessoryProfile {
    func ensuringDefaultStartupActions(now: Date = Date()) -> TerminalAccessoryProfile {
        var profile = self
        var actionsByID = Dictionary(uniqueKeysWithValues: profile.customActions.map { ($0.id, $0) })

        for definition in TerminalSessionStartupDefaults.definitions {
            guard actionsByID[definition.id] == nil else { continue }
            profile.customActions.append(
                TerminalAccessoryCustomAction(
                    id: definition.id,
                    title: definition.title,
                    kind: .command,
                    commandContent: definition.baseCommand,
                    commandSendMode: .insertAndEnter,
                    shortcutModifiers: [],
                    shortcutKey: "",
                    createdAt: now,
                    updatedAt: now,
                    deletedAt: nil
                )
            )
            actionsByID[definition.id] = profile.customActions.last
        }

        return profile
    }
}
```

- [ ] Preserve deleted actions by ID.

If `TerminalAccessoryProfile.customActions` retains soft-deleted actions, the `actionsByID` guard above is enough. If deleted actions are filtered before this helper is called, call the helper before filtering.

- [ ] Update `TerminalAccessoryPreferencesManager.init` load path to seed once.

Expected pattern:

```swift
self.profile = loadedProfile.ensuringDefaultStartupActions()
```

Then persist the profile if seeding changed it so the defaults are available offline and visible in the Custom Actions library.

- [ ] Do not add these actions to `activeLayout.items`.

They should be available in the library and picker, not forced into the terminal accessory toolbar.

- [ ] Add tests in `TerminalSessionStartupTests.swift`.

Test cases:

- default definitions include Claude, Antigravity, Codex, and OpenCode
- profile seeding adds exactly four startup actions to a fresh profile
- profile seeding is idempotent
- user-edited command content is preserved
- deleted startup action is not duplicated

---

## Phase 3: Promote Custom Actions In Settings

- [ ] Modify `SettingsView.swift`.

Add the new selection:

```swift
enum SettingsSelection: Hashable {
    case general
    case terminal
    case customActions
    case transcription
    case keychain
    case sync
    case about
}
```

Add a sidebar row:

```swift
SettingsSidebarRow(
    selection: .customActions,
    systemImage: "command.square",
    title: "Custom Actions"
)
```

Add the detail view:

```swift
case .customActions:
    TerminalCustomActionLibraryView()
```

- [ ] Mirror the same row in the iOS settings list.

- [ ] Modify `TerminalSettingsView.swift`.

Remove the nested `NavigationLink` to `TerminalCustomActionLibraryView()` from the keyboard accessory section. Keep the keyboard accessory customization link and update the footer so it only describes toolbar customization.

---

## Phase 4: Persist Startup Metadata On Sessions And Tabs

- [ ] Modify `ConnectionSession.swift`.

Add:

```swift
var startup: TerminalSessionStartup?
```

Update initializer defaults:

```swift
startup: TerminalSessionStartup? = nil
```

- [ ] Modify `TerminalTab.swift`.

Add `startup` to `TerminalTab`:

```swift
var startup: TerminalSessionStartup?
```

Add `startup` to `TerminalPaneState` if panes can start independent shells:

```swift
var startup: TerminalSessionStartup?
```

Root panes should inherit the tab startup. Split panes should default to `nil` unless the split flow later gains its own picker.

- [ ] Update snapshot Codable structs.

Where session/tab snapshots encode/decode local state, use `decodeIfPresent`:

```swift
self.startup = try container.decodeIfPresent(TerminalSessionStartup.self, forKey: .startup)
```

Existing records must continue to load as `startup == nil`.

- [ ] Update Equatable/Hashable expectations if compiler errors surface.

---

## Phase 5: Add New Session Picker UI

- [ ] Create `NewTerminalSessionPicker.swift`.

Recommended API:

```swift
struct NewTerminalSessionPicker: View {
    let customActions: [TerminalAccessoryCustomAction]
    let onCancel: () -> Void
    let onCreate: (TerminalSessionStartup) -> Void

    @State private var selectedDefinitionID: UUID?
    @State private var bypassPermissions = false
}
```

- [ ] Render generic TMUX plus default startup definitions.

Each row should show:

- icon
- title
- command preview
- selection state

For generic tmux, command preview should be "Attach or create tmux session" or omitted if the existing design is denser.

- [ ] Add a permission bypass checkbox only for definitions that have a bypass command.

Default off:

```swift
if selectedDefinition?.bypassPermissionsCommand != nil {
    Toggle("Skip permission checks", isOn: $bypassPermissions)
}
```

- [ ] Resolve commands from Custom Actions.

Use the Custom Action command if available and the bypass checkbox is off. Use the definition bypass command if bypass is on.

```swift
let action = customActions.first { $0.id == definition.id && $0.deletedAt == nil }
let startup = TerminalSessionStartupDefaults.startup(
    for: definition,
    actionCommand: action?.commandContent,
    bypassPermissions: bypassPermissions
)
```

- [ ] Create `TerminalSessionKindBadge.swift`.

Use it in picker rows, tab rows, and attach prompt rows:

```swift
struct TerminalSessionKindBadge: View {
    let startup: TerminalSessionStartup?

    var body: some View {
        Label(
            startup?.displayTitle ?? TerminalSessionKind.tmux.displayName,
            systemImage: startup?.iconSystemName ?? TerminalSessionKind.tmux.iconSystemName
        )
    }
}
```

If an Ubuntu image asset is added later, keep the badge API unchanged and swap only the `.tmux` rendering.

---

## Phase 6: Wire Session Creation Flows

- [ ] Update `ConnectionSessionManager.openConnection`.

Add an optional startup parameter:

```swift
func openConnection(
    to server: Server,
    forceNew: Bool = false,
    startup: TerminalSessionStartup? = nil
) async throws -> ConnectionSession
```

When creating a new `ConnectionSession`, store `startup`. When reusing an existing session and `forceNew == false`, do not overwrite existing startup metadata.

- [ ] Update `TerminalTabManager.openTab`.

Add:

```swift
func openTab(for server: Server, startup: TerminalSessionStartup? = nil) async throws -> TerminalTab
```

Store startup on the tab and root pane.

- [ ] Update `iOSContentView.swift`.

Replace direct new-tab creation with sheet state:

```swift
@State private var pendingNewSessionServer: Server?
@State private var isShowingNewSessionPicker = false
```

`openNewTab()` should set the pending server and present the picker. Picker completion calls:

```swift
try await sessionManager.openConnection(
    to: server,
    forceNew: true,
    startup: startup
)
```

- [ ] Update `ConnectionTabsView.swift`.

Present the same picker for toolbar plus/new-tab actions. Picker completion calls:

```swift
try await tabManager.openTab(for: server, startup: startup)
```

- [ ] Update `ConnectionTabComponents.swift`.

For any quick action that starts a new terminal session, route through the picker if it is a user-visible button. For internal/noninteractive calls, pass `startup: nil`.

---

## Phase 7: Wire Startup Command Into Existing SSH Path

- [ ] Locate the current `startupPlan` closure passed into `SSHTerminalWrapper`.

Update it so new sessions return:

```swift
(command: session.startup?.command, skipTmuxLifecycle: false)
```

or the equivalent tab/pane startup command for the tab manager path.

- [ ] Keep command execution inside the existing bootstrap path.

Do not send startup commands by writing text into the terminal after launch. The command must flow through:

```swift
SSHClient.startShell(cols:rows:startupCommand:)
```

- [ ] Guard reconnect behavior.

For the first implementation, use this rule:

- new local session with startup command: pass the command when creating the shell
- attach to an existing remote tmux session: pass `nil`
- reconnect to an already-known app session: preserve existing tmux attach behavior and do not create a second CLI process

If current tmux lifecycle code cannot distinguish those states clearly, add a local runtime flag keyed by session or pane ID:

```swift
private var submittedStartupCommandSessionIDs: Set<UUID> = []
```

Mark the ID only after the terminal shell start succeeds. Retry can submit the command again only if the previous shell creation failed before success.

---

## Phase 8: Show Icons And Type Labels In Existing Sessions

- [ ] Update `TerminalTabButton` in `ConnectionTabsView.swift`.

Add `TerminalSessionKindBadge(startup: tab.startup)` or an icon-only variant before the title, keeping the existing status dot.

- [ ] Update iOS session lists/switchers in `iOSContentView.swift`.

Where sessions are listed by title, include the badge or icon for `session.startup`.

- [ ] Update `TmuxAttachPromptSheet.swift`.

Known app sessions should show their stored startup metadata. Remote tmux choices without app metadata should show generic TMUX Session with fallback icon.

- [ ] Do not infer CLI type from remote tmux names in this pass.

Only app-created sessions with stored metadata get typed labels. This prevents false positives.

---

## Phase 9: Tests And Verification

- [ ] Add `TerminalSessionStartupTests.swift`.

Minimum tests:

```swift
@Test
func startupDefinitionsContainExpectedCommands() {
    #expect(TerminalSessionStartupDefaults.definitions.contains {
        $0.kind == .claude && $0.baseCommand == "claude"
    })
    #expect(TerminalSessionStartupDefaults.definitions.contains {
        $0.kind == .antigravity && $0.baseCommand == "agy"
    })
    #expect(TerminalSessionStartupDefaults.definitions.contains {
        $0.kind == .codex && $0.bypassPermissionsCommand == "codex --yolo"
    })
}
```

- [ ] Add tests for Custom Action seeding.

Verify idempotency and preservation of edited commands.

- [ ] Add decode compatibility tests if snapshot Codable tests already exist.

If there are no snapshot tests, add focused tests for `TerminalTab` and `TerminalPaneState` decoding old JSON without a startup field.

- [ ] Run focused tests.

```bash
xcodebuild test \
  -project paullm-ssh.xcodeproj \
  -scheme paullm-ssh \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

If the named simulator is unavailable, list destinations and use an installed iOS simulator:

```bash
xcodebuild -showdestinations -project paullm-ssh.xcodeproj -scheme paullm-ssh
```

- [ ] Run a device-style build without signing.

```bash
xcodebuild build \
  -project paullm-ssh.xcodeproj \
  -scheme paullm-ssh \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO
```

---

## Acceptance Criteria

- Starting a new terminal session presents a type picker.
- Claude CLI can start with `claude` or `claude --dangerously-skip-permissions`.
- Antigravity CLI can start with `agy` or `agy --dangerously-skip-permissions`.
- Codex CLI can start with `codex` or `codex --yolo`.
- OpenCode CLI can start with `opencode`.
- Default startup Custom Actions appear in Settings > Custom Actions.
- Custom Actions is top-level in Settings.
- Terminal Settings no longer buries Custom Actions under keyboard accessory settings.
- Multiple sessions of the same type can exist for the same host.
- Existing app-created typed sessions show type icon and label.
- Existing unknown tmux sessions show generic TMUX Session fallback.
- Old local session snapshots without startup metadata still load.
- iOS generic build passes with `CODE_SIGNING_ALLOWED=NO`.
