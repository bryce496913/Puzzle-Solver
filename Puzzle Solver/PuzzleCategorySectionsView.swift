import SwiftUI

struct PuzzleCategorySectionsView<Item: Identifiable, Destination: View>: View {
    let items: [Item]
    let title: (Item) -> String
    let subtitle: (Item) -> String
    let icon: (Item) -> String
    let isEnabled: (Item) -> Bool
    let destination: (Item) -> Destination

    private var activeItems: [Item] {
        items.filter { isEnabled($0) }
    }

    private var comingSoonItems: [Item] {
        items.filter { !isEnabled($0) }
    }

    var body: some View {
        if !activeItems.isEmpty {
            sectionTitle("Available now")
            ForEach(activeItems) { item in
                NavigationLink {
                    destination(item)
                } label: {
                    PuzzleTypeCard(
                        title: title(item),
                        subtitle: subtitle(item),
                        icon: icon(item),
                        isEnabled: true,
                        accentVariant: .accent
                    )
                }
                .buttonStyle(.plain)
            }
        }

        if !comingSoonItems.isEmpty {
            sectionTitle("Coming soon")
            ForEach(comingSoonItems) { item in
                NavigationLink {
                    destination(item)
                } label: {
                    PuzzleTypeCard(
                        title: title(item),
                        subtitle: subtitle(item),
                        icon: icon(item),
                        isEnabled: false,
                        accentVariant: .highlight
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .appTextStyle(.paragraph)
            .foregroundStyle(AppTheme.Colors.text.opacity(0.72))
            .textCase(.uppercase)
    }
}
