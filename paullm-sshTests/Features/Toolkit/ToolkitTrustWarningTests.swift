import Foundation
import Testing
@testable import paullm_ssh

struct ToolkitTrustWarningTests {
    @Test
    func curlPipeShellDetected() {
        let entry = ToolkitEntry(
            id: UUID(),
            title: "Test",
            category: .aiCLIs,
            description: "Test",
            riskLevel: .medium,
            sourceURL: nil,
            docsURL: nil,
            detectScript: "",
            installScript: "curl -fsSL https://example.com | bash",
            verifyScript: "",
            setupScript: nil,
            uninstallScript: nil,
            requiresSudo: false,
            writesTo: [],
            secretsPolicy: .none,
            tmuxSessionPrefix: "test",
            linkedTerminalSessionKind: nil
        )
        let warning = ToolkitTrustWarning.compute(for: entry)
        #expect(warning.curlPipeShell == true)
        #expect(warning.hasAnyWarning == true)
    }

    @Test
    func sudoDetectedFromScript() {
        let entry = ToolkitEntry(
            id: UUID(),
            title: "Test",
            category: .aiCLIs,
            description: "Test",
            riskLevel: .medium,
            sourceURL: nil,
            docsURL: nil,
            detectScript: "",
            installScript: "sudo apt-get install foo",
            verifyScript: "",
            setupScript: nil,
            uninstallScript: nil,
            requiresSudo: false,
            writesTo: [],
            secretsPolicy: .none,
            tmuxSessionPrefix: "test",
            linkedTerminalSessionKind: nil
        )
        let warning = ToolkitTrustWarning.compute(for: entry)
        #expect(warning.usesSudo == true)
        #expect(warning.hasAnyWarning == true)
    }

    @Test
    func sudoDetectedFromMetadata() {
        let entry = ToolkitEntry(
            id: UUID(),
            title: "Test",
            category: .aiCLIs,
            description: "Test",
            riskLevel: .medium,
            sourceURL: nil,
            docsURL: nil,
            detectScript: "",
            installScript: "apt-get install foo",
            verifyScript: "",
            setupScript: nil,
            uninstallScript: nil,
            requiresSudo: true,
            writesTo: [],
            secretsPolicy: .none,
            tmuxSessionPrefix: "test",
            linkedTerminalSessionKind: nil
        )
        let warning = ToolkitTrustWarning.compute(for: entry)
        #expect(warning.usesSudo == true)
    }

    @Test
    func shellProfileWriteDetected() {
        let entry = ToolkitEntry(
            id: UUID(),
            title: "Test",
            category: .aiCLIs,
            description: "Test",
            riskLevel: .medium,
            sourceURL: nil,
            docsURL: nil,
            detectScript: "",
            installScript: "echo 'export PATH' >> ~/.bashrc",
            verifyScript: "",
            setupScript: nil,
            uninstallScript: nil,
            requiresSudo: false,
            writesTo: [],
            secretsPolicy: .none,
            tmuxSessionPrefix: "test",
            linkedTerminalSessionKind: nil
        )
        let warning = ToolkitTrustWarning.compute(for: entry)
        #expect(warning.writesShellProfile == true)
    }

    @Test
    func credentialAdjacentPathDetected() {
        let entry = ToolkitEntry(
            id: UUID(),
            title: "Test",
            category: .aiCLIs,
            description: "Test",
            riskLevel: .medium,
            sourceURL: nil,
            docsURL: nil,
            detectScript: "",
            installScript: "",
            verifyScript: "",
            setupScript: nil,
            uninstallScript: nil,
            requiresSudo: false,
            writesTo: ["~/.ssh/config"],
            secretsPolicy: .none,
            tmuxSessionPrefix: "test",
            linkedTerminalSessionKind: nil
        )
        let warning = ToolkitTrustWarning.compute(for: entry)
        #expect(warning.credentialAdjacentPath == true)
    }

    @Test
    func lowRiskEntryHasNoWarnings() {
        let entry = ToolkitEntry(
            id: UUID(),
            title: "Test",
            category: .aiCLIs,
            description: "Test",
            riskLevel: .low,
            sourceURL: nil,
            docsURL: nil,
            detectScript: "",
            installScript: "pip install foo",
            verifyScript: "",
            setupScript: nil,
            uninstallScript: nil,
            requiresSudo: false,
            writesTo: [],
            secretsPolicy: .none,
            tmuxSessionPrefix: "test",
            linkedTerminalSessionKind: nil
        )
        let warning = ToolkitTrustWarning.compute(for: entry)
        #expect(!warning.hasAnyWarning)
        #expect(!warning.usesSudo)
        #expect(!warning.curlPipeShell)
        #expect(!warning.writesShellProfile)
        #expect(!warning.credentialAdjacentPath)
    }

    @Test
    func antigravityEntryHasCurlPipeWarning() {
        let entry = ToolkitCatalog.entry(for: .antigravity)!
        let warning = ToolkitTrustWarning.compute(for: entry)
        #expect(warning.curlPipeShell == true)
        #expect(warning.hasAnyWarning == true)
    }

    @Test
    func aiderEntryHasNoWarnings() {
        let entry = ToolkitCatalog.entries.first { $0.title == "Aider" }!
        let warning = ToolkitTrustWarning.compute(for: entry)
        #expect(!warning.hasAnyWarning)
    }
}
