import Foundation

@MainActor
final class SSHSFTPAdapter {
    typealias BorrowedClientProvider = @MainActor (UUID) -> SSHClient?

    private enum ClientOwnership {
        case borrowed
        case owned
    }

    private struct ClientRegistration {
        let client: SSHClient
        let ownership: ClientOwnership
    }

    private var clients: [UUID: ClientRegistration] = [:]
    private let borrowedClientProvider: BorrowedClientProvider

    init(
        // SFTP uses a dedicated connection rather than borrowing the live terminal
        // session. Borrowing shares the terminal's libssh2 session, whose I/O loop
        // blocks the actor in long (up to 250ms) idle poll() waits — that starves
        // concurrent SFTP reads and leaves the file browser stuck on "loading
        // files". A dedicated connection has no competing shell I/O loop, so SFTP
        // stays responsive. Tests can still inject a borrowed client.
        borrowedClientProvider: @escaping BorrowedClientProvider = { _ in nil }
    ) {
        self.borrowedClientProvider = borrowedClientProvider
    }

    func withService<T>(
        for server: Server,
        operation: @escaping (any RemoteFileService) async throws -> T
    ) async throws -> T {
        do {
            return try await runService(for: server, operation: operation)
        } catch let sshError as SSHError where sshError.isHostKeyChallenge {
            // The Files/SFTP flow opens its own connection, so first contact with
            // a host surfaces a host-key challenge. Present the same fingerprint
            // prompt the terminal uses; on approval, retry once now that trust is
            // pinned. Otherwise the user could never reach SFTP on a new host.
            let approved = await ConnectionSessionManager.shared.requestHostKeyApproval(
                for: sshError,
                server: server
            )
            guard approved else { throw sshError }
            return try await runService(for: server, operation: operation)
        }
    }

    private func runService<T>(
        for server: Server,
        operation: @escaping (any RemoteFileService) async throws -> T
    ) async throws -> T {
        let registration = clientRegistration(for: server)
        let credentials = try KeychainManager.shared.getCredentials(for: server)

        do {
            return try await SSHConnectionOperationService.shared.runWithConnection(
                using: registration.client,
                server: server,
                credentials: credentials,
                disconnectWhenDone: false
            ) { client in
                try await operation(SFTPRemoteFileService(client: client))
            }
        } catch {
            if registration.ownership == .borrowed {
                clients.removeValue(forKey: server.id)
            }
            throw error
        }
    }

    func disconnect(serverId: UUID) {
        guard let registration = clients.removeValue(forKey: serverId) else { return }
        guard registration.ownership == .owned else { return }

        Task.detached(priority: .utility) {
            await registration.client.disconnect()
        }
    }

    private func borrowedClient(for serverId: UUID) -> SSHClient? {
        borrowedClientProvider(serverId)
    }

    private func clientRegistration(for server: Server) -> ClientRegistration {
        if let borrowedClient = borrowedClient(for: server.id) {
            if let existing = clients[server.id], existing.client === borrowedClient {
                return existing
            }

            let registration = ClientRegistration(client: borrowedClient, ownership: .borrowed)
            clients[server.id] = registration
            return registration
        }

        if let existing = clients[server.id], existing.ownership == .owned {
            return existing
        }

        let registration = ClientRegistration(client: SSHClient(), ownership: .owned)
        clients[server.id] = registration
        return registration
    }
}
