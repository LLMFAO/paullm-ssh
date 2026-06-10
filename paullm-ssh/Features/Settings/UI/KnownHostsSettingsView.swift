import SwiftUI

// MARK: - Known Hosts Settings View

struct KnownHostsSettingsView: View {
    @State private var entries: [KnownHostsManager.Entry] = []
    @State private var entryPendingDelete: KnownHostsManager.Entry?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if entries.isEmpty {
                emptyView
            } else {
                List {
                    Section {
                        ForEach(entries, id: \.id) { entry in
                            KnownHostRow(entry: entry)
                        }
                        .onDelete(perform: deleteAt)
                    } footer: {
                        Text("Pinned SSH host keys. Removing an entry will cause the next connection to that host to prompt for trust again.")
                    }
                }
            }
        }
        .onAppear(perform: reload)
        .alert(
            "Remove Known Host",
            isPresented: $showDeleteConfirmation,
            presenting: entryPendingDelete
        ) { entry in
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                remove(entry)
            }
        } message: { entry in
            Text(String(format: String(localized: "Remove the pinned host key for %@:%d?"), entry.host, entry.port))
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        if #available(iOS 17.0, macOS 14.0, *) {
            ContentUnavailableView {
                Label("No Known Hosts", systemImage: "checkmark.shield")
            } description: {
                Text("Pinned SSH host keys will appear here after you connect to a server.")
            }
        } else {
            VStack(spacing: 12) {
                Label("No Known Hosts", systemImage: "checkmark.shield")
                    .font(.headline)
                Text("Pinned SSH host keys will appear here after you connect to a server.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func reload() {
        entries = KnownHostsManager.shared.allEntries()
    }

    private func deleteAt(_ offsets: IndexSet) {
        guard let index = offsets.first else { return }
        entryPendingDelete = entries[index]
        showDeleteConfirmation = true
    }

    private func remove(_ entry: KnownHostsManager.Entry) {
        KnownHostsManager.shared.removeEntry(host: entry.host, port: entry.port)
        reload()
    }
}

private struct KnownHostRow: View {
    let entry: KnownHostsManager.Entry

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(entry.host):\(entry.port)")
                .font(.headline)
                .textSelection(.enabled)
            Text(entry.fingerprint)
                .font(.system(.subheadline, design: .monospaced))
                .lineLimit(2)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            HStack(spacing: 12) {
                Label(
                    String(format: String(localized: "Added %@"), Self.dateFormatter.string(from: entry.addedAt)),
                    systemImage: "plus.circle"
                )
                Label(
                    String(format: String(localized: "Seen %@"), Self.dateFormatter.string(from: entry.lastSeenAt)),
                    systemImage: "clock"
                )
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
