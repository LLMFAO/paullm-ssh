import Foundation

struct TmuxAttachSessionInfo: Identifiable, Equatable {
    let name: String
    let attachedClients: Int
    let windowCount: Int
    let currentPath: String?
    var startup: TerminalSessionStartup?

    var id: String { name }
}

struct TmuxAttachPrompt: Identifiable, Equatable {
    /// Session ID (ConnectionSession.id or Terminal paneId) that is waiting for selection.
    let id: UUID
    let serverId: UUID
    let serverName: String
    let existingSessions: [TmuxAttachSessionInfo]
    let message: String?

    init(
        id: UUID,
        serverId: UUID,
        serverName: String,
        existingSessions: [TmuxAttachSessionInfo],
        message: String? = nil
    ) {
        self.id = id
        self.serverId = serverId
        self.serverName = serverName
        self.existingSessions = existingSessions
        self.message = message
    }
}

enum TmuxAttachSelection: Equatable {
    case createManaged
    case attachExisting(sessionName: String)
    case skipTmux
}
