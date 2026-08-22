import Foundation
import Combine
import os.log

/// Orchestrates the Toolkit catalog, per-entry status, install/verify/setup actions,
/// and memory-vault lifecycle. Injected at the screen boundary.
@MainActor
final class ToolkitManager: ObservableObject {

    // MARK: — State

    @Published var entries: [ToolkitEntry] = ToolkitCatalog.entries
    @Published var statusById: [UUID: ToolkitItemStatus] = [:]
    @Published var isRefreshing = false
    @Published var lastError: Error?
    /// True when status detection could not run because no terminal/stats SSH
    /// client is currently connected to this server. Drives a clear UI hint
    /// instead of leaving every entry in an unexplained "unknown" state.
    @Published var requiresConnection = false

    let server: Server

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app.paullm.ssh", category: "ToolkitManager")
    private var refreshTask: Task<Void, Never>?

    // MARK: — Init

    init(server: Server) {
        self.server = server
        for entry in entries {
            statusById[entry.id] = .unknown
        }
    }

    // MARK: — Refresh Status

    func refreshStatus() {
        guard refreshTask == nil else { return }
        isRefreshing = true
        lastError = nil

        refreshTask = Task {
            defer {
                self.isRefreshing = false
                self.refreshTask = nil
            }

            guard let client = activeClient(for: server) else {
                self.requiresConnection = true
                self.lastError = paullm_sshError.connectionFailed(String(localized: "No active connection to server."))
                return
            }
            self.requiresConnection = false

            var updated: [UUID: ToolkitItemStatus] = [:]
            await withTaskGroup(of: (UUID, ToolkitItemStatus).self) { group in
                for entry in entries {
                    group.addTask {
                        let status = await RemoteToolkitRunner.shared.detect(entry, using: client)
                        return (entry.id, status)
                    }
                }

                for await (id, status) in group {
                    updated[id] = status
                }
            }

            self.statusById = updated
        }
    }

    func cancelRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
        isRefreshing = false
    }

    // MARK: — Actions

    func install(entry: ToolkitEntry) -> TerminalSessionStartup {
        RemoteToolkitRunner.shared.makeRunStartup(for: entry, phase: .install)
    }

    func verify(entry: ToolkitEntry) -> TerminalSessionStartup {
        RemoteToolkitRunner.shared.makeRunStartup(for: entry, phase: .verify)
    }

    func setup(entry: ToolkitEntry) -> TerminalSessionStartup {
        RemoteToolkitRunner.shared.makeRunStartup(for: entry, phase: .setup)
    }

    func uninstall(entry: ToolkitEntry) -> TerminalSessionStartup {
        RemoteToolkitRunner.shared.makeRunStartup(for: entry, phase: .uninstall)
    }

    // MARK: — Memory Vault

    func inspectVault() async -> [MemoryVaultInspection] {
        await MemoryVaultWriter.shared.inspectVault(for: server)
    }

    func initializeVault(
        projectName: String,
        projectDescription: String,
        includeOpencode: Bool,
        includeClaude: Bool,
        includeCodex: Bool
    ) async throws {
        try await MemoryVaultWriter.shared.initializeVault(
            for: server,
            projectName: projectName,
            projectDescription: projectDescription,
            includeOpencode: includeOpencode,
            includeClaude: includeClaude,
            includeCodex: includeCodex
        )
    }

    // MARK: — Helpers

    func status(for entry: ToolkitEntry) -> ToolkitItemStatus {
        statusById[entry.id] ?? .unknown
    }

    func status(for kind: TerminalSessionKind) -> ToolkitItemStatus {
        guard let entry = ToolkitCatalog.entry(for: kind) else { return .unknown }
        return status(for: entry)
    }

    private func activeClient(for server: Server) -> SSHClient? {
        ConnectionSessionManager.shared.sharedStatsClient(for: server.id)
            ?? TerminalTabManager.shared.sharedStatsClient(for: server.id)
    }
}
