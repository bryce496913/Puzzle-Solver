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

struct TwistyColorOption: Identifiable {
    let id: String
    let label: String
    let color: Color
}

struct TwistyColorCountItem: Identifiable {
    let id: String
    let color: Color
    let count: Int
    let target: Int
}

struct TwistyColorCountRow: View {
    let items: [TwistyColorCountItem]

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ForEach(items) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 12, height: 12)

                    Text("\(item.count)/\(item.target)")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(item.count == item.target ? AppTheme.Colors.text : AppTheme.Colors.highlight)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(AppTheme.Colors.background.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            }
        }
    }
}

struct TwistyColorPickerRow: View {
    let options: [TwistyColorOption]
    let selectedColorID: String
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            ForEach(options) { option in
                Button {
                    onSelect(option.id)
                } label: {
                    VStack(spacing: AppTheme.Spacing.xSmall) {
                        Circle()
                            .fill(option.color)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(Color.white.opacity(0.65), lineWidth: 1))

                        Text(option.label)
                            .appTextStyle(.paragraph)
                            .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xSmall)
                    .background(selectedColorID == option.id ? AppTheme.Colors.highlight.opacity(0.22) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
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

struct CubeStickerView: View {
    let color: Color
    var size: CGFloat = 24
    var isSelected: Bool = false
    var isLocked: Bool = false
    var isReadOnly: Bool = false
    var onTap: (() -> Void)? = nil

    private var borderColor: Color {
        if isSelected { return AppTheme.Colors.highlight }
        return Color.white.opacity(0.72)
    }

    private var borderWidth: CGFloat {
        isSelected ? 2.6 : 1
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .overlay(alignment: .topTrailing) {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
                        .padding(3)
                        .background(AppTheme.Colors.background.opacity(0.45))
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }
            .overlay {
                if !isReadOnly {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .onTapGesture {
                onTap?()
            }
    }
}

struct Cube3x3FaceView: View {
    let slot: Cube3x3FaceSlot
    let stickers: [Cube3x3StickerColor]
    var selectedStickerIndex: Int? = nil
    var stickerSize: CGFloat = 22
    var isReadOnly: Bool = true
    var onStickerTap: ((Cube3x3StickerCoordinate) -> Void)? = nil

    private var safeStickers: [Cube3x3StickerColor] {
        if stickers.count == 9 { return stickers }
        return Array((stickers + Array(repeating: .up, count: 9)).prefix(9))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(slot.rawValue)
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.75))

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(stickerSize), spacing: AppTheme.Spacing.xSmall), count: 3),
                spacing: AppTheme.Spacing.xSmall
            ) {
                ForEach(Array(safeStickers.enumerated()), id: \.offset) { index, sticker in
                    let coordinate = Cube3x3StickerCoordinate(face: slot, index: index)
                    CubeStickerView(
                        color: sticker.displayColor,
                        size: stickerSize,
                        isSelected: selectedStickerIndex == index,
                        isLocked: coordinate.isCenter,
                        isReadOnly: isReadOnly,
                        onTap: {
                            guard !isReadOnly, !coordinate.isCenter else { return }
                            onStickerTap?(coordinate)
                        }
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.xSmall)
        .background(AppTheme.Colors.background.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
    }
}

struct Cube3x3NetView: View {
    let stickersByFace: [Cube3x3FaceSlot: [Cube3x3StickerColor]]
    var selectedSticker: Cube3x3StickerCoordinate? = nil
    var stickerSize: CGFloat = 22
    var isReadOnly: Bool = true
    var onStickerTap: ((Cube3x3StickerCoordinate) -> Void)? = nil

    private let netRows: [[Cube3x3FaceSlot?]] = [
        [nil, .u, nil, nil],
        [.l, .f, .r, .b],
        [nil, .d, nil, nil]
    ]

    private var blankFaceWidth: CGFloat {
        (stickerSize * 3) + (AppTheme.Spacing.xSmall * 4)
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            ForEach(Array(netRows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        if let face = cell {
                            Cube3x3FaceView(
                                slot: face,
                                stickers: stickersByFace[face] ?? Array(repeating: .up, count: 9),
                                selectedStickerIndex: selectedSticker?.face == face ? selectedSticker?.index : nil,
                                stickerSize: stickerSize,
                                isReadOnly: isReadOnly,
                                onStickerTap: onStickerTap
                            )
                        } else {
                            Color.clear
                                .frame(width: blankFaceWidth, height: blankFaceWidth)
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(AppTheme.Colors.background.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
    }
}

struct CubeMoveStepCardView: View {
    let step: TwistySolutionStepViewData
    var previewNet: Cube3x3StickerNet?
    var stickerSize: CGFloat = 14
    var previewCaption: String = "Cube state preview"

    private var netFaces: [Cube3x3FaceSlot: [Cube3x3StickerColor]] {
        guard let previewNet else { return [:] }
        return [
            .u: previewNet.up,
            .r: previewNet.right,
            .f: previewNet.front,
            .d: previewNet.down,
            .l: previewNet.left,
            .b: previewNet.back
        ]
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
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.84))
            }

            if let _ = previewNet {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                    Text(previewCaption)
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.72))

                    Cube3x3NetView(
                        stickersByFace: netFaces,
                        stickerSize: stickerSize,
                        isReadOnly: true
                    )
                }
            } else {
                HStack(spacing: AppTheme.Spacing.xSmall) {
                    Image(systemName: "cube.transparent")
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.78))
                    Text("Step playback preview not available.")
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.75))
                }
                .padding(AppTheme.Spacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.background.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }
}


extension TwistyEntryValidationStatus {
    var messageColor: Color {
        switch self {
        case .ready:
            return AppTheme.Colors.text
        case .incomplete, .invalid:
            return AppTheme.Colors.highlight
        }
    }
}

extension Cube3x3StickerColor {
    var label: String {
        switch self {
        case .up: return "White"
        case .right: return "Red"
        case .front: return "Green"
        case .down: return "Yellow"
        case .left: return "Orange"
        case .back: return "Blue"
        }
    }

    var shortLabel: String {
        switch self {
        case .up: return "W"
        case .right: return "R"
        case .front: return "G"
        case .down: return "Y"
        case .left: return "O"
        case .back: return "B"
        }
    }

    var displayColor: Color {
        switch self {
        case .up: return TwistyStickerPalette.standard.white
        case .down: return TwistyStickerPalette.standard.yellow
        case .right: return TwistyStickerPalette.standard.red
        case .left: return TwistyStickerPalette.standard.orange
        case .back: return TwistyStickerPalette.standard.blue
        case .front: return TwistyStickerPalette.standard.green
        }
    }
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

enum TwistyMoveSequenceStyle {
    case inline
    case numbered
}

struct TwistyMoveSequenceView: View {
    let title: String
    let moves: [TwistyMove]
    let style: TwistyMoveSequenceStyle

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(title)
                .appTextStyle(.h2)

            if moves.isEmpty {
                Text("No moves needed — this puzzle is already solved.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.82))
            } else {
                switch style {
                case .inline:
                    Text(moves.map(\.token).joined(separator: " "))
                        .appTextStyle(.paragraph)
                        .foregroundStyle(AppTheme.Colors.highlight)
                        .textSelection(.enabled)
                case .numbered:
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }
}

struct TwistyMoveListView: View {
    let title: String
    let moves: [TwistyMove]

    var body: some View {
        TwistyMoveSequenceView(title: title, moves: moves, style: .inline)
    }
}

struct TwistyNumberedMoveListView: View {
    let title: String
    let moves: [TwistyMove]

    var body: some View {
        TwistyMoveSequenceView(title: title, moves: moves, style: .numbered)
    }
}

struct TwistySolveSummaryCard: View {
    let result: TwistySolveResult
    var showChipMetrics: Bool = false
    var elapsedFormatter: ((TimeInterval) -> String)? = nil

    var body: some View {
        let summary = result.makeSummaryViewData()

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            Text(summary.validationText)
                .appTextStyle(.paragraph)
                .foregroundStyle(result.stateValidation.isValid ? AppTheme.Colors.text.opacity(0.9) : AppTheme.Colors.highlight)

            Text(summary.statusText)
                .appTextStyle(.h2)
                .foregroundStyle(result.isSolvable ? AppTheme.Colors.text : AppTheme.Colors.highlight)

            if showChipMetrics {
                HStack(spacing: AppTheme.Spacing.small) {
                    summaryChip(label: "Moves", value: "\(result.moveCount)")
                    summaryChip(label: "Steps", value: "\(result.steps.count)")
                    if let elapsedTime = result.elapsedTime {
                        summaryChip(label: "Time", value: elapsedFormatter?(elapsedTime) ?? String(format: "%.1fs", elapsedTime))
                    }
                }
            } else {
                Text(summary.moveCountText)
                    .appTextStyle(.paragraph)
                Text(summary.stepCountText)
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSurfaceCard()
    }

    private func summaryChip(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
            Text(label)
                .appTextStyle(.h3)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            Text(value)
                .appTextStyle(.h2)
                .foregroundStyle(AppTheme.Colors.highlight)
        }
        .padding(.horizontal, AppTheme.Spacing.small)
        .padding(.vertical, AppTheme.Spacing.xSmall)
        .background(AppTheme.Colors.background.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
    }
}

struct TwistyStepPlaybackControlsView: View {
    let currentStepNumber: Int
    let totalSteps: Int
    var currentMoveText: String? = nil
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

            Text("Current move: \(currentMoveText ?? "—")")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.highlight)

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

struct TwistySolutionPlaybackView<PreviewContent: View>: View {
    let step: TwistySolutionStepViewData
    let totalSteps: Int
    let isAutoPlaying: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToggleAutoPlay: () -> Void
    let previewCaption: String?
    private let previewContent: (() -> PreviewContent)?

    init(
        step: TwistySolutionStepViewData,
        totalSteps: Int,
        isAutoPlaying: Bool,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onToggleAutoPlay: @escaping () -> Void,
        previewCaption: String? = nil,
        @ViewBuilder previewContent: @escaping () -> PreviewContent
    ) {
        self.step = step
        self.totalSteps = totalSteps
        self.isAutoPlaying = isAutoPlaying
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onToggleAutoPlay = onToggleAutoPlay
        self.previewCaption = previewCaption
        self.previewContent = previewContent
    }

    init(
        step: TwistySolutionStepViewData,
        totalSteps: Int,
        isAutoPlaying: Bool,
        onPrevious: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onToggleAutoPlay: @escaping () -> Void
    ) where PreviewContent == EmptyView {
        self.step = step
        self.totalSteps = totalSteps
        self.isAutoPlaying = isAutoPlaying
        self.onPrevious = onPrevious
        self.onNext = onNext
        self.onToggleAutoPlay = onToggleAutoPlay
        self.previewCaption = nil
        self.previewContent = nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            TwistyStepPlaybackControlsView(
                currentStepNumber: step.stepNumber,
                totalSteps: totalSteps,
                currentMoveText: step.primaryText,
                isAutoPlaying: isAutoPlaying,
                onPrevious: onPrevious,
                onNext: onNext,
                onToggleAutoPlay: onToggleAutoPlay
            )

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
                        .foregroundStyle(AppTheme.Colors.text.opacity(0.84))
                }

                if let previewContent {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xSmall) {
                        if let previewCaption {
                            Text(previewCaption)
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
                        }
                        previewContent()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurfaceCard()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
