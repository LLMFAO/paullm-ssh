import Foundation
import Testing
@testable import paullm_ssh

struct ServerMoveSupportTests {
    private func makeWorkspace(
        id: UUID = UUID(),
        name: String,
        order: Int,
        environments: [ServerEnvironment] = ServerEnvironment.builtInEnvironments
    ) -> Workspace {
        Workspace(
            id: id,
            name: name,
            order: order,
            environments: environments
        )
    }

    @Test
    func lockedSourceCanMoveIntoUnlockedWorkspaceOnFreePlan() {
        let unlocked = makeWorkspace(name: "Primary", order: 0)
        let locked = makeWorkspace(name: "Archive", order: 1)

        let allowedDestinations = ServerMoveSupport.allowedDestinationIDs(
            sourceWorkspaceId: locked.id,
            workspacesInOrder: [unlocked, locked]
        )

        #expect(allowedDestinations == Set([unlocked.id]))
    }

    @Test
    func freePlanDoesNotOfferLockedWorkspaceAsDestination() {
        let unlockedA = makeWorkspace(name: "Primary", order: 0)
        let locked = makeWorkspace(name: "Archive", order: 1)
        let unlockedB = makeWorkspace(name: "Shared", order: 2)

        let allowedDestinations = ServerMoveSupport.allowedDestinationIDs(
            sourceWorkspaceId: unlockedA.id,
            workspacesInOrder: [unlockedA, locked, unlockedB]
        )

        #expect(allowedDestinations == Set([locked.id, unlockedB.id]))
    }

    @Test
    func resolveEnvironmentKeepsPreferredEnvironmentWhenDestinationContainsIt() {
        let custom = ServerEnvironment(
            id: UUID(),
            name: "Preview",
            shortName: "Prev",
            colorHex: "#FF00AA"
        )
        let destination = makeWorkspace(
            name: "Destination",
            order: 0,
            environments: ServerEnvironment.builtInEnvironments + [custom]
        )

        let resolved = ServerMoveSupport.resolveEnvironment(
            currentEnvironment: .production,
            preferredEnvironment: custom,
            destination: destination
        )

        #expect(resolved.id == custom.id)
    }

    @Test
    func resolveEnvironmentFallsBackToProductionWhenCustomEnvironmentIsMissing() {
        let custom = ServerEnvironment(
            id: UUID(),
            name: "QA Blue",
            shortName: "QAB",
            colorHex: "#3366FF"
        )
        let destination = makeWorkspace(name: "Destination", order: 0)

        let resolved = ServerMoveSupport.resolveEnvironment(
            currentEnvironment: custom,
            destination: destination
        )

        #expect(resolved.id == ServerEnvironment.production.id)
    }
}
