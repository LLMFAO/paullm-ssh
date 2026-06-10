import SwiftUI

struct NewTerminalSessionPicker: View {
    let server: Server
    let existingSessions: [TmuxAttachSessionInfo]
    let loadedSessionNames: Set<String>
    let isLoadingExistingSessions: Bool
    let onCancel: () -> Void
    let onCreate: (TerminalSessionStartup) -> Void
    let onAttachExisting: ((TmuxAttachSessionInfo) -> Void)?
    let onSetupToolkit: ((ToolkitEntry) -> Void)?
    /// Resolves the host's default starting directory (e.g. $HOME) for the folder picker.
    let onResolveStartPath: (() async -> String)?
    /// Lists directories on the host at a path (for the folder picker).
    let onLoadDirectories: ((String) async throws -> [RemoteFileEntry])?

    @EnvironmentObject private var preferences: TerminalAccessoryPreferencesManager
    @StateObject private var toolkitManager: ToolkitManager

    @State private var selectedActionID: UUID?
    @State private var isCustomSelected = false
    @State private var isShellSelected = false
    @State private var bypassPermissions = false
    @State private var customTitle = ""
    @State private var customCommand = ""
    @State private var customSessionType = ""
    @State private var selectedEntryForSetup: ToolkitEntry?
    @State private var selectedWorkingDirectory: String?
    @State private var showingDirectoryPicker = false

    init(
        server: Server,
        existingSessions: [TmuxAttachSessionInfo] = [],
        loadedSessionNames: Set<String> = [],
        isLoadingExistingSessions: Bool = false,
        onCancel: @escaping () -> Void,
        onCreate: @escaping (TerminalSessionStartup) -> Void,
        onAttachExisting: ((TmuxAttachSessionInfo) -> Void)? = nil,
        onSetupToolkit: ((ToolkitEntry) -> Void)? = nil,
        onResolveStartPath: (() async -> String)? = nil,
        onLoadDirectories: ((String) async throws -> [RemoteFileEntry])? = nil,
        toolkitManager: ToolkitManager? = nil
    ) {
        self.server = server
        self.existingSessions = existingSessions
        self.loadedSessionNames = loadedSessionNames
        self.isLoadingExistingSessions = isLoadingExistingSessions
        self.onCancel = onCancel
        self.onCreate = onCreate
        self.onAttachExisting = onAttachExisting
        self.onSetupToolkit = onSetupToolkit
        self.onResolveStartPath = onResolveStartPath
        self.onLoadDirectories = onLoadDirectories
        self._toolkitManager = StateObject(wrappedValue: toolkitManager ?? ToolkitManager(server: server))
    }

    private var canPickDirectory: Bool {
        onLoadDirectories != nil && onResolveStartPath != nil
    }

    private var selectedDefinition: TerminalStartupActionDefinition? {
        TerminalSessionStartupDefaults.definition(for: selectedActionID)
    }

    private var selectedSupportsBypass: Bool {
        !isCustomSelected && selectedDefinition?.bypassPermissionsCommand != nil
    }

    private var selectedCommandPreview: String? {
        if let selectedDefinition {
            return resolvedCommand(for: selectedDefinition, bypassPermissions: bypassPermissions)
        }
        return nil
    }

    private var canStart: Bool {
        if isCustomSelected {
            return !customCommand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    var body: some View {
        NavigationStack {
            List {
                if isLoadingExistingSessions && existingSessions.isEmpty {
                    Section(String(localized: "Existing Sessions")) {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(String(localized: "Looking for sessions…"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if !existingSessions.isEmpty {
                    Section(String(localized: "Existing Sessions")) {
                        ForEach(existingSessions) { existingSessionRow($0) }
                    }
                }

                Section(String(localized: "New Session")) {
                    sessionOptionRow(
                        title: TerminalSessionKind.tmux.displayName,
                        subtitle: String(localized: "Attach or create a tmux session"),
                        kind: .tmux,
                        isSelected: selectedActionID == nil && !isCustomSelected && !isShellSelected
                    ) {
                        selectedActionID = nil
                        isCustomSelected = false
                        isShellSelected = false
                        bypassPermissions = false
                    }

                    sessionOptionRow(
                        title: TerminalSessionKind.shell.displayName,
                        subtitle: String(localized: "Plain SSH shell, no tmux"),
                        kind: .shell,
                        isSelected: isShellSelected
                    ) {
                        selectedActionID = nil
                        isCustomSelected = false
                        isShellSelected = true
                        bypassPermissions = false
                    }

                    ForEach(TerminalSessionStartupDefaults.definitions) { definition in
                        aiCLISessionRow(definition: definition)
                    }

                    sessionOptionRow(
                        title: TerminalSessionKind.custom.displayName,
                        subtitle: customCommandPreview,
                        kind: .custom,
                        isSelected: isCustomSelected
                    ) {
                        selectedActionID = nil
                        isCustomSelected = true
                        isShellSelected = false
                        bypassPermissions = false
                    }
                }

                if canPickDirectory {
                    Section(String(localized: "Start In")) {
                        Button {
                            showingDirectoryPicker = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(selectedWorkingDirectory.map(folderName) ?? String(localized: "Home"))
                                        .foregroundStyle(.primary)
                                    Text(selectedWorkingDirectory ?? String(localized: "Default home directory"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if selectedWorkingDirectory != nil {
                            Button(String(localized: "Reset to Home")) {
                                selectedWorkingDirectory = nil
                            }
                            .font(.subheadline)
                        }
                    }
                }

                if selectedSupportsBypass {
                    Section {
                        Toggle("Skip permission checks", isOn: $bypassPermissions)
                    } footer: {
                        if let selectedCommandPreview {
                            Text(selectedCommandPreview)
                                .font(.caption)
                                .textSelection(.enabled)
                        }
                    }
                }

                if isCustomSelected {
                    Section {
                        TextField("Name", text: $customTitle)
                        TextField("Command", text: $customCommand)
                        TextField("Session type", text: $customSessionType)
                    } footer: {
                        Text(customSessionFooter)
                    }
                }
            }
            .navigationTitle(String(format: String(localized: "New Session: %@"), server.name))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        onCreate(resolvedStartup())
                    }
                    .disabled(!canStart)
                }
            }
            .sheet(isPresented: $showingDirectoryPicker) {
                if let onResolveStartPath, let onLoadDirectories {
                    RemoteDirectoryPickerSheet(
                        resolveStartPath: {
                            if let dir = selectedWorkingDirectory { return dir }
                            return await onResolveStartPath()
                        },
                        loadDirectories: onLoadDirectories,
                        onCancel: { showingDirectoryPicker = false },
                        onChoose: { path in
                            selectedWorkingDirectory = path
                            showingDirectoryPicker = false
                        }
                    )
                }
            }
        }
    }

    private func folderName(_ path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != "/" else { return String(localized: "Root") }
        let name = (trimmed as NSString).lastPathComponent
        return name.isEmpty ? trimmed : name
    }

    private func existingSessionRow(_ info: TmuxAttachSessionInfo) -> some View {
        let isLoaded = loadedSessionNames.contains(info.name)
        return Button {
            onAttachExisting?(info)
        } label: {
            HStack(spacing: 12) {
                TerminalSessionKindIcon(kind: info.startup?.kind ?? .tmux)
                    .foregroundStyle(.secondary)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(info.startup?.displayTitle ?? info.name)
                        .foregroundStyle(.primary)
                    Text(existingSessionDetail(info))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if isLoaded {
                    Text(String(localized: "Loaded"))
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.15), in: Capsule())
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func existingSessionDetail(_ info: TmuxAttachSessionInfo) -> String {
        var parts: [String] = [info.name]
        let windowFormat = String(localized: "%d windows")
        parts.append(String(format: windowFormat, info.windowCount))
        if let currentPath = info.currentPath {
            parts.append(currentPath)
        }
        if info.attachedClients > 0 {
            parts.append(String(localized: "attached"))
        }
        return parts.joined(separator: " · ")
    }

    private func sessionOptionRow(
        title: String,
        subtitle: String,
        kind: TerminalSessionKind,
        isSelected: Bool,
        onSelect: @escaping () -> Void
    ) -> some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                TerminalSessionKindIcon(kind: kind)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func resolvedStartup() -> TerminalSessionStartup {
        var startup: TerminalSessionStartup
        if isShellSelected {
            startup = .shell
        } else if isCustomSelected {
            startup = resolvedCustomStartup()
        } else if let selectedDefinition {
            startup = TerminalSessionStartupDefaults.startup(
                for: selectedDefinition,
                actionCommand: customAction(for: selectedDefinition)?.commandContent,
                bypassPermissions: bypassPermissions
            )
        } else {
            startup = .tmux
        }
        startup.workingDirectory = selectedWorkingDirectory
        return startup
    }

    private func resolvedCommand(
        for definition: TerminalStartupActionDefinition,
        bypassPermissions: Bool
    ) -> String {
        TerminalSessionStartupDefaults.startup(
            for: definition,
            actionCommand: customAction(for: definition)?.commandContent,
            bypassPermissions: bypassPermissions
        ).command ?? definition.baseCommand
    }

    private func customAction(for definition: TerminalStartupActionDefinition) -> TerminalAccessoryCustomAction? {
        preferences.customAction(for: definition.id)
    }

    private var customCommandPreview: String {
        let command = customCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        if command.isEmpty {
            return String(localized: "Run any command inside a named tmux session")
        }
        let prefix = resolvedCustomSessionPrefix() ?? "custom"
        return "\(prefix)-1: \(command)"
    }

    private var customSessionFooter: String {
        let prefix = resolvedCustomSessionPrefix() ?? "custom"
        return String(format: String(localized: "Sessions will be created as %@-1, %@-2, and so on."), prefix, prefix)
    }

    private func resolvedCustomStartup() -> TerminalSessionStartup {
        let command = customCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = resolvedCustomSessionPrefix()
        let title = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return .custom(
            displayTitle: title.isEmpty ? resolvedCustomTitle(prefix: prefix, command: command) : title,
            command: command,
            sessionNamePrefix: prefix
        )
    }

    private func resolvedCustomSessionPrefix() -> String? {
        if let explicit = TerminalSessionStartup.sanitizedSessionNamePrefix(customSessionType) {
            return explicit
        }
        if let commandPrefix = TerminalSessionStartup.sanitizedSessionNamePrefix(firstCommandToken(in: customCommand)) {
            return commandPrefix
        }
        return TerminalSessionStartup.sanitizedSessionNamePrefix(customTitle)
    }

    private func resolvedCustomTitle(prefix: String?, command: String) -> String {
        if let prefix, !prefix.isEmpty {
            return prefix
        }
        guard !command.isEmpty else {
            return TerminalSessionKind.custom.displayName
        }
        return firstCommandToken(in: command) ?? TerminalSessionKind.custom.displayName
    }

    private func firstCommandToken(in command: String) -> String? {
        guard let token = command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
            .first
        else { return nil }
        let string = String(token)
        let lastPathComponent = (string as NSString).lastPathComponent
        return lastPathComponent.isEmpty ? string : lastPathComponent
    }

    private func aiCLISessionRow(definition: TerminalStartupActionDefinition) -> some View {
        let isSelected = selectedActionID == definition.id && !isCustomSelected
        let toolkitStatus = toolkitManager.status(for: definition.kind)

        return Button {
            selectedActionID = definition.id
            isCustomSelected = false
            isShellSelected = false
            if definition.bypassPermissionsCommand == nil {
                bypassPermissions = false
            }
        } label: {
            HStack(spacing: 12) {
                TerminalSessionKindIcon(kind: definition.kind)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 3) {
                    Text(definition.title)
                        .foregroundStyle(.primary)
                    Text(resolvedCommand(for: definition, bypassPermissions: bypassPermissions))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                if toolkitStatus == .missing && onSetupToolkit != nil {
                    Button("Set up") {
                        if let entry = ToolkitCatalog.entry(for: definition.kind) {
                            onSetupToolkit?(entry)
                        }
                    }
                    .font(.caption.weight(.medium))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
