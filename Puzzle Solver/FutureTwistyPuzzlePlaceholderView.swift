import SwiftUI

struct FutureTwistyPuzzlePlaceholderView: View {
    let puzzleType: TwistyPuzzleType

    private var implementationPlan: TwistyPuzzleImplementationPlan? {
        puzzleType.implementationPlan
    }

    var body: some View {
        TwistyScreenContainer {
            TwistyScreenHeader(
                title: puzzleType.metadata.title,
                subtitle: "Shared twisty architecture ready for next puzzle"
            )

            Text("This puzzle is scaffolded so future implementation can plug into the shared twisty foundation without restructuring navigation.")
                .appTextStyle(.paragraph)
                .foregroundStyle(AppTheme.Colors.text.opacity(0.82))

            if let implementationPlan {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Planned scaffolding")
                        .appTextStyle(.h2)

                    ForEach(implementationPlan.checklist, id: \.self) { checklistItem in
                        HStack(alignment: .top, spacing: AppTheme.Spacing.xSmall) {
                            Image(systemName: "checklist")
                                .foregroundStyle(AppTheme.Colors.highlight)
                            Text(checklistItem)
                                .appTextStyle(.paragraph)
                                .foregroundStyle(AppTheme.Colors.text.opacity(0.88))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .appSurfaceCard()
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text("Current status")
                    .appTextStyle(.h2)
                Text("Input and solving UI are intentionally disabled until solver logic is implemented.")
                    .appTextStyle(.paragraph)
                    .foregroundStyle(AppTheme.Colors.text.opacity(0.82))

                Button("Solve (disabled)") {}
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(true)
                    .opacity(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSurfaceCard()
        }
        .navigationTitle(puzzleType.metadata.shortTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FutureTwistyPuzzlePlaceholderView(puzzleType: .pyraminx)
    }
}
