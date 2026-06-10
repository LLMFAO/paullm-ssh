import Foundation

struct RemoteTerminalEnvironmentVariable: Hashable, Sendable {
    let name: String
    let value: String
}

enum RemoteShellLaunchPlan: Hashable, Sendable {
    case shell
    case exec(String)
}

enum RemoteTerminalBootstrap {
    nonisolated static let terminalType = "xterm-256color"
    nonisolated static let termProgram = "paullm"

    nonisolated static func appVersion(bundle: Bundle = .main) -> String {
        (bundle.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"
    }

    nonisolated static func terminalEnvironment(bundle: Bundle = .main) -> [RemoteTerminalEnvironmentVariable] {
        [
            RemoteTerminalEnvironmentVariable(name: "COLORTERM", value: "truecolor"),
            RemoteTerminalEnvironmentVariable(name: "TERM_PROGRAM", value: termProgram),
            RemoteTerminalEnvironmentVariable(name: "TERM_PROGRAM_VERSION", value: appVersion(bundle: bundle))
        ]
    }

    nonisolated static func terminalEnvironmentNames(bundle: Bundle = .main) -> [String] {
        terminalEnvironment(bundle: bundle).map(\.name)
    }

    nonisolated static func environmentExportScript(bundle: Bundle = .main) -> String {
        let assignments = terminalEnvironment(bundle: bundle)
            .map { "\($0.name)=\(shellQuoted($0.value))" }
            .joined(separator: " ")
        return "export \(assignments);"
    }

    nonisolated static func defaultLoginShellCommand() -> String {
        """
        if [ -n "$SHELL" ]; then exec "$SHELL" -l; fi;
        if command -v bash >/dev/null 2>&1; then exec bash -l; fi;
        if command -v zsh >/dev/null 2>&1; then exec zsh -l; fi;
        exec sh -l
        """
    }

    /// Runs `command` through a **login** shell, then drops into an interactive
    /// login shell so the tmux session survives the command exiting.
    ///
    /// Login (`-l`) sources the profile files where remote PATH setup lives
    /// (`.zprofile`, `.bash_profile`, Homebrew/npm/`~/.local/bin`), so CLIs are
    /// found on both macOS and Linux. We run the command non-interactively (`-lc`,
    /// never `-ic`): interactive startup (prompt frameworks, instant-prompt, rc
    /// files that read stdin) can stall or echo garbage into the PTY, which is what
    /// made earlier session launches hang or fail to start.
    nonisolated static func loginShellCommand(for command: String) -> String {
        // Launch `command` through the user's INTERACTIVE login shell — the same context
        // as typing it in their terminal — so rc files (`.zshrc`/`.bashrc`, where nvm/asdf
        // and custom PATH usually live) are sourced. A non-interactive shell misses those
        // and is the usual reason a CLI like `opencode` reports "command not found". We
        // also prepend common tool dirs (Homebrew, npm global, ~/.local/bin) as a backstop,
        // and resolve the shell explicitly (zsh → bash → sh) because `$SHELL` can be empty
        // in the tmux-server launch context (which otherwise drops us to bare `sh`).
        //
        // Fast-fail rule: if `command` exits within ~10s (failed to start), drop to an
        // interactive login shell so the error stays on screen instead of the session
        // being silently torn down. A normal long-running exit falls through to `exit`,
        // emptying the tmux session so the app closes it (disconnect-on-empty).
        let inner = """
        \(shellPathExport());
        PAULLM_CLI_START="$(date +%s 2>/dev/null || echo 0)";
        \(command);
        PAULLM_CLI_STATUS=$?;
        PAULLM_CLI_END="$(date +%s 2>/dev/null || echo 0)";
        if [ "$((PAULLM_CLI_END - PAULLM_CLI_START))" -lt 10 ]; then
          printf '\\r\\n[paullm-ssh] command exited (status %s). Keeping this shell open so you can read any error above; type exit to close.\\r\\n' "$PAULLM_CLI_STATUS";
          exec "${PAULLM_SH:-/bin/sh}" -il;
        fi;
        exit "$PAULLM_CLI_STATUS"
        """
        let quotedInner = shellQuoted(inner)
        return """
        PAULLM_SH="${SHELL:-}";
        if [ -z "$PAULLM_SH" ] || [ ! -x "$PAULLM_SH" ]; then
          for PAULLM_C in /bin/zsh /opt/homebrew/bin/zsh /usr/local/bin/zsh /bin/bash /opt/homebrew/bin/bash /usr/local/bin/bash /bin/sh; do
            if [ -x "$PAULLM_C" ]; then PAULLM_SH="$PAULLM_C"; break; fi;
          done;
        fi;
        export PAULLM_SH;
        exec "$PAULLM_SH" -ilc \(quotedInner)
        """
    }

    nonisolated static func launchPlan(
        startupCommand: String?,
        environment: RemoteEnvironment = .fallbackPOSIX,
        bundle: Bundle = .main
    ) -> RemoteShellLaunchPlan {
        environment.shellProfile.launchPlan(startupCommand: startupCommand, bundle: bundle)
    }

    nonisolated static func moshStartupScript(startCommand: String?, bundle: Bundle = .main) -> String {
        let command = trimmedStartupCommand(startCommand)
            .flatMap { unwrapPOSIXShellInvocationIfNeeded($0) ?? $0 }
            ?? defaultLoginShellCommand()
        return prefixedPOSIXScript(for: command, bundle: bundle)
    }

    nonisolated static func wrapPOSIXShellCommand(_ script: String) -> String {
        "/bin/sh -lc \(shellQuoted(script))"
    }

    nonisolated static func wrapPowerShellCommand(_ script: String, executableName: String) -> String {
        let data = script.data(using: .utf16LittleEndian) ?? Data()
        return "\(executableName) -NoLogo -NoProfile -EncodedCommand \(data.base64EncodedString())"
    }

    nonisolated static func wrapCmdCommand(_ command: String) -> String {
        let escaped = command.replacingOccurrences(of: "\"", with: "\"\"")
        return "cmd.exe /d /s /k \"\(escaped)\""
    }

    nonisolated static func wrapCmdExecCommand(_ command: String) -> String {
        // Use a direct `cmd /c <command>` form for non-interactive execution.
        // The quoted `/s /c "..."` form has proven unreliable for launching
        // nested PowerShell commands over Windows OpenSSH exec channels.
        "cmd.exe /d /c \(command)"
    }

    nonisolated static func shellQuoted(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    nonisolated static func posixPastedPath(_ path: String) -> String {
        shellQuoted(path)
    }

    nonisolated static func directoryChangeCommand(
        for path: String,
        environment: RemoteEnvironment = .fallbackPOSIX
    ) -> String {
        environment.shellProfile.directoryChangeCommand(for: path)
    }

    nonisolated static func posixDirectoryChangeCommand(for path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "\n" }
        return "cd -- \(shellQuoted(trimmed))\n"
    }

    nonisolated static func powerShellDirectoryChangeCommand(for path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "\n" }
        let resolved = normalizedWindowsPath(from: trimmed) ?? trimmed
        return "Set-Location -LiteralPath \(powerShellQuoted(resolved))\n"
    }

    nonisolated static func cmdDirectoryChangeCommand(for path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "\n" }
        let resolved = normalizedWindowsPath(from: trimmed) ?? trimmed
        let escaped = resolved.replacingOccurrences(of: "\"", with: "\"\"")
        return "cd /d \"\(escaped)\"\r\n"
    }

    nonisolated static func shellPathExport() -> String {
        "export PATH=\"\(shellPathValue())\""
    }

    nonisolated static func tmuxUpdateEnvironmentVariables(bundle: Bundle = .main) -> [String] {
        tmuxLoginEnvironmentNames + terminalEnvironmentNames(bundle: bundle)
    }

    nonisolated static var tmuxLoginEnvironmentNames: [String] {
        [
            "HOME",
            "USER",
            "LOGNAME",
            "SHELL",
            "PATH",
            "XDG_CONFIG_HOME",
            "XDG_DATA_HOME",
            "XDG_CACHE_HOME",
            "TMPDIR",
            "LANG",
            "LC_ALL",
            "LC_CTYPE"
        ]
    }

    nonisolated static func tmuxArrayOptionCommands(option: String, values: [String]) -> [String] {
        let reset = "set -gu \(option)"
        let assignments = values.enumerated().map { index, value in
            "set -g \(option)[\(index)] \"\(value)\""
        }
        return [reset] + assignments
    }

    nonisolated static func tmuxEnvironmentCommands(bundle: Bundle = .main) -> [String] {
        terminalEnvironment(bundle: bundle).map { variable in
            "set-environment -g \(variable.name) \"\(variable.value)\""
        }
    }

    nonisolated static func loginEnvironmentImportScript() -> String {
        let casePattern = tmuxLoginEnvironmentNames.joined(separator: "|")
        return """
        PAULLM_LOGIN_ENV_FILE="${TMPDIR:-/tmp}/paullm-login-env-$$";
        if [ -n "${SHELL:-}" ] && [ -x "${SHELL:-}" ]; then
          env -i HOME="${HOME:-}" USER="${USER:-}" LOGNAME="${LOGNAME:-${USER:-}}" SHELL="${SHELL:-}" TERM="${TERM:-\(terminalType)}" "$SHELL" -lic env >"$PAULLM_LOGIN_ENV_FILE" 2>/dev/null || true;
        else
          env >"$PAULLM_LOGIN_ENV_FILE" 2>/dev/null || true;
        fi;
        if [ -s "$PAULLM_LOGIN_ENV_FILE" ]; then
          while IFS='=' read -r PAULLM_ENV_NAME PAULLM_ENV_VALUE; do
            case "$PAULLM_ENV_NAME" in
              \(casePattern)) export "$PAULLM_ENV_NAME=$PAULLM_ENV_VALUE" ;;
            esac;
          done <"$PAULLM_LOGIN_ENV_FILE";
        fi;
        rm -f "$PAULLM_LOGIN_ENV_FILE";
        \(shellPathExport());
        """
    }

    nonisolated static func prefixedPOSIXScript(for command: String, bundle: Bundle = .main) -> String {
        "\(environmentExportScript(bundle: bundle)) \(command)"
    }

    nonisolated static func prefixedPowerShellScript(for command: String, bundle: Bundle = .main) -> String {
        let environmentSetup = terminalEnvironment(bundle: bundle)
            .map { "$env:\($0.name) = \(powerShellQuoted($0.value))" }
            .joined(separator: "; ")
        return "\(environmentSetup); \(command)"
    }

    nonisolated private static func trimmedStartupCommand(_ startupCommand: String?) -> String? {
        let trimmed = startupCommand?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    nonisolated private static func unwrapPOSIXShellInvocationIfNeeded(_ command: String) -> String? {
        let prefixes = ["sh -lc ", "/bin/sh -lc "]
        guard let prefix = prefixes.first(where: { command.hasPrefix($0) }) else {
            return nil
        }

        let payload = String(command.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !payload.isEmpty else { return nil }

        if payload.hasPrefix("'"), payload.hasSuffix("'"), payload.count >= 2 {
            let start = payload.index(after: payload.startIndex)
            let end = payload.index(before: payload.endIndex)
            let quoted = String(payload[start..<end])
            return quoted.replacingOccurrences(of: "'\\''", with: "'")
        }

        if payload.hasPrefix("\""), payload.hasSuffix("\""), payload.count >= 2 {
            let start = payload.index(after: payload.startIndex)
            let end = payload.index(before: payload.endIndex)
            let quoted = String(payload[start..<end])
            let unescapedQuotes = quoted.replacingOccurrences(of: "\\\"", with: "\"")
            return unescapedQuotes.replacingOccurrences(of: "\\\\", with: "\\")
        }

        return payload
    }

    nonisolated private static func shellPathValue() -> String {
        let paths = [
            "$HOME/.local/bin",
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/local/sbin",
            "/opt/local/bin",
            "/opt/local/sbin",
            "/snap/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
        return paths.joined(separator: ":") + ":$PATH"
    }

    nonisolated private static func powerShellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "''"))'"
    }

    nonisolated private static func normalizedWindowsPath(from path: String) -> String? {
        if let directDriveLetter = directWindowsDriveLetter(in: path) {
            let startIndex = path.index(path.startIndex, offsetBy: 2)
            let suffix = startIndex < path.endIndex ? String(path[startIndex...]) : ""
            let normalizedSuffix = suffix.replacingOccurrences(of: "/", with: "\\")
            return "\(directDriveLetter):\(normalizedSuffix)"
        }

        if let oscDriveLetter = oscWindowsDriveLetter(in: path) {
            let startIndex = path.index(path.startIndex, offsetBy: 3)
            let suffix = startIndex < path.endIndex ? String(path[startIndex...]) : ""
            let normalizedSuffix = suffix.replacingOccurrences(of: "/", with: "\\")
            return "\(oscDriveLetter):\(normalizedSuffix)"
        }

        if path.hasPrefix("\\\\") {
            return path
        }

        if path.hasPrefix("//") {
            return "\\\\" + String(path.dropFirst(2)).replacingOccurrences(of: "/", with: "\\")
        }

        return nil
    }

    nonisolated private static func directWindowsDriveLetter(in path: String) -> Character? {
        let scalars = Array(path.unicodeScalars)
        guard scalars.count >= 2 else { return nil }

        func isLetter(_ scalar: UnicodeScalar) -> Bool {
            (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
        }

        if isLetter(scalars[0]), scalars[1] == ":" {
            return Character(scalars[0])
        }

        return nil
    }

    nonisolated private static func oscWindowsDriveLetter(in path: String) -> Character? {
        let scalars = Array(path.unicodeScalars)
        guard scalars.count >= 4 else { return nil }

        func isLetter(_ scalar: UnicodeScalar) -> Bool {
            (65...90).contains(Int(scalar.value)) || (97...122).contains(Int(scalar.value))
        }

        guard scalars[0] == "/", isLetter(scalars[1]), scalars[2] == ":", scalars[3] == "/" else {
            return nil
        }
        return Character(scalars[1])
    }
}
