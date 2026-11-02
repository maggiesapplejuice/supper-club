import SwiftUI

// Free photos from TheMealDB, matched by hand. Only dishes it has (or a near-identical version of)
// are listed, so a card never shows the wrong food. The rest show a placeholder until we have photos.
private let dishPhotos: [String: String] = [
    "Massaman Curry": "tvttqv1504640475",
    "Hyderabadi Dum Biryani": "xrttsx1487339558",
    "Edomae Nigiri": "g046bb1663960946",
    "Chicken Katsu Curry": "vwrpps1503068729",
    "Ratatouille": "wrpwuu1511786491",
    "Coq au Vin": "qstyvs1505931190",
    "Moussaka": "ctg8jd1585563097",
    "Osso Buco": "wwuqvt1487345467",
    "Pad Thai": "rg9ze01763479093",
    "Phở Bò": "pbzcrx1763765096",
    "Bánh Xèo": "xrv78g1782769859",
    "Mapo Tofu": "1525874812",
    "Dal Tadka": "wuxrtu1483564410",
    "Tonkotsu Ramen": "ip5xtp1769779958",
    "Bouillabaisse de Marseille": "vptqpw1511798500",
    "Bánh Mì": "sonirb1763782831",
    "Khao Soi": "118oj61763423896",
]

extension Recipe {
    var photoURL: URL? {
        dishPhotos[name].flatMap { URL(string: "https://www.themealdb.com/images/media/meals/\($0).jpg") }
    }
}

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
            .overlay { RoundedRectangle(cornerRadius: 24).stroke(Color.ink, lineWidth: 2.5) }
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
            InkGlyphView(emoji: recipe.emoji, size: 120)
            Text(note)
                .font(.text(13))
                .foregroundStyle(Color.gray4)
        }
    }
}
