import SwiftUI

struct TerminalSessionKindBadge: View {
    let startup: TerminalSessionStartup?
    var showTitle: Bool = true

    private var title: String {
        startup?.displayTitle ?? TerminalSessionKind.tmux.displayName
    }

    private var iconSystemName: String {
        startup?.iconSystemName ?? TerminalSessionKind.tmux.iconSystemName
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
        if kind == .tmux {
            ZStack {
                Circle()
                    .fill(Color.orange)
                Text("u")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 16, height: 16)
        } else {
            Image(systemName: iconSystemName)
        }
    }
}
