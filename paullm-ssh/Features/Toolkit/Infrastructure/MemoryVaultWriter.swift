import Foundation
import os.log

/// Initializes, inspects, and updates memory-vault files on a remote server via SFTP (fallback to shell heredoc).
@MainActor
final class MemoryVaultWriter {
    static let shared = MemoryVaultWriter()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app.paullm.ssh", category: "MemoryVaultWriter")
    private let adapter = SSHSFTPAdapter()

    private init() {}

    // MARK: — Inspect

    func inspectVault(for server: Server) async -> [MemoryVaultInspection] {
        let templates = MemoryVaultTemplate.defaultVaultSet
            + [MemoryVaultTemplate.opencodeConfigTemplate,
               MemoryVaultTemplate.claudeProjectConfigTemplate,
               MemoryVaultTemplate.codexProjectConfigTemplate]

        var results: [MemoryVaultInspection] = []
        for template in templates {
            let exists = await fileExists(template.fullPath, on: server)
            results.append(MemoryVaultInspection(
                template: template,
                exists: exists
            ))
        }
        return results
    }

    // MARK: — Initialize / Update

    func initializeVault(
        for server: Server,
        projectName: String,
        projectDescription: String,
        includeOpencode: Bool,
        includeClaude: Bool,
        includeCodex: Bool
    ) async throws {
        var templates = MemoryVaultTemplate.defaultVaultSet
        if includeOpencode { templates.append(MemoryVaultTemplate.opencodeConfigTemplate) }
        if includeClaude { templates.append(MemoryVaultTemplate.claudeProjectConfigTemplate) }
        if includeCodex { templates.append(MemoryVaultTemplate.codexProjectConfigTemplate) }

        for template in templates {
            let body = template.body
                .replacingOccurrences(of: "{{PROJECT_NAME}}", with: projectName)
                .replacingOccurrences(of: "{{PROJECT_DESCRIPTION}}", with: projectDescription)
            try await writeFile(body, to: template.fullPath, on: server, strategy: template.mergeStrategy)
        }
    }

    func updateVaultFile(
        for server: Server,
        template: MemoryVaultTemplate,
        body: String
    ) async throws {
        try await writeFile(body, to: template.fullPath, on: server, strategy: .overwrite)
    }

    // MARK: — Helpers

    private func fileExists(_ path: String, on server: Server) async -> Bool {
        do {
            return try await adapter.withService(for: server) { service in
                _ = try await service.stat(at: path)
                return true
            }
        } catch {
            return false
        }
    }

    private func writeFile(
        _ body: String,
        to path: String,
        on server: Server,
        strategy: ToolkitMergeStrategy
    ) async throws {
        guard let data = body.data(using: .utf8) else {
            throw paullm_sshError.encodingFailed
        }

        switch strategy {
        case .create:
            let exists = await fileExists(path, on: server)
            guard !exists else { return }
            try await ensureDirectory(for: path, on: server)
            try await adapter.withService(for: server) { service in
                try await service.upload(data, to: path, permissions: 0o644, strategy: .automatic)
            }

        case .overwrite:
            try await ensureDirectory(for: path, on: server)
            try await adapter.withService(for: server) { service in
                try await service.upload(data, to: path, permissions: 0o644, strategy: .automatic)
            }

        case .append:
            try await adapter.withService(for: server) { service in
                let existing = try await service.readFile(at: path, maxBytes: 1024 * 1024)
                let combined = existing + data
                try await service.upload(combined, to: path, permissions: 0o644, strategy: .automatic)
            }
        }
    }

    private func ensureDirectory(for filePath: String, on server: Server) async throws {
        let dir = (filePath as NSString).deletingLastPathComponent
        guard !dir.isEmpty, dir != "/" else { return }
        try await adapter.withService(for: server) { service in
            try await service.createDirectory(at: dir, permissions: 0o755)
        }
    }
}

struct MemoryVaultInspection: Identifiable, Sendable {
    let id = UUID()
    let template: MemoryVaultTemplate
    let exists: Bool
}

extension MemoryVaultTemplate {
    var fullPath: String {
        if relativeDirectory.isEmpty { return filename }
        return "\(relativeDirectory)/\(filename)"
    }
}
