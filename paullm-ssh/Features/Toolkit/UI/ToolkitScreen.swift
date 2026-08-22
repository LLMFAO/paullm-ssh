import SwiftUI
import Combine

struct ToolkitScreen: View {
    @StateObject private var manager: ToolkitManager
    @State private var selectedEntry: ToolkitEntry?
    @State private var showingMemoryVault = false

    let onOpenSession: (TerminalSessionStartup) -> Void

    init(server: Server, onOpenSession: @escaping (TerminalSessionStartup) -> Void) {
        self._manager = StateObject(wrappedValue: ToolkitManager(server: server))
        self.onOpenSession = onOpenSession
    }

    var body: some View {
        NavigationStack {
            List {
                if manager.requiresConnection {
                    Section {
                        connectionRequiredBanner
                    }
                }

                ForEach(ToolkitCategory.allCases) { category in
                    let categoryEntries = manager.entries.filter { $0.category == category }
                    if !categoryEntries.isEmpty {
                        Section(category.displayName) {
                            ForEach(categoryEntries) { entry in
                                toolkitRow(entry: entry)
                            }
                        }
                    }
                }
            }
            .navigationTitle(String(localized: "Toolkit"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingMemoryVault = true
                    } label: {
                        Image(systemName: "archivebox")
                    }
                }
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    if manager.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button {
                            manager.refreshStatus()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                #endif
            }
            .onAppear {
                manager.refreshStatus()
            }
            .onDisappear {
                manager.cancelRefresh()
            }
            .sheet(item: $selectedEntry) { entry in
                ToolkitEntryDetailView(
                    entry: entry,
                    manager: manager,
                    onOpenSession: onOpenSession
                )
            }
            .sheet(isPresented: $showingMemoryVault) {
                MemoryVaultView(
                    server: manager.server,
                    onOpenSession: onOpenSession
                )
            }
        }
    }

    private var connectionRequiredBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "Connect to detect status"))
                    .font(.subheadline.weight(.semibold))
                Text(String(localized: "Open a terminal session to this server so the Toolkit can check which tools are installed. You can still inspect and run actions below."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    private func toolkitRow(entry: ToolkitEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(entry.title)
                            .font(.body)
                            .foregroundStyle(.primary)

                        ToolkitStatusBadge(status: manager.status(for: entry))
                        ToolkitRiskBadge(level: entry.riskLevel)
                    }

                    Text(entry.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
