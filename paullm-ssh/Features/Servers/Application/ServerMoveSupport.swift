import Foundation

enum ServerMoveSupport {
    static func allowedDestinationIDs(
        sourceWorkspaceId: UUID,
        workspacesInOrder: [Workspace]
    ) -> Set<UUID> {
        let orderedIDs = workspacesInOrder.map(\.id)
        return Set(orderedIDs.filter { $0 != sourceWorkspaceId })
    }

    static func resolveEnvironment(
        currentEnvironment: ServerEnvironment,
        preferredEnvironment: ServerEnvironment? = nil,
        destination: Workspace
    ) -> ServerEnvironment {
        if let preferredEnvironment,
           let matchedPreferred = destination.environment(withId: preferredEnvironment.id) {
            return matchedPreferred
        }

        if let matchedCurrent = destination.environment(withId: currentEnvironment.id) {
            return matchedCurrent
        }

        if let production = destination.environment(withId: ServerEnvironment.production.id) {
            return production
        }

        return destination.environments.first ?? .production
    }

    static func requiresEnvironmentFallback(
        currentEnvironment: ServerEnvironment,
        destination: Workspace
    ) -> Bool {
        destination.environment(withId: currentEnvironment.id) == nil
    }
}
