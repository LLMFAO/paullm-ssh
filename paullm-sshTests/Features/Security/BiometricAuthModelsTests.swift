import XCTest
@testable import paullm-ssh

final class BiometricAuthModelsTests: XCTestCase {
    func testCancelledErrorHasNoDescriptionAndIsMarkedCancellation() {
        let error = BiometricAuthError.cancelled

        XCTAssertNil(error.errorDescription)
        XCTAssertTrue(error.isCancellation)
    }

    func testUnavailableErrorPreservesMessage() {
        let error = BiometricAuthError.unavailable("Unavailable")

        XCTAssertEqual(error.errorDescription, "Unavailable")
        XCTAssertFalse(error.isCancellation)
    }
}
