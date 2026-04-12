import SwiftUI

enum SlidingPuzzleBoardMode {
    case input
    case display
    case solution
}

struct SlidingPuzzleBoardView: View {
    let boardValues: [Int?]
    let boardSize: Int
    var selectedTileIndex: Int?
    var onTileTap: ((Int) -> Void)?
    var mode: SlidingPuzzleBoardMode = .display

    private var spacing: CGFloat { AppTheme.Spacing.small }

    private var tileCount: Int {
        boardSize * boardSize
    }

    var body: some View {
        GeometryReader { geometry in
            let sideLength = max(min(geometry.size.width, geometry.size.height), 1)
            let totalSpacing = spacing * CGFloat(max(boardSize - 1, 0))
            let tileLength = max((sideLength - totalSpacing) / CGFloat(max(boardSize, 1)), 32)

            VStack(spacing: spacing) {
                ForEach(0..<boardSize, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<boardSize, id: \.self) { column in
                            let index = row * boardSize + column
                            tileView(value: value(at: index), index: index, tileLength: tileLength)
                        }
                    }
                }
            }
            .frame(width: sideLength, height: sideLength)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func tileView(value: Int?, index: Int, tileLength: CGFloat) -> some View {
        let isBlank = value == nil
        let isSelected = selectedTileIndex == index

        Text(value.map(String.init) ?? "")
            .appTextStyle(boardSize == 3 ? .h2 : .h3)
            .foregroundStyle(isBlank ? AppTheme.Colors.text.opacity(0.7) : AppTheme.Colors.text)
            .minimumScaleFactor(0.7)
            .frame(width: tileLength, height: tileLength)
            .background(tileBackgroundColor(isBlank: isBlank, isSelected: isSelected))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous)
                    .stroke(tileBorderColor(isSelected: isSelected), lineWidth: isSelected ? 2.5 : 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture {
                onTileTap?(index)
            }
    }

    private func value(at index: Int) -> Int? {
        guard index >= 0, index < min(boardValues.count, tileCount) else { return nil }
        return boardValues[index]
    }

    private func tileBackgroundColor(isBlank: Bool, isSelected: Bool) -> Color {
        if isSelected {
            return AppTheme.Colors.highlight.opacity(0.28)
        }

        if isBlank {
            return AppTheme.Colors.surface.opacity(mode == .input ? 1 : 0.8)
        }

        switch mode {
        case .input:
            return AppTheme.Colors.accent.opacity(0.35)
        case .display:
            return AppTheme.Colors.accent.opacity(0.25)
        case .solution:
            return AppTheme.Colors.highlight.opacity(0.25)
        }
    }

    private func tileBorderColor(isSelected: Bool) -> Color {
        if isSelected {
            return AppTheme.Colors.highlight
        }

        return Color.white.opacity(mode == .solution ? 0.7 : 0.9)
    }
}

#Preview {
    VStack(spacing: AppTheme.Spacing.large) {
        SlidingPuzzleBoardView(
            boardValues: [1, 2, 3, 4, 5, 6, 7, 8, nil],
            boardSize: 3,
            selectedTileIndex: 7,
            onTileTap: { _ in },
            mode: .input
        )

        SlidingPuzzleBoardView(
            boardValues: [1, 2, 3, 4, 5, 6, 7, nil, 8, 9, 10, 11, 13, 14, 15, 12],
            boardSize: 4,
            mode: .solution
        )
    }
    .padding()
    .background(AppTheme.Colors.background)
}
