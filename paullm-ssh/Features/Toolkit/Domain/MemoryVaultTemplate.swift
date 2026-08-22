import Foundation

/// Template file entry for a project memory vault.
struct MemoryVaultTemplate: Identifiable, Equatable, Sendable {
    let id: UUID
    let filename: String
    let relativeDirectory: String
    let body: String
    let mergeStrategy: ToolkitMergeStrategy
}

extension MemoryVaultTemplate {
    static var defaultVaultSet: [MemoryVaultTemplate] {
        [
            MemoryVaultTemplate(
                id: UUID(),
                filename: "AGENTS.md",
                relativeDirectory: "",
                body: defaultAgentsMD,
                mergeStrategy: .create
            ),
            MemoryVaultTemplate(
                id: UUID(),
                filename: "context.md",
                relativeDirectory: "docs/ai",
                body: defaultContextMD,
                mergeStrategy: .create
            ),
            MemoryVaultTemplate(
                id: UUID(),
                filename: "decisions.md",
                relativeDirectory: "docs/ai",
                body: defaultDecisionsMD,
                mergeStrategy: .create
            ),
            MemoryVaultTemplate(
                id: UUID(),
                filename: "runbooks.md",
                relativeDirectory: "docs/ai",
                body: defaultRunbooksMD,
                mergeStrategy: .create
            ),
            MemoryVaultTemplate(
                id: UUID(),
                filename: "testing.md",
                relativeDirectory: "docs/ai",
                body: defaultTestingMD,
                mergeStrategy: .create
            )
        ]
    }

    static var opencodeConfigTemplate: MemoryVaultTemplate {
        MemoryVaultTemplate(
            id: UUID(),
            filename: "opencode.jsonc",
            relativeDirectory: ".opencode",
            body: defaultOpencodeConfig,
            mergeStrategy: .create
        )
    }

    static var claudeProjectConfigTemplate: MemoryVaultTemplate {
        MemoryVaultTemplate(
            id: UUID(),
            filename: "CLAUDE.md",
            relativeDirectory: ".claude",
            body: defaultClaudeProjectMD,
            mergeStrategy: .create
        )
    }

    static var codexProjectConfigTemplate: MemoryVaultTemplate {
        MemoryVaultTemplate(
            id: UUID(),
            filename: "codex.md",
            relativeDirectory: ".codex",
            body: defaultCodexProjectMD,
            mergeStrategy: .create
        )
    }
}

// MARK: — Default template bodies

private let defaultAgentsMD = """
# Project Agents

## Context
- Project:
- Stack:
- Repo:

## Agent Rules
- Use atomic commits.
- Prefer explicit dependency injection.
- Keep platform parity unless fixing a platform-specific bug.
- Never apply glass to terminal content (only nav/toolbars).
"""

private let defaultContextMD = """
# AI Context

## Architecture
- Feature-first layout (`Domain` / `Application` / `Infrastructure` / `UI`).
- New code stays within its feature subtree.

## Decisions
- (Add as you go.)

## Runbooks
- (Add as you go.)
"""

private let defaultDecisionsMD = """
# Architecture Decisions

## ADR-001 — Title
- Date: YYYY-MM-DD
- Context:
- Decision:
- Consequences:
"""

private let defaultRunbooksMD = """
# Runbooks

## Setup
1. Clone repo
2. Install deps
3. Build

## Deploy
1. Tag release
2. CI builds
3. Upload
"""

private let defaultTestingMD = """
# Testing Strategy

- Unit tests: `make test`
- Integration tests: `make integration`
- E2E: `make e2e`
"""

private let defaultOpencodeConfig = """
{
  // Opencode project configuration
  "project": {
    "name": "",
    "description": ""
  },
  "agents": {
    "default": {
      "model": "ollama-cloud/kimi-k2.6"
    }
  }
}
"""

private let defaultClaudeProjectMD = """
# Claude Project Config

- Project:
- Stack:
- Style guide:
- Testing:
"""

private let defaultCodexProjectMD = """
# Codex Project Config

- Project:
- Stack:
- Style guide:
- Testing:
"""
