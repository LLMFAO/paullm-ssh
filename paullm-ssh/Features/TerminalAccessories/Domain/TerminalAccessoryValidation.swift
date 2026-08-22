import Foundation

enum TerminalAccessoryValidationError: LocalizedError {
    case customActionLimitReached
    case emptyTitle
    case emptyCommandContent
    case customActionNotFound
    case sessionTypeLimitReached
    case sessionTypeNotFound

    var errorDescription: String? {
        switch self {
        case .customActionLimitReached:
            return String(
                format: String(localized: "You can create up to %lld custom actions."),
                Int64(TerminalAccessoryProfile.maxCustomActions)
            )
        case .emptyTitle:
            return String(localized: "Action title cannot be empty.")
        case .emptyCommandContent:
            return String(localized: "Command content cannot be empty.")
        case .customActionNotFound:
            return String(localized: "Action not found.")
        case .sessionTypeLimitReached:
            return String(
                format: String(localized: "You can create up to %lld session types."),
                Int64(TerminalAccessoryProfile.maxSessionTypes)
            )
        case .sessionTypeNotFound:
            return String(localized: "Session type not found.")
        }
    }
}
