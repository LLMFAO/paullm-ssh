import Foundation

/// A user-defined session type that persists and appears in the New Session picker.
///
/// Unlike the built-in `TerminalSessionStartupDefaults` entries (which are fixed),
/// saved session types are created, edited, reordered, and deleted by the user, and
/// sync across devices as part of the `TerminalAccessoryProfile` payload.
struct SavedSessionType: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    var title: String
    var command: String
    /// Optional explicit tmux session-name prefix. When `nil` the prefix is derived
    /// from the title/command by the picker (same logic as the one-off custom row).
    var sessionNamePrefix: String?
    var iconSystemName: String
    var order: Int
    var updatedAt: Date
    /// Soft-delete tombstone so deletions propagate through CloudKit merges, mirroring
    /// `TerminalAccessoryCustomAction`.
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        command: String,
        sessionNamePrefix: String? = nil,
        iconSystemName: String = SavedSessionType.defaultIconSystemName,
        order: Int = 0,
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.command = command
        self.sessionNamePrefix = sessionNamePrefix
        self.iconSystemName = iconSystemName
        self.order = order
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    static let defaultIconSystemName = "command"

    /// Builds the launch startup. Kind stays `.custom`; restored-session display is
    /// handled by the existing `.custom` branch in
    /// `TerminalSessionStartup.displayStartup(forExistingTmuxSessionName:)`.
    func startup(workingDirectory: String? = nil) -> TerminalSessionStartup {
        var startup = TerminalSessionStartup.custom(
            displayTitle: title,
            command: command,
            sessionNamePrefix: sessionNamePrefix ?? title
        )
        if !iconSystemName.isEmpty {
            startup.iconSystemName = iconSystemName
        }
        startup.workingDirectory = workingDirectory
        return startup
    }
}
