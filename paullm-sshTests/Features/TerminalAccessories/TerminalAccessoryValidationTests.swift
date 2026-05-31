import XCTest
@testable import paullm_ssh

final class TerminalAccessoryValidationTests: XCTestCase {
    func testEmptyTitleErrorMessage() {
        XCTAssertEqual(
            TerminalAccessoryValidationError.emptyTitle.errorDescription,
            "Action title cannot be empty."
        )
    }

    func testCustomActionLimitErrorUsesProfileLimit() {
        XCTAssertEqual(
            TerminalAccessoryValidationError.customActionLimitReached.errorDescription,
            "You can create up to \(TerminalAccessoryProfile.maxCustomActions) custom actions."
        )
    }
}
