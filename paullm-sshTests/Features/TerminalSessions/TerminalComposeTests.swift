import Foundation
import Testing
@testable import paullm_ssh

struct TerminalSendModeTests {
    @Test
    func allModesAreRepresented() {
        #expect(TerminalSendMode.allCases.count == 4)
        #expect(TerminalSendMode.allCases.contains(.raw))
        #expect(TerminalSendMode.allCases.contains(.enter))
        #expect(TerminalSendMode.allCases.contains(.pasteSafe))
        #expect(TerminalSendMode.allCases.contains(.agent))
    }

    @Test
    func rawValuesAreStableForPersistence() {
        // These strings are stored via @AppStorage; changing them would silently
        // reset users' selected mode, so pin them.
        #expect(TerminalSendMode.raw.rawValue == "raw")
        #expect(TerminalSendMode.enter.rawValue == "enter")
        #expect(TerminalSendMode.pasteSafe.rawValue == "pasteSafe")
        #expect(TerminalSendMode.agent.rawValue == "agent")
    }

    @Test
    func everyModeHasTitleDetailAndSymbol() {
        for mode in TerminalSendMode.allCases {
            #expect(!mode.title.isEmpty)
            #expect(!mode.detail.isEmpty)
            #expect(!mode.systemImage.isEmpty)
        }
    }

    @Test
    func roundTripsThroughRawValue() {
        for mode in TerminalSendMode.allCases {
            #expect(TerminalSendMode(rawValue: mode.rawValue) == mode)
        }
    }
}
