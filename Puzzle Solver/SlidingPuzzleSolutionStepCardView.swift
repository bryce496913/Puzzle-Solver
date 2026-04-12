import SwiftUI

struct SolutionStepCardView: View {
    let step: SlidingPuzzleSolutionStep

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Step \(step.stepNumber)")
                    .appTextStyle(.h2)
                    .foregroundStyle(AppTheme.Colors.text)

                Spacer(minLength: AppTheme.Spacing.small)

                if let moveLabel = step.moveLabel {
                    Text(moveLabel)
                        .appTextStyle(.h3)
                        .foregroundStyle(AppTheme.Colors.highlight)
                        .multilineTextAlignment(.trailing)
                } else {
                    Text("Initial state")
                        .appTextStyle(.h3)
                        .foregroundStyle(AppTheme.Colors.highlight)
                }
            }

            SlidingPuzzleBoardView(
                boardValues: step.state.boardRows().flatMap { $0 },
                boardSize: step.state.size,
                mode: .solution
            )
                .padding(AppTheme.Spacing.xSmall)
                .background(AppTheme.Colors.background.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium, style: .continuous))
        }
        .appSurfaceCard()
    }
}

struct SolutionStepCardView_Previews: PreviewProvider {
    static var previews: some View {
        SolutionStepCardView(
            step: .init(
                state: SlidingPuzzleState(board: [
                    [1, 2, 3],
                    [4, 5, 6],
                    [7, nil, 8]
                ])!,
                stepNumber: 1,
                move: .right
            )
        )
        .padding()
        .background(AppTheme.Colors.background)
    }
}
