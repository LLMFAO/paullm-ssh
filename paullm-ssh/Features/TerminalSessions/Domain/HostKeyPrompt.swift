import Foundation

/// A user-facing prompt presented when an SSH host key needs an explicit
/// trust decision: either a first contact (`unknown`) or a fingerprint
/// change from a previously pinned key (`changed`).
struct HostKeyPrompt: Identifiable, Equatable {
    enum Kind: Equatable {
        /// First contact with the host. The user has not seen this
        /// fingerprint before.
        case unknown
        /// The pinned fingerprint does not match the one the server just
        /// presented. Carries the previously-pinned fingerprint for display.
        case changed(knownFingerprint: String)
    }

    /// ID of the session/pane awaiting the decision.
    let id: UUID
    let serverId: UUID
    let serverName: String
    let host: String
    let port: Int
    let presentedFingerprint: String
    let keyType: Int
    let kind: Kind
}

extension HostKeyPrompt.Kind {
    /// Localized alert title appropriate for the kind of decision the user
    /// is being asked to make.
    var warningTitle: String {
        switch self {
        case .unknown:
            return String(localized: "Verify Host Key")
        case .changed:
            return String(localized: "Host Key Changed")
        }
    }
}

extension SSHError {
    /// Build a `HostKeyPrompt` from the typed host-key errors thrown by
    /// `SSHClient.verifyHostKey()`. Returns nil for other error cases.
    func hostKeyPrompt(sessionId: UUID, serverId: UUID, serverName: String) -> HostKeyPrompt? {
        switch self {
        case .hostKeyUnknown(let host, let port, let fingerprint, let keyType):
            return HostKeyPrompt(
                id: sessionId,
                serverId: serverId,
                serverName: serverName,
                host: host,
                port: port,
                presentedFingerprint: fingerprint,
                keyType: keyType,
                kind: .unknown
            )
        case .hostKeyMismatch(let host, let port, let knownFingerprint, let presentedFingerprint, let keyType):
            return HostKeyPrompt(
                id: sessionId,
                serverId: serverId,
                serverName: serverName,
                host: host,
                port: port,
                presentedFingerprint: presentedFingerprint,
                keyType: keyType,
                kind: .changed(knownFingerprint: knownFingerprint)
            )
        default:
            return nil
        }
    }
}
