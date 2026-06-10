import Foundation
import Testing
@testable import paullm_ssh

struct TerminalSessionStartupTests {
    @Test
    func startupDefinitionsContainExpectedCommands() {
        #expect(TerminalSessionStartupDefaults.definitions.contains {
            $0.kind == .claude
                && $0.baseCommand == "claude"
                && $0.bypassPermissionsCommand == "claude --dangerously-skip-permissions"
        })
        #expect(TerminalSessionStartupDefaults.definitions.contains {
            $0.kind == .antigravity
                && $0.baseCommand == "agy"
                && $0.bypassPermissionsCommand == "agy --dangerously-skip-permissions"
        })
        #expect(TerminalSessionStartupDefaults.definitions.contains {
            $0.kind == .codex
                && $0.baseCommand == "codex"
                && $0.bypassPermissionsCommand == "codex --yolo"
        })
        #expect(TerminalSessionStartupDefaults.definitions.contains {
            $0.kind == .opencode
                && $0.baseCommand == "opencode"
                && $0.bypassPermissionsCommand == nil
        })
    }

    @Test
    func startupUsesEditedCustomActionCommandWhenBypassIsOff() {
        let definition = TerminalSessionStartupDefaults.definitions.first { $0.kind == .claude }!
        let startup = TerminalSessionStartupDefaults.startup(
            for: definition,
            actionCommand: "claude --model sonnet",
            bypassPermissions: false
        )

        #expect(startup.kind == .claude)
        #expect(startup.actionID == definition.id)
        #expect(startup.command == "claude --model sonnet")
        #expect(startup.bypassPermissions == false)
    }

    @Test
    func startupUsesBypassCommandWhenRequested() {
        let definition = TerminalSessionStartupDefaults.definitions.first { $0.kind == .codex }!
        let startup = TerminalSessionStartupDefaults.startup(
            for: definition,
            actionCommand: "codex --model gpt-5",
            bypassPermissions: true
        )

        #expect(startup.command == "codex --yolo")
        #expect(startup.bypassPermissions)
    }

    @Test
    func customStartupSanitizesSessionPrefix() {
        let startup = TerminalSessionStartup.custom(
            displayTitle: "Aider",
            command: "aider --model sonnet",
            sessionNamePrefix: "Aider CLI!"
        )

        #expect(startup.kind == .custom)
        #expect(startup.displayTitle == "Aider")
        #expect(startup.command == "aider --model sonnet")
        #expect(startup.sessionNamePrefix == "aider-cli")
        #expect(startup.bypassPermissions == false)
    }

    @Test
    func profileSeedingAddsStartupActionsIdempotently() {
        let now = Date(timeIntervalSince1970: 1234)
        let seeded = TerminalAccessoryProfile.defaultValue.ensuringDefaultStartupActions(now: now)
        let reseeded = seeded.ensuringDefaultStartupActions(now: now.addingTimeInterval(60))

        let startupActionIDs = Set(TerminalSessionStartupDefaults.definitions.map(\.id))
        let seededStartupActions = seeded.customActions.filter { startupActionIDs.contains($0.id) }
        let reseededStartupActions = reseeded.customActions.filter { startupActionIDs.contains($0.id) }

        #expect(seededStartupActions.count == TerminalSessionStartupDefaults.definitions.count)
        #expect(reseededStartupActions.count == TerminalSessionStartupDefaults.definitions.count)
        #expect(seeded.customActions.count == reseeded.customActions.count)
    }

    @Test
    func profileSeedingPreservesEditedActionAndDeletedAction() {
        let definition = TerminalSessionStartupDefaults.definitions.first { $0.kind == .claude }!
        let edited = TerminalAccessoryCustomAction(
            id: definition.id,
            title: "Claude Custom",
            kind: .command,
            commandContent: "claude --model opus",
            commandSendMode: .insertAndEnter,
            updatedAt: Date(timeIntervalSince1970: 1000)
        )
        let deletedDefinition = TerminalSessionStartupDefaults.definitions.first { $0.kind == .codex }!
        let deletedAt = Date(timeIntervalSince1970: 1001)
        let deleted = TerminalAccessoryCustomAction(
            id: deletedDefinition.id,
            title: "",
            kind: .command,
            commandContent: "",
            commandSendMode: .insertAndEnter,
            updatedAt: deletedAt,
            deletedAt: deletedAt
        )
        let profile = TerminalAccessoryProfile(
            schemaVersion: TerminalAccessoryProfile.schemaVersion,
            layout: TerminalAccessoryLayout(
                version: 1,
                activeItems: TerminalAccessoryProfile.defaultActiveItems,
                updatedAt: .distantPast
            ),
            customActions: [edited, deleted],
            updatedAt: Date(timeIntervalSince1970: 1002),
            lastWriterDeviceId: "device-a"
        )

        let seeded = profile.ensuringDefaultStartupActions(now: Date(timeIntervalSince1970: 2000))

        let seededEdited = seeded.customActions.first { $0.id == definition.id }
        let seededDeleted = seeded.customActions.first { $0.id == deletedDefinition.id }
        #expect(seededEdited?.title == "Claude Custom")
        #expect(seededEdited?.commandContent == "claude --model opus")
        #expect(seededDeleted?.isDeleted == true)
    }

    @MainActor @Test
    func testNormalManagedSessionNameFormatting() {
        let resolver = TmuxAttachResolver()
        let id = UUID()
        let expectedName = "paullm_\(DeviceIdentity.id)_\(id.uuidString)"
        #expect(resolver.managedSessionName(for: id) == expectedName)
    }

    @MainActor @Test
    func testAISessionNameResolutionBypassesPromptAndGeneratesFirstIndex() async {
        let resolver = TmuxAttachResolver()
        let entityId = UUID()
        let serverId = UUID()
        let client = SSHClient()
        
        let startup = TerminalSessionStartup(
            kind: .claude,
            actionID: UUID(),
            displayTitle: "Claude CLI",
            iconSystemName: "sparkles",
            command: "claude",
            bypassPermissions: false
        )
        
        var promptCalled = false
        let selection = await resolver.resolveSelection(
            for: entityId,
            serverId: serverId,
            client: client,
            startup: startup,
            setPrompt: { _ in
                promptCalled = true
            }
        )
        
        #expect(!promptCalled)
        #expect(selection == .createManaged)
        #expect(resolver.sessionName(for: entityId) == "claude-1")
        #expect(resolver.sessionOwnership[entityId] == .managed)
    }

    @MainActor @Test
    func testAISessionNameResolutionUsesPersistedCustomName() async {
        let resolver = TmuxAttachResolver()
        let entityId = UUID()
        let serverId = UUID()
        let client = SSHClient()
        
        let startup = TerminalSessionStartup(
            kind: .antigravity,
            actionID: UUID(),
            displayTitle: "Antigravity CLI",
            iconSystemName: "atom",
            command: "agy",
            bypassPermissions: false
        )
        
        // Persist a custom name first
        resolver.setCustomSessionName("antigravity-pre-existing", for: entityId)
        
        var promptCalled = false
        let selection = await resolver.resolveSelection(
            for: entityId,
            serverId: serverId,
            client: client,
            startup: startup,
            setPrompt: { _ in
                promptCalled = true
            }
        )
        
        #expect(!promptCalled)
        #expect(selection == .createManaged)
        #expect(resolver.sessionName(for: entityId) == "antigravity-pre-existing")
        #expect(resolver.sessionOwnership[entityId] == .managed)
        
        // Cleanup and make sure it deletes the AI-looking pre-existing name
        resolver.clearAttachmentState(for: entityId)
        #expect(resolver.sessionName(for: entityId) != "antigravity-pre-existing")
    }

    @MainActor @Test
    func testClearAttachmentStateCleansUpOnlyAISessionNames() {
        let resolver = TmuxAttachResolver()
        let id1 = UUID()
        let id2 = UUID()
        
        resolver.setCustomSessionName("claude-4", for: id1)
        resolver.setCustomSessionName("my-hand-made-session", for: id2)
        
        resolver.clearAttachmentState(for: id1)
        resolver.clearAttachmentState(for: id2)
        
        #expect(resolver.sessionName(for: id1) != "claude-4")
        #expect(resolver.sessionName(for: id2) == "my-hand-made-session")
    }

    @MainActor @Test
    func immediateManagedSelectionUsesIndexedAISessionNames() {
        let resolver = TmuxAttachResolver()
        let id = UUID()
        let startup = TerminalSessionStartup(
            kind: .codex,
            actionID: UUID(),
            displayTitle: "Codex CLI",
            iconSystemName: "chevron.left.forwardslash.chevron.right",
            command: "codex",
            bypassPermissions: false
        )

        resolver.sessionNames[id] = "codex"
        let selection = resolver.prepareManagedSelection(
            for: id,
            startup: startup,
            existingSessionNames: ["codex-1"]
        )

        #expect(selection == .createManaged)
        #expect(resolver.sessionName(for: id) == "codex-2")
        #expect(resolver.sessionOwnership[id] == .managed)
    }

    @MainActor @Test
    func immediateManagedSelectionAvoidsLocalAISessionNameCollisions() {
        let resolver = TmuxAttachResolver()
        let firstId = UUID()
        let secondId = UUID()
        let startup = TerminalSessionStartup(
            kind: .opencode,
            actionID: UUID(),
            displayTitle: "OpenCode CLI",
            iconSystemName: "curlybraces",
            command: "opencode",
            bypassPermissions: false
        )

        _ = resolver.prepareManagedSelection(for: firstId, startup: startup)
        _ = resolver.prepareManagedSelection(for: secondId, startup: startup)

        #expect(resolver.sessionName(for: firstId) == "opencode-1")
        #expect(resolver.sessionName(for: secondId) == "opencode-2")
    }

    @MainActor @Test
    func immediateManagedSelectionUsesCustomSessionPrefix() {
        let resolver = TmuxAttachResolver()
        let id = UUID()
        let startup = TerminalSessionStartup.custom(
            displayTitle: "Aider",
            command: "aider --model sonnet",
            sessionNamePrefix: "Aider CLI!"
        )

        let selection = resolver.prepareManagedSelection(
            for: id,
            startup: startup,
            existingSessionNames: ["aider-cli-1"]
        )

        #expect(selection == .createManaged)
        #expect(resolver.sessionName(for: id) == "aider-cli-2")

        resolver.clearAttachmentState(for: id)
        #expect(resolver.sessionName(for: id) != "aider-cli-2")
    }

    @Test
    func tmuxStartupCommandRunsInitialCommandThroughLoginShell() {
        let command = RemoteTmuxManager.shared.attachCommand(
            sessionName: "opencode-1",
            workingDirectory: "~",
            initialCommand: "opencode"
        )

        #expect(command.contains("opencode"))
        #expect(command.contains("$SHELL"))
        // The CLI runs through a non-interactive login shell (`-lc`), never an
        // interactive one (`-ic`): interactive startup could stall or echo garbage
        // into the PTY.
        #expect(command.contains("-lc"))
        #expect(!command.contains("-ic"))
        // The CLI is not `exec`'d: after it exits (finished, crashed, or "command not
        // found") we drop into an interactive login shell so the tmux session stays
        // alive. It ends only on Ctrl-D / disconnect, not when the CLI exits.
        #expect(command.contains("exec \"$SHELL\" -l"))
        #expect(command.contains("exec sh -l"))
    }
}
