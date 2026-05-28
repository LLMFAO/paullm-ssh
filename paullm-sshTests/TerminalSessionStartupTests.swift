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
}
