import SwiftUI

struct TmuxAttachPromptSheet: View {
    let prompt: TmuxAttachPrompt
    /// Confirms the user's choice. The optional path is the start directory chosen
    /// for a newly created session (`.createManaged`); it is `nil` otherwise.
    let onConfirm: (TmuxAttachSelection, String?) -> Void
    /// Resolves the initial directory to browse from (e.g. $HOME). When both this
    /// and `loadDirectories` are provided, a "Start in" chooser is shown for new
    /// sessions.
    var resolveStartPath: (() async -> String)? = nil
    /// Lists folders at a path for the directory chooser.
    var loadDirectories: ((String) async throws -> [RemoteFileEntry])? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var selectedWorkingDirectory: String?
    @State private var showingDirectoryPicker = false

    private var hasSessions: Bool {
        !prompt.existingSessions.isEmpty
    }

    private var canChooseDirectory: Bool {
        resolveStartPath != nil && loadDirectories != nil
    }


    var body: some View {
        #if os(iOS)
        NavigationStack {
            contentBody
            .navigationTitle("Choose tmux session")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actionRow
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .sheet(isPresented: $showingDirectoryPicker) {
                directoryPickerSheet
            }
        }
        #else
        VStack(spacing: 0) {
            macHeader

            Divider()

            contentBody
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            actionRow
        }
        .frame(minWidth: 520, minHeight: 500)
        .sheet(isPresented: $showingDirectoryPicker) {
            directoryPickerSheet
        }
        #endif
    }

    #if os(macOS)
    private var macHeader: some View {
        DialogSheetHeader(title: "Choose tmux session") {
            dismiss()
        }
    }
    #endif

    @ViewBuilder
    private var contentBody: some View {
        if hasSessions {
            #if os(macOS)
            Form {
                Section {
                    ForEach(prompt.existingSessions) { session in
                        Button {
                            confirm(.attachExisting(sessionName: session.name))
                        } label: {
                            HStack(spacing: 10) {
                                TerminalSessionKindBadge(startup: session.startup, showTitle: false)
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.name)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Text(sessionDetailsText(for: session))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Existing sessions")
                } footer: {
                    Text("Select a session to attach immediately.")
                }
            }
            .formStyle(.grouped)
            #else
            List {
                Section {
                    ForEach(prompt.existingSessions) { session in
                        Button {
                            confirm(.attachExisting(sessionName: session.name))
                        } label: {
                            HStack(spacing: 10) {
                                TerminalSessionKindBadge(startup: session.startup, showTitle: false)
                                    .foregroundStyle(.secondary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.name)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Text(sessionDetailsText(for: session))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Existing sessions")
                } footer: {
                    Text("Select a session to attach immediately.")
                }
            }
            .listStyle(.insetGrouped)
            #endif
        } else {
            VStack {
                Spacer(minLength: 0)
                noSessionsView
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
        }
    }

    private func sessionDetailsText(for session: TmuxAttachSessionInfo) -> String {
        let attachment = session.attachedClients > 0
            ? String(localized: "Attached")
            : String(localized: "Detached")

        let clients: String
        if session.attachedClients == 1 {
            clients = String(localized: "1 client")
        } else {
            clients = String(
                format: String(localized: "%lld clients"),
                Int64(session.attachedClients)
            )
        }

        let windows: String
        if session.windowCount == 1 {
            windows = String(localized: "1 window")
        } else {
            windows = String(
                format: String(localized: "%lld windows"),
                Int64(session.windowCount)
            )
        }

        var parts = [attachment, clients, windows]
        if let currentPath = session.currentPath {
            parts.append(currentPath)
        }
        return parts.joined(separator: " • ")
    }

    private var actionRow: some View {
        #if os(macOS)
        VStack(spacing: 10) {
            if canChooseDirectory {
                startInControl
                    .frame(maxWidth: 460)
            }
            HStack(spacing: 12) {
                Button {
                    confirm(.skipTmux)
                } label: {
                    Label("Skip tmux", systemImage: "arrow.right.circle")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 38)
                        .font(.callout.weight(.semibold))
                        .imageScale(.small)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 220)

                Button {
                    confirm(.createManaged)
                } label: {
                    Label("New session", systemImage: "plus.rectangle.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 38)
                        .font(.callout.weight(.semibold))
                        .imageScale(.small)
                        .foregroundStyle(.white)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.accentColor)
                        )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 220)
            }
            .frame(maxWidth: 460)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
        #else
        VStack(spacing: 10) {
            if canChooseDirectory {
                startInControl
                Divider()
            }

            Button {
                confirm(.createManaged)
            } label: {
                Label("New session", systemImage: "plus.rectangle.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.accentColor)
                    )
            }
            .buttonStyle(.plain)

            Button {
                confirm(.skipTmux)
            } label: {
                Label("Skip tmux", systemImage: "arrow.right.circle")
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        #endif
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            #if os(macOS)
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                )
            #else
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
            #endif
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }

    @ViewBuilder
    private var noSessionsView: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView(
                "No tmux sessions found",
                systemImage: "terminal",
                description: Text("Create a new session, or continue without tmux.")
            )
        } else {
            VStack(spacing: 8) {
                Label("No tmux sessions found", systemImage: "terminal")
                    .font(.headline)
                Text("Create a new session, or continue without tmux.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
        }
    }

    private func confirm(_ selection: TmuxAttachSelection) {
        let workingDirectory: String?
        if case .createManaged = selection {
            workingDirectory = selectedWorkingDirectory
        } else {
            workingDirectory = nil
        }
        onConfirm(selection, workingDirectory)
        dismiss()
    }

    @ViewBuilder
    private var startInControl: some View {
        if canChooseDirectory {
            Button {
                showingDirectoryPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "folder")
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start in")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(selectedWorkingDirectory ?? String(localized: "Default (home directory)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var directoryPickerSheet: some View {
        if let resolveStartPath, let loadDirectories {
            RemoteDirectoryPickerSheet(
                resolveStartPath: {
                    if let selectedWorkingDirectory { return selectedWorkingDirectory }
                    return await resolveStartPath()
                },
                loadDirectories: loadDirectories,
                onCancel: { showingDirectoryPicker = false },
                onChoose: { path in
                    selectedWorkingDirectory = path
                    showingDirectoryPicker = false
                }
            )
        }
    }
}
