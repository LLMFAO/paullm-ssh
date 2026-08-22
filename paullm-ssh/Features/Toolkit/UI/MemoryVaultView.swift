import SwiftUI
import Combine

struct MemoryVaultView: View {
    let server: Server
    let onOpenSession: (TerminalSessionStartup) -> Void

    @StateObject private var writer = MemoryVaultViewModel()
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var includeOpencode = true
    @State private var includeClaude = true
    @State private var includeCodex = true
    @State private var showingInitializeConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if !writer.inspections.isEmpty {
                    Section("Vault Files") {
                        ForEach(writer.inspections) { inspection in
                            HStack {
                                Text(inspection.template.fullPath)
                                    .font(.caption.monospaced())
                                Spacer()
                                Image(systemName: inspection.exists ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(inspection.exists ? .green : .secondary)
                            }
                        }
                    }
                }

                Section("Project Details") {
                    TextField("Project Name", text: $projectName)
                    TextField("Description", text: $projectDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Include Configs") {
                    Toggle("OpenCode (.opencode/)", isOn: $includeOpencode)
                    Toggle("Claude (.claude/)", isOn: $includeClaude)
                    Toggle("Codex (.codex/)", isOn: $includeCodex)
                }

                Section {
                    Button {
                        showingInitializeConfirm = true
                    } label: {
                        Label("Initialize Memory Vault", systemImage: "archivebox.fill")
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty || writer.isInitializing)
                }
            }
            .navigationTitle(String(localized: "Memory Vault"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await writer.inspect(server: server)
            }
            .alert("Initialize Memory Vault?", isPresented: $showingInitializeConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Initialize") {
                    Task {
                        await writer.initialize(
                            server: server,
                            projectName: projectName,
                            projectDescription: projectDescription,
                            includeOpencode: includeOpencode,
                            includeClaude: includeClaude,
                            includeCodex: includeCodex
                        )
                    }
                }
            } message: {
                Text("This will create docs/ai/ and optional .opencode/, .claude/, .codex/ directories on the remote server.")
            }
        }
    }
}

@MainActor
final class MemoryVaultViewModel: ObservableObject {
    @Published var inspections: [MemoryVaultInspection] = []
    @Published var isInitializing = false
    @Published var lastError: Error?

    func inspect(server: Server) async {
        inspections = await MemoryVaultWriter.shared.inspectVault(for: server)
    }

    func initialize(
        server: Server,
        projectName: String,
        projectDescription: String,
        includeOpencode: Bool,
        includeClaude: Bool,
        includeCodex: Bool
    ) async {
        isInitializing = true
        defer { isInitializing = false }
        do {
            try await MemoryVaultWriter.shared.initializeVault(
                for: server,
                projectName: projectName,
                projectDescription: projectDescription,
                includeOpencode: includeOpencode,
                includeClaude: includeClaude,
                includeCodex: includeCodex
            )
            await inspect(server: server)
        } catch {
            lastError = error
        }
    }
}
