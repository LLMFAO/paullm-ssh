import SwiftUI

struct SessionTypeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: TerminalAccessoryPreferencesManager

    let sessionType: SavedSessionType?

    @State private var title: String
    @State private var command: String
    @State private var sessionPrefix: String
    @State private var iconSystemName: String
    @State private var errorMessage: String?
    @State private var showingIconPicker = false
    @State private var showingDeleteConfirmation = false

    init(sessionType: SavedSessionType? = nil) {
        self.sessionType = sessionType
        _title = State(initialValue: sessionType?.title ?? "")
        _command = State(initialValue: sessionType?.command ?? "")
        _sessionPrefix = State(initialValue: sessionType?.sessionNamePrefix ?? "")
        _iconSystemName = State(initialValue: sessionType?.iconSystemName ?? SavedSessionType.defaultIconSystemName)
    }

    private var isEditing: Bool {
        sessionType != nil
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (isEditing || preferences.canCreateSessionType)
    }

    private var resolvedIcon: String {
        iconSystemName.isEmpty ? SavedSessionType.defaultIconSystemName : iconSystemName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $title)

                    Button {
                        showingIconPicker = true
                    } label: {
                        HStack {
                            Text("Icon")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: resolvedIcon)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Session Type")
                }

                Section {
                    TextField("Command", text: $command, axis: .vertical)
                        .lineLimit(1...6)
                } header: {
                    Text("Command")
                } footer: {
                    Text("Runs inside a named tmux session when the type is started.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    TextField("Session name prefix (optional)", text: $sessionPrefix)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                } footer: {
                    Text("Leave blank to derive a prefix from the name or command. Sessions are created as prefix-1, prefix-2, and so on.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Text("Avoid storing secrets in commands or names.")
                        .foregroundStyle(.orange)
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Session Type")
                                Spacer()
                            }
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(
                isEditing
                    ? String(localized: "Edit Session Type")
                    : String(localized: "New Session Type")
            )
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingIconPicker) {
                SFSymbolPickerView(selectedSymbol: $iconSystemName, isPresented: $showingIconPicker)
            }
            .alert("Delete Session Type?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    guard let sessionType else { return }
                    preferences.deleteSessionType(id: sessionType.id)
                    dismiss()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    private func save() {
        do {
            if let sessionType {
                try preferences.updateSessionType(
                    id: sessionType.id,
                    title: title,
                    command: command,
                    sessionNamePrefix: sessionPrefix,
                    iconSystemName: resolvedIcon
                )
            } else {
                _ = try preferences.createSessionType(
                    title: title,
                    command: command,
                    sessionNamePrefix: sessionPrefix,
                    iconSystemName: resolvedIcon
                )
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
