import SwiftUI

/// A full-width photo of the finished dish, shown under the card on Inspect.
struct DishPhotoView: View {
    let recipe: Recipe

    var body: some View {
        Color.gray1
            .aspectRatio(4 / 5, contentMode: .fit)
            .overlay {
                if let url = recipe.photoURL {
                    AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.4))) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            placeholder(note: "Photo couldn't load")
                        default:
                            ProgressView().tint(Color.ink)
                        }
                    }
                } else {
                    placeholder(note: "Photo coming soon")
                }
            }
            .clipShape(.rect(cornerRadius: 24))
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(Color.gray2, lineWidth: 1.5) }
            .overlay(alignment: .bottomLeading) {
                if recipe.photoURL != nil {
                    Text("photo · TheMealDB")
                        .font(.text(10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.45), in: .capsule)
                        .padding(12)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(recipe.photoURL == nil ? "No photo yet" : "Photo of \(recipe.name)")
    }

    private func placeholder(note: String) -> some View {
        VStack(spacing: 12) {
            GlyphBubble(emoji: recipe.emoji, diameter: 140)
            Text(note)
                .font(.text(13))
                .foregroundStyle(Color.gray4)
        }
    }
}
