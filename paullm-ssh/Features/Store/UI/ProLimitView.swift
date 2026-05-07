import SwiftUI

// MARK: - No-op Pro UI (GPL — all features free)

struct ProLimitBanner: View {
    let title: String
    let message: String
    let action: () -> Void
    var body: some View { EmptyView() }
}

struct ProFeatureLock: View {
    let feature: String
    let description: String
    @Binding var showUpgrade: Bool
    var body: some View { EmptyView() }
}

struct LimitReachedAlert: ViewModifier {
    let limitType: LimitType
    @Binding var isPresented: Bool
    enum LimitType { case servers, workspaces, tabs, fileTabs }
    func body(content: Content) -> some View { content }
}

extension View {
    func limitReachedAlert(_ limitType: LimitReachedAlert.LimitType, isPresented: Binding<Bool>) -> some View {
        self
    }
}

extension View {
    func proFeatureAlert(title: String, message: String, isPresented: Binding<Bool>) -> some View {
        self
    }
    func splitPaneProFeatureAlert(isPresented: Binding<Bool>) -> some View {
        self
    }
}

struct ProBadge: View {
    var compact: Bool = false
    var body: some View { EmptyView() }
}

struct ProGateView<Content: View, LockedContent: View>: View {
    let content: () -> Content
    let lockedContent: () -> LockedContent
    init(@ViewBuilder content: @escaping () -> Content, @ViewBuilder lockedContent: @escaping () -> LockedContent) {
        self.content = content
        self.lockedContent = lockedContent
    }
    var body: some View { content() }
}

struct UsageIndicator: View {
    let current: Int
    let limit: Int
    let label: String
    @Binding var showUpgrade: Bool
    var body: some View { EmptyView() }
}

struct LockedItemAlert: ViewModifier {
    let itemType: ItemType
    let itemName: String
    @Binding var isPresented: Bool
    enum ItemType { case server, workspace }
    func body(content: Content) -> some View { content }
}

extension View {
    func lockedItemAlert(_ itemType: LockedItemAlert.ItemType, itemName: String, isPresented: Binding<Bool>) -> some View {
        self
    }
}

struct LockedBadge: View {
    var body: some View { EmptyView() }
}

struct DowngradeBanner: View {
    let lockedServers: Int
    let lockedWorkspaces: Int
    let action: () -> Void
    var body: some View { EmptyView() }
}

// Keep FreeTierLimits for compatibility (values irrelevant — everything is unlimited)
enum FreeTierLimits {
    static let maxWorkspaces = Int.max
    static let maxServers = Int.max
    static let maxTabs = Int.max
}
