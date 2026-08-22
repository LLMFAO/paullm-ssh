import Foundation
import Testing
@testable import paullm_ssh

struct ToolkitCatalogTests {
    @Test
    func catalogContainsAllExpectedAICliEntries() {
        let entries = ToolkitCatalog.entries
        #expect(entries.contains { $0.title == "Claude Code" })
        #expect(entries.contains { $0.title == "Codex CLI" })
        #expect(entries.contains { $0.title == "OpenCode CLI" })
        #expect(entries.contains { $0.title == "Antigravity CLI" })
        #expect(entries.contains { $0.title == "Aider" })
        #expect(entries.contains { $0.title == "Goose" })
    }

    @Test
    func catalogContainsSkillAndMemoryVaultEntries() {
        let entries = ToolkitCatalog.entries
        #expect(entries.contains { $0.title == "Project AGENTS.md" })
        #expect(entries.contains { $0.title == "Opencode Prompt Config" })
        #expect(entries.contains { $0.title == "Project Memory Vault" })
    }

    @Test
    func entryLinkedToTerminalSessionKindCanBeResolved() {
        let claudeEntry = ToolkitCatalog.entry(for: .claude)
        #expect(claudeEntry != nil)
        #expect(claudeEntry?.title == "Claude Code")
        #expect(claudeEntry?.linkedTerminalSessionKind == .claude)

        let codexEntry = ToolkitCatalog.entry(for: .codex)
        #expect(codexEntry != nil)
        #expect(codexEntry?.title == "Codex CLI")
        #expect(codexEntry?.linkedTerminalSessionKind == .codex)

        let opencodeEntry = ToolkitCatalog.entry(for: .opencode)
        #expect(opencodeEntry != nil)
        #expect(opencodeEntry?.title == "OpenCode CLI")
        #expect(opencodeEntry?.linkedTerminalSessionKind == .opencode)

        let antigravityEntry = ToolkitCatalog.entry(for: .antigravity)
        #expect(antigravityEntry != nil)
        #expect(antigravityEntry?.title == "Antigravity CLI")
        #expect(antigravityEntry?.linkedTerminalSessionKind == .antigravity)
    }

    @Test
    func entryByUUIDIsStable() {
        let entries = ToolkitCatalog.entries
        for entry in entries {
            let resolved = ToolkitCatalog.entry(for: entry.id)
            #expect(resolved?.id == entry.id)
        }
    }

    @Test
    func aiCliEntriesHaveDetectAndVerifyScripts() {
        let aiEntries = ToolkitCatalog.entries.filter { $0.category == .aiCLIs }
        for entry in aiEntries {
            #expect(!entry.detectScript.isEmpty, "\(entry.title) missing detect script")
            #expect(!entry.installScript.isEmpty, "\(entry.title) missing install script")
            #expect(!entry.verifyScript.isEmpty, "\(entry.title) missing verify script")
            #expect(entry.detectScript.contains("__PAULLM_TOOLKIT_OK__"), "\(entry.title) detect missing marker")
            #expect(entry.verifyScript.contains("__PAULLM_TOOLKIT_OK__"), "\(entry.title) verify missing marker")
        }
    }

    @Test
    func antigravityHasHighRiskLevel() {
        let entry = ToolkitCatalog.entry(for: .antigravity)
        #expect(entry?.riskLevel == .high)
    }

    @Test
    func aiderHasLowRiskLevel() {
        let entry = ToolkitCatalog.entries.first { $0.title == "Aider" }
        #expect(entry?.riskLevel == .low)
    }

    @Test
    func aiCliSecretsPolicyIsExternalCliOwned() {
        let aiEntries = ToolkitCatalog.entries.filter { $0.category == .aiCLIs }
        for entry in aiEntries {
            #expect(entry.secretsPolicy == .externalCliOwned, "\(entry.title) should not own secrets")
        }
    }

    @Test
    func memoryVaultWritesToDocsAI() {
        let entry = ToolkitCatalog.entries.first { $0.category == .memoryVaults }
        #expect(entry != nil)
        #expect(entry?.writesTo.contains("docs/ai/context.md") == true)
    }
}
