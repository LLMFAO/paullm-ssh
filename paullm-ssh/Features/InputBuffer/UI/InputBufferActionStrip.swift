import SwiftUI

struct InputBufferActionStrip: View {
    var onVoice: () -> Void
    var onPaste: () -> Void
    var onSnippet: () -> Void
    var onNewline: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onVoice) {
                Label("Voice", systemImage: "mic.fill")
            }
            Button(action: onPaste) {
                Label("Paste", systemImage: "doc.on.clipboard")
            }
            Button(action: onSnippet) {
                Label("Snippet", systemImage: "text.quote")
            }
            Button(action: onNewline) {
                Label("Newline", systemImage: "return")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
