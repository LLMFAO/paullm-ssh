import Foundation
import os.log

/// Generalized safe script runner for Toolkit entries.
/// Mirrors `RemoteTmuxManager` patterns: silent detect/verify via `client.execute`,
/// script construction through `RemoteTerminalBootstrap.shellQuoted`, no secret injection.
actor RemoteToolkitRunner {
    static let shared = RemoteToolkitRunner()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app.paullm.ssh", category: "RemoteToolkitRunner")
    private let probeTimeout: Duration = .seconds(8)
    private let marker = "__PAULLM_TOOLKIT_OK__"

    private init() {}

    // MARK: — Detect & Verify

    func detect(_ entry: ToolkitEntry, using client: SSHClient) async -> ToolkitItemStatus {
        let output = try? await client.execute(entry.detectScript, timeout: probeTimeout)
        if output?.contains(marker) == true {
            return .installed
        }
        return .missing
    }

    func verify(_ entry: ToolkitEntry, using client: SSHClient) async -> Bool {
        let output = try? await client.execute(entry.verifyScript, timeout: probeTimeout)
        return output?.contains(marker) == true
    }

    // MARK: — Script Building

    /// Builds a POSIX shell script that:
    /// 1. Exports PATH.
    /// 2. Writes a user-owned temp script file (avoids quoting the phase body
    ///    through several shell layers).
    /// 3. Runs it, then drops to an interactive login shell so output stays
    ///    inspectable.
    ///
    /// It deliberately does **not** create a tmux session. Toolkit actions are
    /// opened as `.custom` startups, which the app already wraps in its managed
    /// tmux startup path (`tmuxStartupPlan` → `tmuxStartupCommand`). Creating a
    /// tmux session here too would nest tmux and break attach/state.
    nonisolated func makeRunScript(
        for entry: ToolkitEntry,
        phase: ToolkitRunPhase
    ) -> String {
        let scriptBody = phaseScriptBody(for: entry, phase: phase)

        return """
        \(RemoteTerminalBootstrap.shellPathExport());
        TMP_SCRIPT="$HOME/.paullm_toolkit_\(entry.id.uuidString.prefix(8)).sh";
        cat > "$TMP_SCRIPT" <<'PAULLM_EOF'
        \(scriptBody)
        PAULLM_EOF
        chmod +x "$TMP_SCRIPT";
        sh "$TMP_SCRIPT";
        PAULLM_TOOLKIT_STATUS=$?;
        rm -f "$TMP_SCRIPT";
        if [ "$PAULLM_TOOLKIT_STATUS" -ne 0 ]; then
          printf '%s\\n' "Toolkit action exited with status $PAULLM_TOOLKIT_STATUS.";
        fi;
        exec "${SHELL:-/bin/sh}" -l
        """
    }

    /// Returns a `TerminalSessionStartup` suitable for passing to `ConnectionSessionManager.openConnection(..., startup:)`.
    nonisolated func makeRunStartup(
        for entry: ToolkitEntry,
        phase: ToolkitRunPhase
    ) -> TerminalSessionStartup {
        let command = makeRunScript(for: entry, phase: phase)
        let title: String
        switch phase {
        case .install:
            title = String(localized: "Install \(entry.title)")
        case .verify:
            title = String(localized: "Verify \(entry.title)")
        case .setup:
            title = String(localized: "Setup \(entry.title)")
        case .uninstall:
            title = String(localized: "Uninstall \(entry.title)")
        }
        return TerminalSessionStartup.custom(
            displayTitle: title,
            command: command,
            sessionNamePrefix: entry.tmuxSessionPrefix
        )
    }

    // MARK: — Phase Script Body

    nonisolated private func phaseScriptBody(for entry: ToolkitEntry, phase: ToolkitRunPhase) -> String {
        switch phase {
        case .install:
            return entry.installScript
        case .verify:
            return entry.verifyScript
        case .setup:
            return entry.setupScript ?? "echo 'No setup script provided.'"
        case .uninstall:
            return entry.uninstallScript ?? "echo 'No uninstall script provided.'"
        }
    }
}

enum ToolkitRunPhase {
    case install
    case verify
    case setup
    case uninstall
}
