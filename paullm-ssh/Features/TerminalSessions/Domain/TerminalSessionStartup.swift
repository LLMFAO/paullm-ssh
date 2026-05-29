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
        case .tmux:
            return String(localized: "TMUX Session")
        case .claude:
            return String(localized: "Claude CLI")
        case .antigravity:
            return String(localized: "Antigravity CLI")
        case .codex:
            return String(localized: "Codex CLI")
        case .opencode:
            return String(localized: "OpenCode CLI")
        }
    }

    var iconSystemName: String {
        switch self {
        case .tmux:
            return "terminal"
        case .claude:
            return "sparkles"
        case .antigravity:
            return "atom"
        case .codex:
            return "chevron.left.forwardslash.chevron.right"
        case .opencode:
            return "curlybraces"
        }
    }

    var iconAssetName: String {
        switch self {
        case .tmux:
            return "SessionIconUbuntu"
        case .claude:
            return "SessionIconClaude"
        case .antigravity:
            return "SessionIconAntigravity"
        case .codex:
            return "SessionIconCodex"
        case .opencode:
            return "SessionIconOpenCode"
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

    static var tmux: TerminalSessionStartup {
        TerminalSessionStartup(
            kind: .tmux,
            actionID: nil,
            displayTitle: TerminalSessionKind.tmux.displayName,
            iconSystemName: TerminalSessionKind.tmux.iconSystemName,
            command: nil,
            bypassPermissions: false
        )
    }
}

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
        TerminalStartupActionDefinition(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            kind: .claude,
            title: String(localized: "Claude CLI"),
            baseCommand: "claude",
            bypassPermissionsCommand: "claude --dangerously-skip-permissions"
        ),
        TerminalStartupActionDefinition(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            kind: .antigravity,
            title: String(localized: "Antigravity CLI"),
            baseCommand: "agy",
            bypassPermissionsCommand: "agy --dangerously-skip-permissions"
        ),
        TerminalStartupActionDefinition(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
            kind: .codex,
            title: String(localized: "Codex CLI"),
            baseCommand: "codex",
            bypassPermissionsCommand: "codex --yolo"
        ),
        TerminalStartupActionDefinition(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
            kind: .opencode,
            title: String(localized: "OpenCode CLI"),
            baseCommand: "opencode",
            bypassPermissionsCommand: nil
        )
    ]

    static func definition(for id: UUID?) -> TerminalStartupActionDefinition? {
        guard let id else { return nil }
        return definitions.first { $0.id == id }
    }

    static func startup(
        for definition: TerminalStartupActionDefinition,
        actionCommand: String?,
        bypassPermissions: Bool
    ) -> TerminalSessionStartup {
        let trimmedActionCommand = actionCommand?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCommand: String
        if bypassPermissions {
            resolvedCommand = definition.command(bypassPermissions: true)
        } else if let trimmedActionCommand, !trimmedActionCommand.isEmpty {
            resolvedCommand = trimmedActionCommand
        } else {
            resolvedCommand = definition.baseCommand
        }

        return TerminalSessionStartup(
            kind: definition.kind,
            actionID: definition.id,
            displayTitle: definition.title,
            iconSystemName: definition.kind.iconSystemName,
            command: resolvedCommand,
            bypassPermissions: bypassPermissions
        )
    }
}
