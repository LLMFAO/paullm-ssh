import Foundation

enum TerminalSessionKind: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case tmux
    case shell
    case claude
    case antigravity
    case codex
    case opencode
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tmux:
            return String(localized: "TMUX Session")
        case .shell:
            return String(localized: "Shell")
        case .claude:
            return String(localized: "Claude CLI")
        case .antigravity:
            return String(localized: "Antigravity CLI")
        case .codex:
            return String(localized: "Codex CLI")
        case .opencode:
            return String(localized: "OpenCode CLI")
        case .custom:
            return String(localized: "Custom Session")
        }
    }

    var iconSystemName: String {
        switch self {
        case .tmux:
            return "terminal"
        case .shell:
            return "terminal"
        case .claude:
            return "sparkles"
        case .antigravity:
            return "atom"
        case .codex:
            return "chevron.left.forwardslash.chevron.right"
        case .opencode:
            return "curlybraces"
        case .custom:
            return "command"
        }
    }

    var iconAssetName: String {
        switch self {
        case .tmux:
            return "SessionIconUbuntu"
        case .shell:
            return ""
        case .claude:
            return "SessionIconClaude"
        case .antigravity:
            return "SessionIconAntigravity"
        case .codex:
            return "SessionIconCodex"
        case .opencode:
            return "SessionIconOpenCode"
        case .custom:
            return ""
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
    var sessionNamePrefix: String? = nil
    /// Optional remote directory to start the session in (tmux `-c` or a `cd`).
    /// Optional so older persisted snapshots decode cleanly.
    var workingDirectory: String? = nil

    static var tmux: TerminalSessionStartup {
        TerminalSessionStartup(
            kind: .tmux,
            actionID: nil,
            displayTitle: TerminalSessionKind.tmux.displayName,
            iconSystemName: TerminalSessionKind.tmux.iconSystemName,
            command: nil,
            bypassPermissions: false,
            sessionNamePrefix: nil
        )
    }

    /// A plain SSH login shell that bypasses tmux entirely and runs no command.
    static var shell: TerminalSessionStartup {
        TerminalSessionStartup(
            kind: .shell,
            actionID: nil,
            displayTitle: TerminalSessionKind.shell.displayName,
            iconSystemName: TerminalSessionKind.shell.iconSystemName,
            command: nil,
            bypassPermissions: false,
            sessionNamePrefix: nil
        )
    }

    static func custom(
        displayTitle: String,
        command: String,
        sessionNamePrefix: String?
    ) -> TerminalSessionStartup {
        TerminalSessionStartup(
            kind: .custom,
            actionID: nil,
            displayTitle: displayTitle,
            iconSystemName: TerminalSessionKind.custom.iconSystemName,
            command: command,
            bypassPermissions: false,
            sessionNamePrefix: TerminalSessionStartup.sanitizedSessionNamePrefix(sessionNamePrefix)
        )
    }

    static func existingTmuxSession(named sessionName: String) -> TerminalSessionStartup {
        if let kind = TerminalSessionKind.builtInSessionKind(forSessionName: sessionName) {
            return TerminalSessionStartup(
                kind: kind,
                actionID: nil,
                displayTitle: kind.displayName,
                iconSystemName: kind.iconSystemName,
                command: nil,
                bypassPermissions: false,
                sessionNamePrefix: kind.rawValue
            )
        }

        return TerminalSessionStartup(
            kind: .tmux,
            actionID: nil,
            displayTitle: TerminalSessionKind.tmux.displayName,
            iconSystemName: TerminalSessionKind.tmux.iconSystemName,
            command: nil,
            bypassPermissions: false,
            sessionNamePrefix: nil
        )
    }

    static func displayStartup(forExistingTmuxSessionName sessionName: String) -> TerminalSessionStartup? {
        if TerminalSessionKind.builtInSessionKind(forSessionName: sessionName) != nil {
            return existingTmuxSession(named: sessionName)
        }

        guard let prefix = indexedSessionPrefix(in: sessionName) else {
            return nil
        }

        return TerminalSessionStartup(
            kind: .custom,
            actionID: nil,
            displayTitle: prefix,
            iconSystemName: TerminalSessionKind.custom.iconSystemName,
            command: nil,
            bypassPermissions: false,
            sessionNamePrefix: prefix
        )
    }

    static func sanitizedSessionNamePrefix(_ value: String?) -> String? {
        guard let value else { return nil }
        let lowered = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var result = ""
        var lastWasSeparator = false

        for scalar in lowered.unicodeScalars {
            let isAllowed = CharacterSet.alphanumerics.contains(scalar)
                || scalar == UnicodeScalar("_")
                || scalar == UnicodeScalar("-")
            if isAllowed {
                result.unicodeScalars.append(scalar)
                lastWasSeparator = false
            } else if !lastWasSeparator {
                result.append("-")
                lastWasSeparator = true
            }
        }

        let trimmed = result.trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(24))
    }

    private static func indexedSessionPrefix(in sessionName: String) -> String? {
        guard let separatorIndex = sessionName.lastIndex(of: "-") else { return nil }
        let suffix = sessionName[sessionName.index(after: separatorIndex)...]
        guard !suffix.isEmpty, suffix.allSatisfy(\.isNumber) else { return nil }
        let prefix = String(sessionName[..<separatorIndex])
        return sanitizedSessionNamePrefix(prefix)
    }
}

extension TerminalSessionKind {
    static func builtInSessionKind(forSessionName sessionName: String) -> TerminalSessionKind? {
        let typedKinds: [TerminalSessionKind] = [.claude, .antigravity, .codex, .opencode]
        return typedKinds.first { sessionName.hasPrefix("\($0.rawValue)-") }
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
            bypassPermissions: bypassPermissions,
            sessionNamePrefix: definition.kind.rawValue
        )
    }
}
