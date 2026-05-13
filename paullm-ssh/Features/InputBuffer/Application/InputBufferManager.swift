import Foundation
import Combine

@MainActor
final class InputBufferManager: ObservableObject {
    static let shared = InputBufferManager()

    @Published var isPresented = false
    @Published var draftText = ""

    private let draftKey = "inputBufferDraft"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.draftText = defaults.string(forKey: draftKey) ?? ""
    }

    func appendText(_ text: String) {
        draftText += text
        saveDraft()
    }

    func setDraftText(_ text: String) {
        draftText = text
        saveDraft()
    }

    func sendAndClear(via sender: (String) -> Void, withNewline: Bool = true) {
        let text = withNewline ? draftText + "\n" : draftText
        sender(text)
        draftText = ""
        defaults.removeObject(forKey: draftKey)
        isPresented = false
    }

    func clearDraft() {
        draftText = ""
        defaults.removeObject(forKey: draftKey)
    }

    private func saveDraft() {
        defaults.set(draftText, forKey: draftKey)
    }
}

extension Notification.Name {
    static let openInputBuffer = Notification.Name("paullm.openInputBuffer")
}
