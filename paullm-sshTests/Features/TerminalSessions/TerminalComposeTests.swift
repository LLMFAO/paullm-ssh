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

@MainActor
struct TerminalComposeDraftStoreTests {
    @Test
    func storesAndReturnsDraftPerSession() {
        let store = TerminalComposeDraftStore()
        let a = UUID()
        let b = UUID()

        store.setDraft("hello", for: a)
        store.setDraft("world", for: b)

        #expect(store.draft(for: a) == "hello")
        #expect(store.draft(for: b) == "world")
    }

    @Test
    func unknownSessionReturnsEmptyDraft() {
        let store = TerminalComposeDraftStore()
        #expect(store.draft(for: UUID()).isEmpty)
    }

    @Test
    func settingEmptyTextClearsDraft() {
        let store = TerminalComposeDraftStore()
        let id = UUID()
        store.setDraft("draft", for: id)
        store.setDraft("", for: id)
        #expect(store.draft(for: id).isEmpty)
    }

    @Test
    func clearDraftRemovesOnlyThatSession() {
        let store = TerminalComposeDraftStore()
        let a = UUID()
        let b = UUID()
        store.setDraft("a", for: a)
        store.setDraft("b", for: b)

        store.clearDraft(for: a)

        #expect(store.draft(for: a).isEmpty)
        #expect(store.draft(for: b) == "b")
    }

    @Test
    func pruneKeepsOnlyActiveSessions() {
        let store = TerminalComposeDraftStore()
        let keep = UUID()
        let drop = UUID()
        store.setDraft("keep", for: keep)
        store.setDraft("drop", for: drop)

        store.pruneDrafts(keepingSessionIds: [keep])

        #expect(store.draft(for: keep) == "keep")
        #expect(store.draft(for: drop).isEmpty)
    }
}
