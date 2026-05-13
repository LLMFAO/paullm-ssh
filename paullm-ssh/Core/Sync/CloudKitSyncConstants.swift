import Foundation

enum CloudKitSyncConstants {
    static let appPrefix = "app.paullm.ssh"
    static let cloudKitContainerIdentifier = "iCloud.app.paullm.ssh"
    static let recordZoneName = "paullm-sshZone"
    static let databaseSubscriptionID = "database-changes"

    static let syncEnabledKey = "iCloudSyncEnabled"
    static let pendingCloudKitSyncQueueStorageKey = "\(appPrefix).pendingCloudKitSyncQueue"
    static let serverStorageKey = "\(appPrefix).servers"
    static let workspaceStorageKey = "\(appPrefix).workspaces"
    static let didBootstrapDefaultWorkspaceKey = "\(appPrefix).didBootstrapDefaultWorkspace"
    static let pendingBootstrapWorkspaceIDKey = "\(appPrefix).pendingBootstrapWorkspaceID"
    static let terminalCustomThemesStorageKey = "terminalCustomThemesV1"
    static let terminalThemeNameKey = "terminalThemeName"
    static let terminalThemeNameLightKey = "terminalThemeNameLight"
    static let terminalUsePerAppearanceThemeKey = "terminalUsePerAppearanceTheme"
    static let terminalThemePreferenceUpdatedAtKey = "terminalThemePreferenceUpdatedAt"
    static let terminalAccessoryProfileStorageKey = "terminalAccessoryProfileV1"

    static func changeTokenKey(for zoneName: String = recordZoneName) -> String {
        "\(appPrefix).cloudkit.\(zoneName).token"
    }

    static func zoneReadyKey(for zoneName: String = recordZoneName) -> String {
        "\(appPrefix).cloudkit.\(zoneName).ready"
    }
}
