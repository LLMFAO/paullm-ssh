import SwiftUI

struct ToolkitEntryDetailView: View {
    let entry: ToolkitEntry
    let manager: ToolkitManager
    let onOpenSession: (TerminalSessionStartup) -> Void

    @State private var showingPhaseConfirm = false
    @State private var pendingPhase: ToolkitRunPhase?
    @Environment(\.dismiss) private var dismiss

    private var status: ToolkitItemStatus { manager.status(for: entry) }
    private var warnings: ToolkitTrustWarning { ToolkitTrustWarning.compute(for: entry) }

    var body: some View {
        NavigationStack {
            List {
                headerSection
                statusSection
                trustWarningSection
                scriptsSection
                actionsSection
            }
            .navigationTitle(entry.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .alert(confirmTitle, isPresented: $showingPhaseConfirm, presenting: pendingPhase) { phase in
            Button("Cancel", role: .cancel) { }
            Button(phaseActionTitle(phase), role: phase == .uninstall ? .destructive : nil) {
                runPhase(phase)
            }
        } message: { phase in
            Text(confirmMessage(for: phase))
        }
    }

    // MARK: — Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ToolkitRiskBadge(level: entry.riskLevel)
                    ToolkitStatusBadge(status: status)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var statusSection: some View {
        Section("Status") {
            HStack {
                Text(status.displayName)
                Spacer()
                if status == .checking {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
    }

    @ViewBuilder
    private var trustWarningSection: some View {
        if warnings.hasAnyWarning {
            Section("Trust Warnings") {
                VStack(alignment: .leading, spacing: 8) {
                    if warnings.curlPipeShell {
                        warningRow(icon: "network", text: String(localized: "Downloads and executes remote shell code"))
                    }
                    if warnings.usesSudo {
                        warningRow(icon: "person.badge.key", text: String(localized: "May require elevated privileges (sudo)"))
                    }
                    if warnings.writesShellProfile {
                        warningRow(icon: "doc.badge.gearshape", text: String(localized: "Writes to shell profile files"))
                    }
                    if warnings.credentialAdjacentPath {
                        warningRow(icon: "lock.shield", text: String(localized: "Touches credential-adjacent paths"))
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var scriptsSection: some View {
        Group {
            scriptRow(title: String(localized: "Detect"), script: entry.detectScript)
            scriptRow(title: String(localized: "Install"), script: entry.installScript)
            scriptRow(title: String(localized: "Verify"), script: entry.verifyScript)
            if let setup = entry.setupScript {
                scriptRow(title: String(localized: "Setup"), script: setup)
            }
            if let uninstall = entry.uninstallScript {
                scriptRow(title: String(localized: "Uninstall"), script: uninstall)
            }
        }
    }

    private var actionsSection: some View {
        Group {
            Section {
                if status == .missing || status == .unknown {
                    Button {
                        maybeConfirm(phase: .install)
                    } label: {
                        Label(String(localized: "Install"), systemImage: "arrow.down.circle")
                    }
                }

                Button {
                    maybeConfirm(phase: .verify)
                } label: {
                    Label(String(localized: "Verify"), systemImage: "checkmark.shield")
                }

                if entry.setupScript != nil {
                    Button {
                        maybeConfirm(phase: .setup)
                    } label: {
                        Label(String(localized: "Setup"), systemImage: "person.badge.key")
                    }
                }

                if entry.uninstallScript != nil {
                    Button(role: .destructive) {
                        maybeConfirm(phase: .uninstall)
                    } label: {
                        Label(String(localized: "Uninstall"), systemImage: "trash")
                    }
                }
            }

            if let source = entry.sourceURL {
                Section {
                    Link(destination: source) {
                        Label(String(localized: "Source"), systemImage: "link")
                    }
                }
            }

            if let docs = entry.docsURL {
                Section {
                    Link(destination: docs) {
                        Label(String(localized: "Documentation"), systemImage: "book")
                    }
                }
            }
        }
    }

    // MARK: — Helpers

    private func scriptRow(title: String, script: String) -> some View {
        Section(title) {
            Text(script)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(.vertical, 2)
        }
    }

    private func warningRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    /// The exact script that will run for `phase` — the basis for confirmation
    /// instead of always keying off the install script.
    private func command(for phase: ToolkitRunPhase) -> String {
        switch phase {
        case .install: return entry.installScript
        case .verify: return entry.verifyScript
        case .setup: return entry.setupScript ?? ""
        case .uninstall: return entry.uninstallScript ?? ""
        }
    }

    private func phaseActionTitle(_ phase: ToolkitRunPhase) -> String {
        switch phase {
        case .install: return String(localized: "Install")
        case .verify: return String(localized: "Verify")
        case .setup: return String(localized: "Setup")
        case .uninstall: return String(localized: "Uninstall")
        }
    }

    private var confirmTitle: String {
        guard let phase = pendingPhase else { return entry.title }
        return String(localized: "\(phaseActionTitle(phase)) \(entry.title)?")
    }

    /// True when the *specific phase command* warrants an explicit confirmation:
    /// it pipes remote code into a shell, needs sudo, or the entry is high risk.
    private func requiresConfirmation(for phase: ToolkitRunPhase) -> Bool {
        let lowered = command(for: phase).lowercased()
        let curlPipe = lowered.contains("curl")
            && (lowered.contains("| sh") || lowered.contains("| bash") || lowered.contains("| /bin/bash"))
        let usesSudo = lowered.contains("sudo ")
        return curlPipe || usesSudo || entry.riskLevel == .high
    }

    private func confirmMessage(for phase: ToolkitRunPhase) -> String {
        let cmd = command(for: phase)
        let lowered = cmd.lowercased()
        var lines: [String] = []
        if lowered.contains("curl") && (lowered.contains("| sh") || lowered.contains("| bash") || lowered.contains("| /bin/bash")) {
            lines.append(String(localized: "This downloads and executes code from the internet. Verify the source before continuing."))
        } else if lowered.contains("sudo ") {
            lines.append(String(localized: "This may require elevated privileges (sudo). Ensure you trust the source before continuing."))
        }
        lines.append(String(localized: "This exact command will run on the remote server:"))
        lines.append(cmd)
        return lines.joined(separator: "\n\n")
    }

    private func maybeConfirm(phase: ToolkitRunPhase) {
        pendingPhase = phase
        if requiresConfirmation(for: phase) {
            showingPhaseConfirm = true
        } else {
            runPhase(phase)
        }
    }

    private func runPhase(_ phase: ToolkitRunPhase) {
        let startup = RemoteToolkitRunner.shared.makeRunStartup(for: entry, phase: phase)
        dismiss()
        onOpenSession(startup)
    }
}
