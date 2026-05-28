import XCTest
@testable import paullm_ssh

final class ConnectionViewTabTests: XCTestCase {
    func testFromReturnsKnownTab() {
        XCTAssertEqual(ConnectionViewTab.from(id: "stats"), .stats)
        XCTAssertEqual(ConnectionViewTab.from(id: "terminal"), .terminal)
        XCTAssertEqual(ConnectionViewTab.from(id: "files"), .files)
    }

    func testFromReturnsNilForUnknownTab() {
        XCTAssertNil(ConnectionViewTab.from(id: "unknown"))
    }
}
