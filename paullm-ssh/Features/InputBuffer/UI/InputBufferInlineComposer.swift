import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct InputBufferInlineComposer: View {
    @StateObject private var manager = InputBufferManager.shared
    @FocusState private var isEditorFocused: Bool
    @AppStorage("terminalComposeSendMode") private var sendModeRaw = TerminalSendMode.enter.rawValue

    let canSend: Bool
    var onVoice: (() -> Void)?
    var onSend: (String, TerminalSendMode) -> Void

    private var sendMode: TerminalSendMode {
        TerminalSendMode(rawValue: sendModeRaw) ?? .enter
    }

    private var hasDraft: Bool {
        !manager.draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 4) {
            // Start as a single line and grow with the draft so the composer stays
            // out of the way until there's something to compose.
            InputBufferTextView(text: $manager.draftText, focused: $isEditorFocused, onCmdReturn: send)
                .frame(minHeight: 30, maxHeight: 110)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            actionRow
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
        .onAppear {
            // Focusing synchronously in onAppear is unreliable: the editor isn't in
            // the responder hierarchy yet, so the keyboard/focus (and the resulting
            // layout of this action row) doesn't engage until some later event — which
            // is why the controls stayed hidden until you tapped the terminal. Defer a
            // beat so focus reliably takes and the bar lays out immediately.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isEditorFocused = true
            }
        }
    }

    private var closeButton: some View {
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                manager.isPresented = false
            }
        } label: {
            Image(systemName: "chevron.down")
        }
        .accessibilityLabel("Close composer")
    }

    private var actionRow: some View {
        // Pin the primary controls (mic, send mode, Send) so they stay visible on
        // narrow screens; let the secondary actions scroll horizontally instead of
        // pushing Send off the trailing edge.
        HStack(spacing: 10) {
            closeButton

            if let onVoice {
                Button(action: onVoice) {
                    Image(systemName: "mic.fill")
                }
                .accessibilityLabel("Dictate to composer")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
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

                    Button("Clear", role: .destructive) {
                        manager.clearDraft()
                        isEditorFocused = true
                    }
                    .disabled(manager.draftText.isEmpty)
                }
                .padding(.trailing, 4)
            }

            sendModeMenu

            Button("Send") {
                send()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!hasDraft || !canSend)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    private var sendModeMenu: some View {
        Menu {
            Picker("Send mode", selection: $sendModeRaw) {
                ForEach(TerminalSendMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .tag(mode.rawValue)
                }
            }
        } label: {
            // Text label (not the mode icon) so this reads as a send-mode
            // selector rather than a second "return" key next to the newline
            // button.
            HStack(spacing: 3) {
                Text(sendMode.title)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
        .accessibilityLabel("Send mode: \(sendMode.title)")
    }

    private func send() {
        guard hasDraft, canSend else { return }
        let mode = sendMode
        manager.sendAndClear(via: { onSend($0, mode) }, withNewline: false)
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
