import SwiftUI

struct TerminalSessionKindBadge: View {
    let startup: TerminalSessionStartup?
    var showTitle: Bool = true

    private var title: String {
        startup?.displayTitle ?? TerminalSessionKind.tmux.displayName
    }

    private var kind: TerminalSessionKind {
        startup?.kind ?? .tmux
    }

    var body: some View {
        if showTitle {
            HStack(spacing: 6) {
                iconView
                Text(title)
            }
        } else {
            iconView
                .accessibilityLabel(title)
        }
    }

    @ViewBuilder
    private var iconView: some View {
        TerminalSessionKindIcon(kind: kind)
    }
}

struct TerminalSessionKindIcon: View {
    let kind: TerminalSessionKind

    var body: some View {
        Image(kind.iconAssetName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 16, height: 16)
    }
}
