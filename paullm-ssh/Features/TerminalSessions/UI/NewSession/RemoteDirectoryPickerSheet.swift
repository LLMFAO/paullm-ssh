import SwiftUI

/// A lightweight remote directory browser used to choose a starting folder for a
/// new session. It lists directories on the actual host via the injected closure
/// and returns the chosen absolute path.
struct RemoteDirectoryPickerSheet: View {
    /// Resolves the initial absolute directory to start browsing from (e.g. $HOME).
    let resolveStartPath: () async -> String
    /// Lists the directory entries (filtered to folders) at a path.
    let loadDirectories: (String) async throws -> [RemoteFileEntry]
    let onCancel: () -> Void
    let onChoose: (String) -> Void

    @State private var currentDirectory: String = "/"
    @State private var directories: [RemoteFileEntry] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "Selected Folder")) {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.badge.checkmark")
                            .foregroundStyle(Color.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(folderDisplayName(for: currentDirectory))
                                .font(.headline)
                                .lineLimit(1)
                            Text(currentDirectory)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 2)
                }

                Section(String(localized: "Choose Folder")) {
                    if currentDirectory != "/" {
                        Button {
                            navigate(to: RemoteFilePath.parent(of: currentDirectory))
                        } label: {
                            pickerRow(title: String(localized: "Up"), systemImage: "arrow.up")
                        }
                    }

                    Button {
                        navigate(to: "/")
                    } label: {
                        pickerRow(title: String(localized: "Root"), systemImage: "externaldrive")
                    }

                    if isLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text(String(localized: "Loading folders…"))
                                .foregroundStyle(.secondary)
                        }
                    } else if let errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button(String(localized: "Retry")) {
                                Task { await loadCurrent() }
                            }
                        }
                    } else if directories.isEmpty {
                        Text(String(localized: "No subfolders in this location."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(directories) { directory in
                            Button {
                                navigate(to: directory.path)
                            } label: {
                                pickerRow(title: directory.name, systemImage: "folder")
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "Start In Folder"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel"), action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Use This Folder")) {
                        onChoose(currentDirectory)
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                let start = await resolveStartPath()
                currentDirectory = RemoteFilePath.normalize(start)
                await loadCurrent()
            }
        }
    }

    private func pickerRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func navigate(to path: String) {
        currentDirectory = RemoteFilePath.normalize(path)
        Task { await loadCurrent() }
    }

    @MainActor
    private func loadCurrent() async {
        isLoading = true
        errorMessage = nil
        do {
            directories = try await loadDirectories(currentDirectory)
        } catch {
            directories = []
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func folderDisplayName(for path: String) -> String {
        let normalized = RemoteFilePath.normalize(path)
        guard normalized != "/" else { return String(localized: "Root") }
        return URL(fileURLWithPath: normalized).lastPathComponent
    }
}
