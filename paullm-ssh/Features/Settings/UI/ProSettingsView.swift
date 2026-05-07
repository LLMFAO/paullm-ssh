//
//  ProSettingsView.swift
//  paullm-ssh
//

import SwiftUI

struct ProSettingsView: View {
    var body: some View {
        Form {
            Section("Features") {
                featureRow(icon: "server.rack", title: "Unlimited Servers")
                featureRow(icon: "folder", title: "Unlimited Workspaces")
                featureRow(icon: "rectangle.stack", title: "Multiple Connections")
                featureRow(icon: "paintbrush", title: "Custom Environments")
                featureRow(icon: "icloud", title: "iCloud Sync")
            }

            Section("Legal") {
                Link(destination: URL(string: "https://vvterm.com/privacy/")!) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                .tint(.primary)
                .foregroundStyle(.primary)

                Link(destination: URL(string: "https://vvterm.com/terms/")!) {
                    Label("Terms of Use (EULA)", systemImage: "doc.text")
                }
                .tint(.primary)
                .foregroundStyle(.primary)
            }
        }
        .formStyle(.grouped)
    }

    private func featureRow(icon: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(title)
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
    }
}

#if os(iOS)
extension View {
    @ViewBuilder
    func manageSubscriptionsSheetCompat(
        isPresented: Binding<Bool>,
        subscriptionGroupID: String
    ) -> some View {
        self
    }
}
#endif

// MARK: - Preview

#Preview {
    ProSettingsView()
}
