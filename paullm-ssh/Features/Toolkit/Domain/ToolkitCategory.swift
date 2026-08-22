import Foundation

enum ToolkitCategory: String, CaseIterable, Identifiable, Sendable {
    case aiCLIs
    case skills
    case promptPacks
    case memoryVaults
    case projectSetup
    case agentWorkflows
    case devTools

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aiCLIs:
            return String(localized: "AI CLIs")
        case .skills:
            return String(localized: "Skills")
        case .promptPacks:
            return String(localized: "Prompt Packs")
        case .memoryVaults:
            return String(localized: "Memory Vaults")
        case .projectSetup:
            return String(localized: "Project Setup")
        case .agentWorkflows:
            return String(localized: "Agent Workflows")
        case .devTools:
            return String(localized: "Dev Tools")
        }
    }
}

enum ToolkitItemStatus: String, Sendable {
    case unknown
    case checking
    case installed
    case missing
    case needsSetup

    var displayName: String {
        switch self {
        case .unknown:
            return String(localized: "Unknown")
        case .checking:
            return String(localized: "Checking…")
        case .installed:
            return String(localized: "Installed")
        case .missing:
            return String(localized: "Not Installed")
        case .needsSetup:
            return String(localized: "Needs Setup")
        }
    }
}

enum ToolkitRiskLevel: String, Sendable {
    case low
    case medium
    case high

    var displayName: String {
        switch self {
        case .low:
            return String(localized: "Low Risk")
        case .medium:
            return String(localized: "Medium Risk")
        case .high:
            return String(localized: "High Risk")
        }
    }
}

enum ToolkitSecretsPolicy: String, Sendable {
    case none
    case userEntered
    case externalCliOwned
}
