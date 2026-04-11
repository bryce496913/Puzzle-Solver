import SwiftUI

struct PuzzleTypeCard: View {
    enum AccentVariant {
        case accent
        case highlight

        var color: Color {
            switch self {
            case .accent:
                return AppTheme.Colors.accent
            case .highlight:
                return AppTheme.Colors.highlight
            }
        }
    }

    let title: String
    let subtitle: String
    let icon: String
    let isEnabled: Bool
    let accentVariant: AccentVariant

    init(
        title: String,
        subtitle: String,
        icon: String,
        isEnabled: Bool = true,
        accentVariant: AccentVariant = .accent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.isEnabled = isEnabled
        self.accentVariant = accentVariant
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .frame(width: 34, height: 34)
                .foregroundStyle(accentColor)
                .background(accentColor.opacity(isEnabled ? 0.16 : 0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                Text(title)
                    .appTextStyle(.h2)
                    .foregroundStyle(AppTheme.Colors.text)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(isEnabled ? 0.72 : 0.56))
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: isEnabled ? "chevron.right" : "lock.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accentColor.opacity(isEnabled ? 1 : 0.6))
        }
        .padding(.vertical, AppTheme.Spacing.small)
        .padding(.horizontal, AppTheme.Spacing.small)
        .appSurfaceCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, style: .continuous)
                .stroke(accentColor.opacity(isEnabled ? 0.3 : 0.14), lineWidth: 1)
        )
        .opacity(isEnabled ? 1 : 0.78)
    }

    private var accentColor: Color {
        accentVariant.color
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.medium) {
        PuzzleTypeCard(
            title: "3×3 Sliding Puzzle",
            subtitle: "Ready now",
            icon: "square.grid.3x3.fill",
            isEnabled: true,
            accentVariant: .accent
        )

        PuzzleTypeCard(
            title: "Rubik’s Cube",
            subtitle: "Coming soon",
            icon: "cube.fill",
            isEnabled: false,
            accentVariant: .highlight
        )
    }
    .padding()
    .background(AppTheme.Colors.background)
}
