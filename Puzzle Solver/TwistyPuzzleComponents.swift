import SwiftUI


struct TwistyScreenContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                    content()
                }
                .padding(AppTheme.Spacing.large)
            }
        }
    }
}

struct TwistyScreenHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(title)
                .appTextStyle(.h1)
                .foregroundStyle(AppTheme.Colors.highlight)

            Text(subtitle)
                .appTextStyle(.h2)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
        }
    }
}

struct TwistyInlineStatusMessage: View {
    let message: String

    var body: some View {
        Text(message)
            .appTextStyle(.paragraph)
            .foregroundStyle(AppTheme.Colors.highlight)
            .padding(AppTheme.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.highlight.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
    }
}

struct TwistyStickerPalette {
    let white: Color
    let yellow: Color
    let red: Color
    let orange: Color
    let blue: Color
    let green: Color
    let fallback: Color

    static let standard = TwistyStickerPalette(
        white: Color(red: 0.95, green: 0.95, blue: 0.98),
        yellow: Color(red: 0.98, green: 0.84, blue: 0.25),
        red: Color(red: 0.87, green: 0.22, blue: 0.22),
        orange: Color(red: 0.95, green: 0.52, blue: 0.19),
        blue: Color(red: 0.19, green: 0.39, blue: 0.91),
        green: Color(red: 0.20, green: 0.68, blue: 0.35),
        fallback: AppTheme.Colors.surface
    )
}

struct TwistyFaceSticker: Identifiable, Hashable {
    let id: String
    let color: Color
}

struct TwistyFaceModel: Identifiable, Hashable {
    let id: String
    let title: String?
    let dimension: Int
    let stickers: [TwistyFaceSticker]
}

struct CubeFaceView: View {
    let face: TwistyFaceModel
    var stickerSize: CGFloat = 26
    var onStickerTap: ((TwistyFaceSticker) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            if let title = face.title {
                Text(title)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            }

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(stickerSize), spacing: AppTheme.Spacing.xSmall), count: face.dimension),
                spacing: AppTheme.Spacing.xSmall
            ) {
                ForEach(face.stickers) { sticker in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(sticker.color)
                        .frame(width: stickerSize, height: stickerSize)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.white.opacity(0.58), lineWidth: 1)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .onTapGesture {
                            onStickerTap?(sticker)
                        }
                }
            }
        }
        .padding(AppTheme.Spacing.xSmall)
        .background(AppTheme.Colors.background.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
    }
}

struct CubeNetView: View {
    let layoutRows: [[String?]]
    let facesByID: [String: TwistyFaceModel]
    var stickerSize: CGFloat = 26
    var onStickerTap: ((String, TwistyFaceSticker) -> Void)? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(Array(layoutRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        if let faceID = cell,
                           let face = facesByID[faceID] {
                            CubeFaceView(face: face, stickerSize: stickerSize) { sticker in
                                onStickerTap?(faceID, sticker)
                            }
                        } else {
                            Color.clear
                                .frame(width: (stickerSize * 2) + (AppTheme.Spacing.xSmall * 3), height: (stickerSize * 2) + (AppTheme.Spacing.xSmall * 3))
                        }
                    }
                }
            }
        }
    }
}

struct TwistyMoveListView: View {
    let title: String
    let moves: [TwistyMove]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .appTextStyle(.h2)

            if moves.isEmpty {
                Text("No moves needed — this puzzle is already solved.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
            } else {
                Text(moves.map(\.token).joined(separator: " "))
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.highlight)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }
}

struct TwistyNumberedMoveListView: View {
    let title: String
    let moves: [TwistyMove]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .appTextStyle(.h2)

            if moves.isEmpty {
                Text("No moves needed — this puzzle is already solved.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
            } else {
                VStack(spacing: AppTheme.Spacing.xSmall) {
                    ForEach(Array(moves.enumerated()), id: \.offset) { index, move in
                        HStack(spacing: AppTheme.Spacing.small) {
                            Text("\(index + 1).")
                                .appTextStyle(.h3)
                                .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
                                .frame(width: 28, alignment: .leading)

                            Text(move.token)
                                .appTextStyle(.h2)
                                .foregroundStyle(AppTheme.Colors.highlight)

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, AppTheme.Spacing.small)
                        .padding(.vertical, AppTheme.Spacing.xSmall)
                        .background(AppTheme.Colors.background.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }
}

struct TwistyStepPlaybackControlsView: View {
    let currentStepNumber: Int
    let totalSteps: Int
    let isAutoPlaying: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToggleAutoPlay: () -> Void

    private var canGoPrevious: Bool {
        currentStepNumber > 1
    }

    private var canGoNext: Bool {
        currentStepNumber < totalSteps
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text("Step \(currentStepNumber) of \(totalSteps)")
                .appTextStyle(.h3)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.85))

            HStack(spacing: AppTheme.Spacing.small) {
                Button(action: onPrevious) {
                    Label("Previous", systemImage: "chevron.left")
                }
                .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.background.opacity(0.42)))
                .disabled(!canGoPrevious)

                Button(action: onToggleAutoPlay) {
                    Label(isAutoPlaying ? "Pause" : "Play", systemImage: isAutoPlaying ? "pause.fill" : "play.fill")
                }
                .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.accent.opacity(0.75)))
                .disabled(totalSteps < 2)

                Button(action: onNext) {
                    Label("Next", systemImage: "chevron.right")
                }
                .buttonStyle(AppSolidButtonStyle(fillColor: AppTheme.Colors.background.opacity(0.42)))
                .disabled(!canGoNext)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }
}

struct TwistyStepCardView: View {
    let step: TwistySolutionStepViewData
    let previewText: String

    init(step: TwistySolutionStepViewData, previewText: String = "Puzzle preview coming soon") {
        self.step = step
        self.previewText = previewText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.small) {
                Text("Step \(step.stepNumber)")
                    .appTextStyle(.h2)

                Spacer(minLength: AppTheme.Spacing.small)

                Text(step.primaryText)
                    .appTextStyle(.h2)
                    .foregroundStyle(AppTheme.Colors.highlight)
                    .padding(.horizontal, AppTheme.Spacing.small)
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                    .background(AppTheme.Colors.background.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            }

            if let secondaryText = step.secondaryText {
                Text(secondaryText)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.8))
            }

            HStack(spacing: AppTheme.Spacing.xSmall) {
                Image(systemName: "cube.transparent")
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
                Text(previewText)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.75))
            }
            .padding(AppTheme.Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Colors.background.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }
}
