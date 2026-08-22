import Foundation

/// Prompt template for injecting into `AGENTS.md`, `CLAUDE.md`, opencode config, etc.
struct ToolkitPromptTemplate: Identifiable, Equatable, Sendable {
    let id: UUID
    let filename: String
    let relativePath: String
    let body: String
    let mergeStrategy: ToolkitMergeStrategy
}

enum ToolkitMergeStrategy: String, Sendable {
    case create
    case overwrite
    case append
}
