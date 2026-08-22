import Foundation

enum ToolkitCatalog {
    /// Curated static catalog for Slice 1 (AI CLIs) + placeholders for Slices 2 & 3.
    static var entries: [ToolkitEntry] {
        aiCLIEntries + skillEntries + memoryVaultEntries
    }

    static func entry(for id: UUID) -> ToolkitEntry? {
        entries.first { $0.id == id }
    }

    static func entry(for kind: TerminalSessionKind) -> ToolkitEntry? {
        entries.first { $0.linkedTerminalSessionKind == kind }
    }

    // MARK: — AI CLIs (Slice 1)

    private static var aiCLIEntries: [ToolkitEntry] {
        let defs = TerminalSessionStartupDefaults.definitions
        var result: [ToolkitEntry] = []

        for def in defs {
            switch def.kind {
            case .claude:
                result.append(claudeEntry(baseCommand: def.baseCommand))
            case .codex:
                result.append(codexEntry(baseCommand: def.baseCommand))
            case .opencode:
                result.append(opencodeEntry(baseCommand: def.baseCommand))
            case .antigravity:
                result.append(antigravityEntry(baseCommand: def.baseCommand))
            default:
                break
            }
        }

        result.append(aiderEntry())
        result.append(gooseEntry())
        return result
    }

    private static func claudeEntry(baseCommand: String) -> ToolkitEntry {
        ToolkitEntry(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            title: String(localized: "Claude Code"),
            category: .aiCLIs,
            description: String(localized: "Anthropic's Claude Code agent. Install via npm, authenticate through its own flow."),
            riskLevel: .medium,
            sourceURL: URL(string: "https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview"),
            docsURL: URL(string: "https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview"),
            detectScript: "command -v claude && echo __PAULLM_TOOLKIT_OK__",
            installScript: "npm install -g @anthropic-ai/claude-code",
            verifyScript: "claude --version && echo __PAULLM_TOOLKIT_OK__",
            setupScript: "claude auth login",
            uninstallScript: "npm uninstall -g @anthropic-ai/claude-code",
            requiresSudo: false,
            writesTo: ["~/.claude"],
            secretsPolicy: .externalCliOwned,
            tmuxSessionPrefix: "toolkit-claude",
            linkedTerminalSessionKind: .claude
        )
    }

    private static func codexEntry(baseCommand: String) -> ToolkitEntry {
        ToolkitEntry(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
            title: String(localized: "Codex CLI"),
            category: .aiCLIs,
            description: String(localized: "OpenAI's Codex CLI. Install via npm, authenticate through its own flow."),
            riskLevel: .medium,
            sourceURL: URL(string: "https://github.com/openai/codex"),
            docsURL: URL(string: "https://github.com/openai/codex/blob/main/README.md"),
            detectScript: "command -v codex && echo __PAULLM_TOOLKIT_OK__",
            installScript: "npm install -g @openai/codex",
            verifyScript: "codex --version && echo __PAULLM_TOOLKIT_OK__",
            setupScript: "codex login --device-auth",
            uninstallScript: "npm uninstall -g @openai/codex",
            requiresSudo: false,
            writesTo: ["~/.codex"],
            secretsPolicy: .externalCliOwned,
            tmuxSessionPrefix: "toolkit-codex",
            linkedTerminalSessionKind: .codex
        )
    }

    private static func opencodeEntry(baseCommand: String) -> ToolkitEntry {
        ToolkitEntry(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!,
            title: String(localized: "OpenCode CLI"),
            category: .aiCLIs,
            description: String(localized: "OpenCode interactive coding agent. Install via npm, authenticate through its own flow."),
            riskLevel: .medium,
            sourceURL: URL(string: "https://github.com/opencode-ai/opencode"),
            docsURL: URL(string: "https://github.com/opencode-ai/opencode/blob/main/README.md"),
            detectScript: "command -v opencode && echo __PAULLM_TOOLKIT_OK__",
            installScript: "npm install -g opencode-ai",
            verifyScript: "opencode --version && echo __PAULLM_TOOLKIT_OK__",
            setupScript: "opencode auth login",
            uninstallScript: "npm uninstall -g opencode-ai",
            requiresSudo: false,
            writesTo: ["~/.opencode"],
            secretsPolicy: .externalCliOwned,
            tmuxSessionPrefix: "toolkit-opencode",
            linkedTerminalSessionKind: .opencode
        )
    }

    private static func antigravityEntry(baseCommand: String) -> ToolkitEntry {
        ToolkitEntry(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!,
            title: String(localized: "Antigravity CLI"),
            category: .aiCLIs,
            description: String(localized: "Antigravity coding assistant. Install via official curl script."),
            riskLevel: .high,
            sourceURL: URL(string: "https://antigravity.ai"),
            docsURL: URL(string: "https://antigravity.ai/docs"),
            detectScript: "command -v agy && echo __PAULLM_TOOLKIT_OK__",
            installScript: "curl -fsSL https://antigravity.google/cli/install.sh | bash",
            verifyScript: "agy --version && echo __PAULLM_TOOLKIT_OK__",
            setupScript: "agy",
            uninstallScript: nil,
            requiresSudo: false,
            writesTo: ["~/.antigravity"],
            secretsPolicy: .externalCliOwned,
            tmuxSessionPrefix: "toolkit-antigravity",
            linkedTerminalSessionKind: .antigravity
        )
    }

    private static func aiderEntry() -> ToolkitEntry {
        ToolkitEntry(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000005")!,
            title: String(localized: "Aider"),
            category: .aiCLIs,
            description: String(localized: "Aider — AI pair programming in your terminal. Install via pip."),
            riskLevel: .low,
            sourceURL: URL(string: "https://aider.chat"),
            docsURL: URL(string: "https://aider.chat/docs/"),
            detectScript: "command -v aider && echo __PAULLM_TOOLKIT_OK__",
            installScript: "pip install aider-chat",
            verifyScript: "aider --version && echo __PAULLM_TOOLKIT_OK__",
            setupScript: "aider",
            uninstallScript: "pip uninstall -y aider-chat",
            requiresSudo: false,
            writesTo: ["~/.aider"],
            secretsPolicy: .externalCliOwned,
            tmuxSessionPrefix: "toolkit-aider",
            linkedTerminalSessionKind: nil
        )
    }

    private static func gooseEntry() -> ToolkitEntry {
        ToolkitEntry(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000006")!,
            title: String(localized: "Goose"),
            category: .aiCLIs,
            description: String(localized: "Block's Goose AI agent. Install via official installer."),
            riskLevel: .medium,
            sourceURL: URL(string: "https://github.com/block/goose"),
            docsURL: URL(string: "https://github.com/block/goose/blob/main/README.md"),
            detectScript: "command -v goose && echo __PAULLM_TOOLKIT_OK__",
            installScript: "curl -fsSL https://github.com/block/goose/releases/latest/download/install.sh | bash",
            verifyScript: "goose --version && echo __PAULLM_TOOLKIT_OK__",
            setupScript: "goose",
            uninstallScript: nil,
            requiresSudo: false,
            writesTo: ["~/.goose"],
            secretsPolicy: .externalCliOwned,
            tmuxSessionPrefix: "toolkit-goose",
            linkedTerminalSessionKind: nil
        )
    }

    // MARK: — Skills & Prompt Packs (Slice 2)

    private static var skillEntries: [ToolkitEntry] {
        [
            ToolkitEntry(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
                title: String(localized: "Project AGENTS.md"),
                category: .promptPacks,
                description: String(localized: "Bootstrap an AGENTS.md file in the project root with agent rules, context, and stack notes."),
                riskLevel: .low,
                sourceURL: nil,
                docsURL: nil,
                detectScript: "test -f AGENTS.md && echo __PAULLM_TOOLKIT_OK__",
                installScript: "cat > AGENTS.md <<'EOF'\n# Project Agents\n\n## Context\n- Project: \n- Stack: \n- Repo: \n\n## Agent Rules\n- Use atomic commits.\n- Prefer explicit dependency injection.\n- Keep platform parity unless fixing a platform-specific bug.\n- Never apply glass to terminal content (only nav/toolbars).\nEOF",
                verifyScript: "test -f AGENTS.md && echo __PAULLM_TOOLKIT_OK__",
                setupScript: nil,
                uninstallScript: "rm -f AGENTS.md",
                requiresSudo: false,
                writesTo: ["AGENTS.md"],
                secretsPolicy: .none,
                tmuxSessionPrefix: "toolkit-agents-md",
                linkedTerminalSessionKind: nil
            ),
            ToolkitEntry(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!,
                title: String(localized: "Opencode Prompt Config"),
                category: .promptPacks,
                description: String(localized: "Create `.opencode/opencode.jsonc` with project-level defaults for the OpenCode agent."),
                riskLevel: .low,
                sourceURL: nil,
                docsURL: nil,
                detectScript: "test -f .opencode/opencode.jsonc && echo __PAULLM_TOOLKIT_OK__",
                installScript: "mkdir -p .opencode && cat > .opencode/opencode.jsonc <<'EOF'\n{\n  \"project\": {\n    \"name\": \"\",\n    \"description\": \"\"\n  },\n  \"agents\": {\n    \"default\": {\n      \"model\": \"ollama-cloud/kimi-k2.6\"\n    }\n  }\n}\nEOF",
                verifyScript: "test -f .opencode/opencode.jsonc && echo __PAULLM_TOOLKIT_OK__",
                setupScript: nil,
                uninstallScript: "rm -rf .opencode",
                requiresSudo: false,
                writesTo: [".opencode/opencode.jsonc"],
                secretsPolicy: .none,
                tmuxSessionPrefix: "toolkit-opencode-config",
                linkedTerminalSessionKind: nil
            )
        ]
    }

    // MARK: — Memory Vaults (Slice 3)

    private static var memoryVaultEntries: [ToolkitEntry] {
        [
            ToolkitEntry(
                id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!,
                title: String(localized: "Project Memory Vault"),
                category: .memoryVaults,
                description: String(localized: "Bootstrap `docs/ai/` with context, decisions, runbooks, and testing files."),
                riskLevel: .low,
                sourceURL: nil,
                docsURL: nil,
                detectScript: "test -d docs/ai && echo __PAULLM_TOOLKIT_OK__",
                installScript: "mkdir -p docs/ai && cat > docs/ai/context.md <<'EOF'\n# AI Context\n\n## Architecture\n- Feature-first layout (Domain / Application / Infrastructure / UI).\n- New code stays within its feature subtree.\n\n## Decisions\n- (Add as you go.)\nEOF",
                verifyScript: "test -d docs/ai && test -f docs/ai/context.md && echo __PAULLM_TOOLKIT_OK__",
                setupScript: nil,
                uninstallScript: "rm -rf docs/ai",
                requiresSudo: false,
                writesTo: ["docs/ai/context.md", "docs/ai/decisions.md", "docs/ai/runbooks.md", "docs/ai/testing.md"],
                secretsPolicy: .none,
                tmuxSessionPrefix: "toolkit-memory-vault",
                linkedTerminalSessionKind: nil
            )
        ]
    }
}
