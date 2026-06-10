import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct InputBufferInlineComposer: View {
    @StateObject private var manager = InputBufferManager.shared
    @FocusState private var isEditorFocused: Bool

    let canSend: Bool
    var onVoice: (() -> Void)?
    var onSend: (String) -> Void

    private var hasDraft: Bool {
        !manager.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 8) {
            header

            InputBufferTextView(text: $manager.draftText, onCmdReturn: send)
                .focused($isEditorFocused)
                .frame(minHeight: 72, maxHeight: 150)
                .padding(8)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            actionRow
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
        .onAppear {
            isEditorFocused = true
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("Compose", systemImage: "text.bubble")
                .font(.subheadline.weight(.semibold))

            Spacer(minLength: 8)

            Text("\(manager.draftText.count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                    manager.isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close composer")
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            if let onVoice {
                Button(action: onVoice) {
                    Image(systemName: "mic.fill")
                }
                .accessibilityLabel("Dictate to composer")
            }

            Button(action: pasteFromClipboard) {
                Image(systemName: "doc.on.clipboard")
            }
            .accessibilityLabel("Paste into composer")

            Menu {
                ForEach(Self.snippets) { snippet in
                    Button(snippet.title) {
                        appendSnippet(snippet.body)
                    }
                }
            } label: {
                Image(systemName: "shippingbox")
            }
            .accessibilityLabel("Open toolbox snippets")

            Button {
                manager.appendText("\n")
                isEditorFocused = true
            } label: {
                Image(systemName: "return")
            }
            .accessibilityLabel("Insert newline")

            Spacer(minLength: 8)

            Button("Clear", role: .destructive) {
                manager.clearDraft()
                isEditorFocused = true
            }
            .disabled(manager.draftText.isEmpty)

            Button("Send") {
                send()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasDraft || !canSend)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private func send() {
        guard hasDraft, canSend else { return }
        manager.sendAndClear(via: onSend, withNewline: true)
    }

    private func pasteFromClipboard() {
        #if os(iOS)
        guard let string = UIPasteboard.general.string, !string.isEmpty else { return }
        manager.appendText(string)
        #elseif os(macOS)
        guard let string = NSPasteboard.general.string(forType: .string), !string.isEmpty else { return }
        manager.appendText(string)
        #endif
        isEditorFocused = true
    }

    private func appendSnippet(_ snippet: String) {
        if hasDraft, !manager.draftText.hasSuffix("\n") {
            manager.appendText("\n")
        }
        manager.appendText(snippet)
        isEditorFocused = true
    }

    private static let snippets: [InputBufferSnippet] = [
        InputBufferSnippet(
            title: String(localized: "Review current diff"),
            body: String(localized: "Review the current git diff for bugs, regressions, and missing tests. Lead with findings and include file/line references.")
        ),
        InputBufferSnippet(
            title: String(localized: "Plan the change"),
            body: String(localized: "Before editing, inspect the relevant files and give me a short implementation plan with the files you expect to touch.")
        ),
        InputBufferSnippet(
            title: String(localized: "Summarize project state"),
            body: String(localized: "Summarize the current project state, open risks, and the next concrete actions.")
        )
    ]
}

private struct InputBufferSnippet: Identifiable {
    let id = UUID()
    let title: String
    let body: String
}
