import SwiftUI

/// A star that saves a chef to the cook's favorites.
struct FavoriteChefButton: View {
    let model: OnboardingModel
    let chef: CookProfile
    var size: CGFloat = 30

    private var isFavorite: Bool { model.isFavorite(chef) }

    var body: some View {
        Button { model.toggleFavorite(chef) } label: {
            Image(systemName: isFavorite ? "star.fill" : "star")
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(isFavorite ? .white : Color.ink)
                .frame(width: size, height: size)
                .background(isFavorite ? Color.ink : .white, in: .circle)
                .overlay { Circle().stroke(Color.ink, lineWidth: 1.5) }
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isFavorite ? "Remove \(chef.name) from favorite chefs" : "Save \(chef.name) as a favorite chef")
        .sensoryFeedback(.selection, trigger: isFavorite)
    }
}

/// The Profile section listing saved chefs.
struct FavoriteChefsList: View {
    let model: OnboardingModel

    var body: some View {
        if model.favoriteChefs.isEmpty {
            Text("Tap the ☆ next to a chef on any card to save them here.")
                .font(.text(14))
                .foregroundStyle(Color.gray4)
        } else {
            VStack(spacing: 12) {
                ForEach(model.favoriteChefs, id: \.self) { chef in
                    HStack(spacing: 10) {
                        InkGlyphView(emoji: "👩‍🍳", size: 34)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(chef.name)
                                .font(.display(14))
                                .foregroundStyle(Color.ink)
                            Text(chef.detail)
                                .font(.text(12))
                                .foregroundStyle(Color.gray4)
                        }
                        Spacer()
                        FavoriteChefButton(model: model, chef: chef)
                    }
                }
            }
        }
    }
}
