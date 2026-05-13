import Foundation

struct InputBufferDraft: Codable {
    var text: String
    var updatedAt: Date

    init(text: String = "", updatedAt: Date = Date()) {
        self.text = text
        self.updatedAt = updatedAt
    }
}
