import Foundation

/// A curated catalog entry for a remote tool, skill, prompt pack, or memory vault template.
struct ToolkitEntry: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let category: ToolkitCategory
    let description: String
    let riskLevel: ToolkitRiskLevel
    let sourceURL: URL?
    let docsURL: URL?

    /// Silent detection script — should print a success marker on stdout when the tool is present.
    let detectScript: String
    /// Installation script — shown to the user before running. May use package managers.
    let installScript: String
    /// Verification script — should print a success marker on stdout when the tool works.
    let verifyScript: String
    /// Optional post-install setup (auth, config init). The CLI owns its own secrets.
    let setupScript: String?
    /// Optional uninstall script.
    let uninstallScript: String?

    let requiresSudo: Bool
    /// Paths this script writes to (for trust-warning generation).
    let writesTo: [String]
    let secretsPolicy: ToolkitSecretsPolicy

    /// Prefix for the tmux session name, e.g. "toolkit-opencode".
    let tmuxSessionPrefix: String

    /// Optional link to an existing `TerminalSessionKind` so the New Session picker can
    /// cross-reference this entry for the repair shortcut.
    let linkedTerminalSessionKind: TerminalSessionKind?
}
