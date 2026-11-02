import SwiftUI

/// Stands in for the Discover home screen until the trading flow is built.
struct CollectionView: View {
    let recipes: [Recipe]
    @State private var detailRecipe: Recipe?

    private var sorted: [Recipe] { recipes.sorted { $0.score > $1.score } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("My Recipe Cards")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color.brandText)
                if recipes.isEmpty {
                    Text("Cards you collect will show up here.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.gray4)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 14) {
                        ForEach(sorted) { recipe in
                            Button { detailRecipe = recipe } label: {
                                LiveCardView(recipe: recipe, width: 165)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Shows rarity details")
                        }
                    }
                }
            }
            .padding(20)
        }
        .sheet(item: $detailRecipe) { recipe in
            RarityDetailView(recipe: recipe)
        }
    }
}

#Preview {
    CollectionView(recipes: StarterPack.build(experience: .advanced, cuisines: ["French", "Japanese"]))
}
