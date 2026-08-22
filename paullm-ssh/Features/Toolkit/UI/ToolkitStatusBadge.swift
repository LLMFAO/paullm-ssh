import SwiftUI

struct ToolkitStatusBadge: View {
    let status: ToolkitItemStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .unknown:
            return Color.secondary.opacity(0.15)
        case .checking:
            return Color.accentColor.opacity(0.15)
        case .installed:
            return Color.green.opacity(0.15)
        case .missing:
            return Color.red.opacity(0.15)
        case .needsSetup:
            return Color.orange.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .unknown:
            return .secondary
        case .checking:
            return .accentColor
        case .installed:
            return .green
        case .missing:
            return .red
        case .needsSetup:
            return .orange
        }
    }
}

struct ToolkitRiskBadge: View {
    let level: ToolkitRiskLevel

    var body: some View {
        if level != .low {
            HStack(spacing: 2) {
                Image(systemName: iconName)
                    .font(.caption2)
                Text(level.displayName)
                    .font(.caption2.weight(.medium))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
        }
    }

    private var iconName: String {
        switch level {
        case .low:
            return "checkmark.shield"
        case .medium:
            return "exclamationmark.triangle"
        case .high:
            return "exclamationmark.octagon"
        }
    }

    private var backgroundColor: Color {
        switch level {
        case .low:
            return Color.green.opacity(0.15)
        case .medium:
            return Color.orange.opacity(0.15)
        case .high:
            return Color.red.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch level {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}
