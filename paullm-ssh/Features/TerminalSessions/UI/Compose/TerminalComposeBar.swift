//
//  TerminalComposeBar.swift
//  paullm-ssh
//
//  A Termius-style local compose box that sits above the iOS keyboard. Text is
//  drafted, dictated, pasted, and edited locally and only reaches the active SSH
//  terminal session when the user explicitly taps Send.
//

#if os(iOS)
import SwiftUI

struct TerminalComposeBar: View {
    let sessionId: UUID
    @ObservedObject var draftStore: TerminalComposeDraftStore

    @AppStorage("terminalComposeSendMode") private var sendModeRaw = TerminalSendMode.enter.rawValue
    @AppStorage("terminalComposeCollapsed") private var isCollapsed = false
    @FocusState private var isEditorFocused: Bool

    private var sendMode: TerminalSendMode {
        TerminalSendMode(rawValue: sendModeRaw) ?? .enter
    }

    private var draftText: Binding<String> {
        Binding(
            get: { draftStore.draft(for: sessionId) },
            set: { draftStore.setDraft($0, for: sessionId) }
        )
    }

    private var trimmedDraft: String {
        draftStore.draft(for: sessionId).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSend: Bool { !trimmedDraft.isEmpty }

    var body: some View {
        Group {
            if isCollapsed {
                collapsedBar
            } else {
                expandedBar
            }
        }
        .animation(.easeInOut(duration: 0.18), value: isCollapsed)
        .onChange(of: isEditorFocused) { focused in
            draftStore.setEditorFocused(focused, for: sessionId)
        }
        .onDisappear {
            draftStore.setEditorFocused(false, for: sessionId)
        }
    }

    // MARK: - Collapsed

    private var collapsedBar: some View {
        HStack(spacing: 8) {
            Button {
                isCollapsed = false
            } label: {
                Label(String(localized: "Compose"), systemImage: "chevron.up")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            if canSend {
                Text(String(localized: "Draft saved"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .adaptiveGlass()
    }

    // MARK: - Expanded

    private var expandedBar: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                modeMenu

                TextField(
                    String(localized: "Compose locally, then send…"),
                    text: draftText,
                    axis: .vertical
                )
                .lineLimit(1...6)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(false)
                .focused($isEditorFocused)
                .font(.body)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )

                trailingControls
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .adaptiveGlass()
    }

    private var modeMenu: some View {
        Menu {
            Picker(String(localized: "Send mode"), selection: $sendModeRaw) {
                ForEach(TerminalSendMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .tag(mode.rawValue)
                }
            }
            Divider()
            Button {
                isCollapsed = true
            } label: {
                Label(String(localized: "Hide compose box"), systemImage: "chevron.down")
            }
        } label: {
            Image(systemName: sendMode.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 38, height: 38)
                .foregroundStyle(.secondary)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                )
        }
        .accessibilityLabel(String(localized: "Send mode: \(sendMode.title)"))
    }

    private var trailingControls: some View {
        HStack(spacing: 8) {
            if canSend {
                Button(action: clear) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 38, height: 38)
                        .foregroundStyle(.secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.primary.opacity(0.06))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Clear draft"))
            }

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(canSend ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel(String(localized: "Send"))
        }
    }

    // MARK: - Actions

    private func send() {
        let text = draftStore.draft(for: sessionId)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let sent = ConnectionSessionManager.shared.send(text, mode: sendMode, to: sessionId)
        if sent {
            draftStore.clearDraft(for: sessionId)
        }
    }

    private func clear() {
        draftStore.clearDraft(for: sessionId)
    }
}
#endif
