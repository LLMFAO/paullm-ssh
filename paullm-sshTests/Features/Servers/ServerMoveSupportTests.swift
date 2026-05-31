import XCTest
@testable import paullm_ssh

final class ServersFeatureMoveSupportTests: XCTestCase {
    func testAllowedDestinationIDsExcludesSourceWorkspace() {
        let source = Workspace(name: "Source")
        let unlocked = Workspace(name: "Unlocked", order: 1)
        let locked = Workspace(name: "Locked", order: 2)

        let destinations = ServerMoveSupport.allowedDestinationIDs(
            sourceWorkspaceId: source.id,
            workspacesInOrder: [source, unlocked, locked]
        )

        XCTAssertEqual(destinations, [unlocked.id, locked.id])
    }

    func testResolveEnvironmentFallsBackToProductionWhenCurrentMissing() {
        let productionOnly = Workspace(
            name: "Prod Only",
            environments: [.production]
        )

        let resolved = ServerMoveSupport.resolveEnvironment(
            currentEnvironment: .staging,
            destination: productionOnly
        )

        XCTAssertEqual(resolved, .production)
    }

    func testRequiresEnvironmentFallbackWhenDestinationDoesNotContainCurrentEnvironment() {
        let workspace = Workspace(name: "Prod Only", environments: [.production])

        XCTAssertTrue(ServerMoveSupport.requiresEnvironmentFallback(currentEnvironment: .staging, destination: workspace))
        XCTAssertFalse(ServerMoveSupport.requiresEnvironmentFallback(currentEnvironment: .production, destination: workspace))
    }
}
