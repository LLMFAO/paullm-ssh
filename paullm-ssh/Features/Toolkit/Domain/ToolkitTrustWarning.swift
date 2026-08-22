import Foundation

/// Derived trust warnings computed from a `ToolkitEntry`'s scripts and metadata.
struct ToolkitTrustWarning: Equatable, Sendable {
    let usesSudo: Bool
    let curlPipeShell: Bool
    let writesShellProfile: Bool
    let credentialAdjacentPath: Bool

    var hasAnyWarning: Bool {
        usesSudo || curlPipeShell || writesShellProfile || credentialAdjacentPath
    }

    static func compute(for entry: ToolkitEntry) -> ToolkitTrustWarning {
        let install = entry.installScript.lowercased()
        let writes = entry.writesTo.map { $0.lowercased() }

        let usesSudo = entry.requiresSudo || install.contains("sudo ")
        let curlPipeShell = install.contains("curl") && (install.contains("| sh") || install.contains("| bash") || install.contains("| /bin/bash"))
        let writesShellProfile = writes.contains(where: {
            $0.contains(".bashrc") || $0.contains(".zshrc") || $0.contains(".bash_profile") || $0.contains(".profile")
        }) || install.contains(".bashrc") || install.contains(".zshrc") || install.contains(".bash_profile") || install.contains(".profile")
        let credentialAdjacentPath = writes.contains(where: {
            $0.contains(".ssh") || $0.contains(".gnupg") || $0.contains("keychain") || $0.contains("credentials")
        })

        return ToolkitTrustWarning(
            usesSudo: usesSudo,
            curlPipeShell: curlPipeShell,
            writesShellProfile: writesShellProfile,
            credentialAdjacentPath: credentialAdjacentPath
        )
    }
}
