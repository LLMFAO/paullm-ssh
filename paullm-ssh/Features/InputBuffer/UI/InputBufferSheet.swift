import SwiftUI

struct InputBufferSheet: View {
    @StateObject private var manager = InputBufferManager.shared
    var onSend: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                InputBufferTextView(text: $manager.draftText, onCmdReturn: {
                    manager.sendAndClear(via: onSend, withNewline: true)
                })
                .padding()

                HStack {
                    Spacer()
                    Text("\(manager.draftText.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.trailing)
                }

                InputBufferActionStrip(
                    onVoice: { /* TODO: wire voice transcription to buffer */ },
                    onPaste: { pasteFromClipboard() },
                    onSnippet: { /* TODO: wire snippet picker to buffer */ },
                    onNewline: { manager.appendText("\n") }
                )
            }
            .navigationTitle("Compose & Send")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        manager.isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        manager.sendAndClear(via: onSend, withNewline: true)
                    }
                    .disabled(manager.draftText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func pasteFromClipboard() {
        #if os(iOS)
        if let string = UIPasteboard.general.string {
            manager.appendText(string)
        }
        #elseif os(macOS)
        if let string = NSPasteboard.general.string(forType: .string) {
            manager.appendText(string)
        }
        #endif
    }
}
