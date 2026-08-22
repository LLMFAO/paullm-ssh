import SwiftUI

struct SessionTypesSettingsView: View {
    @EnvironmentObject private var preferences: TerminalAccessoryPreferencesManager

    @State private var showingCreateSheet = false
    @State private var editingSessionType: SavedSessionType?

    var body: some View {
        Form {
            Section {
                if preferences.savedSessionTypes.isEmpty {
                    Text("No session types yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(preferences.savedSessionTypes) { sessionType in
                        Button {
                            editingSessionType = sessionType
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: sessionType.iconSystemName.isEmpty
                                    ? SavedSessionType.defaultIconSystemName
                                    : sessionType.iconSystemName)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 26)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(sessionType.title)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(sessionType.command)
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
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Edit") {
                                editingSessionType = sessionType
                            }
                            .tint(.blue)

                            Button("Delete", role: .destructive) {
                                preferences.deleteSessionType(id: sessionType.id)
                            }
                        }
                    }
                    .onMove { offsets, destination in
                        preferences.moveSessionTypes(fromOffsets: offsets, toOffset: destination)
                    }
                    .onDelete { offsets in
                        let types = preferences.savedSessionTypes
                        for index in offsets {
                            guard types.indices.contains(index) else { continue }
                            preferences.deleteSessionType(id: types[index].id)
                        }
                    }
                }
            } header: {
                Text("Session Types")
            } footer: {
                Text(
                    String(
                        format: String(localized: "%lld/%lld session types. They appear under My Session Types in the New Session picker."),
                        Int64(preferences.savedSessionTypes.count),
                        Int64(TerminalAccessoryProfile.maxSessionTypes)
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Session Types")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            #endif
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(!preferences.canCreateSessionType)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            SessionTypeFormView()
        }
        .sheet(item: $editingSessionType) { sessionType in
            SessionTypeFormView(sessionType: sessionType)
        }
    }
}
