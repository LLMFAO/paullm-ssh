import SwiftUI

struct NewTerminalSessionPicker: View {
    let server: Server
    let onCancel: () -> Void
    let onCreate: (TerminalSessionStartup) -> Void

    @EnvironmentObject private var preferences: TerminalAccessoryPreferencesManager

    @State private var selectedActionID: UUID?
    @State private var bypassPermissions = false

    private var selectedDefinition: TerminalStartupActionDefinition? {
        TerminalSessionStartupDefaults.definition(for: selectedActionID)
    }

    private var selectedSupportsBypass: Bool {
        selectedDefinition?.bypassPermissionsCommand != nil
    }

    private var selectedCommandPreview: String? {
        if let selectedDefinition {
            return resolvedCommand(for: selectedDefinition, bypassPermissions: bypassPermissions)
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    sessionOptionRow(
                        title: TerminalSessionKind.tmux.displayName,
                        subtitle: String(localized: "Attach or create a tmux session"),
                        iconSystemName: TerminalSessionKind.tmux.iconSystemName,
                        isSelected: selectedActionID == nil
                    ) {
                        selectedActionID = nil
                        bypassPermissions = false
                    }

                    ForEach(TerminalSessionStartupDefaults.definitions) { definition in
                        sessionOptionRow(
                            title: definition.title,
                            subtitle: resolvedCommand(for: definition, bypassPermissions: bypassPermissions),
                            iconSystemName: definition.kind.iconSystemName,
                            isSelected: selectedActionID == definition.id
                        ) {
                            selectedActionID = definition.id
                            if definition.bypassPermissionsCommand == nil {
                                bypassPermissions = false
                            }
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
                }
            }
        }
    }

    private func sessionOptionRow(
        title: String,
        subtitle: String,
        iconSystemName: String,
        isSelected: Bool,
        onSelect: @escaping () -> Void
    ) -> some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: iconSystemName)
                    .font(.system(size: 18, weight: .semibold))
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
        guard let selectedDefinition else {
            return .tmux
        }
        return TerminalSessionStartupDefaults.startup(
            for: selectedDefinition,
            actionCommand: customAction(for: selectedDefinition)?.commandContent,
            bypassPermissions: bypassPermissions
        )
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
}
