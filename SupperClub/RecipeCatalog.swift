import SwiftUI

enum RarityTier: Int, CaseIterable, Identifiable {
    case common, uncommon, rare, epic, legendary

    var id: Self { self }

    init(score: Int) {
        switch score {
        case ..<40: self = .common
        case ..<60: self = .uncommon
        case ..<75: self = .rare
        case ..<90: self = .epic
        default: self = .legendary
        }
    }

    var name: String {
        switch self {
        case .common: "Common"
        case .uncommon: "Uncommon"
        case .rare: "Rare"
        case .epic: "Epic"
        case .legendary: "Legendary"
        }
    }

    var scoreRange: String {
        switch self {
        case .common: "0–39"
        case .uncommon: "40–59"
        case .rare: "60–74"
        case .epic: "75–89"
        case .legendary: "90–100"
        }
    }

    var stars: Int { rawValue + 1 }

    var isHolographic: Bool { self == .legendary }

    /// The tier's fill on cards, pills and pack reveals.
    var accent: Color {
        switch self {
        case .common: .oat
        case .uncommon: .mint
        case .rare: .sky
        case .epic: .grape
        case .legendary: .rose
        }
    }

    /// The tier's color for text on paper, dark enough to read.
    var color: Color {
        switch self {
        case .common: .gray4
        case .uncommon: Color(hex: 0x7F8A1E)
        case .rare: Color.periwinkle
        case .epic: Color.grape
        case .legendary: Color.rose
        }
    }
}

struct RarityFactor: Identifiable {
    let name: String
    let detail: String
    let points: Int

    var id: String { name }
    static let maxPoints = 25
}

struct Recipe: Identifiable, Hashable, Decodable {
    let id: String
    let name: String
    let emoji: String
    let cuisine: String
    let city: DishCity
    let skill: CookingExperience
    let minutes: Int
    let technique: Int
    let ingredients: Int
    let heritage: Int
    let tradeScarcity: Int
    let photoURL: URL?
    /// What the dish contains, for the dietary filters.
    let contents: Set<Ingredient>
    let ingredientList: [String]

    var score: Int { technique + ingredients + heritage + tradeScarcity }
    var tier: RarityTier { RarityTier(score: score) }

    var factors: [RarityFactor] {
        [
            RarityFactor(name: "Technique", detail: "How hard it is to master", points: technique),
            RarityFactor(name: "Ingredients", detail: "How hard they are to find", points: ingredients),
            RarityFactor(name: "Heritage", detail: "How closely tied it is to one place or tradition", points: heritage),
            RarityFactor(name: "Trading frequency", detail: "Fewer trades earn more points", points: tradeScarcity),
        ]
    }

    static func == (lhs: Recipe, rhs: Recipe) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    private enum CodingKeys: String, CodingKey {
        case id, name, emoji, cuisine, city, latitude, longitude, skill, minutes
        case technique, ingredients, heritage, tradeScarcity, photo, contents, ingredientList
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        emoji = try values.decode(String.self, forKey: .emoji)
        cuisine = try values.decode(String.self, forKey: .cuisine)
        city = DishCity(
            name: try values.decode(String.self, forKey: .city),
            latitude: try values.decode(Double.self, forKey: .latitude),
            longitude: try values.decode(Double.self, forKey: .longitude)
        )
        skill = try values.decode(CookingExperience.self, forKey: .skill)
        minutes = try values.decode(Int.self, forKey: .minutes)
        technique = try values.decode(Int.self, forKey: .technique)
        ingredients = try values.decode(Int.self, forKey: .ingredients)
        heritage = try values.decode(Int.self, forKey: .heritage)
        tradeScarcity = try values.decode(Int.self, forKey: .tradeScarcity)
        photoURL = try values.decodeIfPresent(URL.self, forKey: .photo)
        contents = Set(try values.decode([String].self, forKey: .contents).compactMap(Ingredient.init(rawValue:)))
        ingredientList = try values.decode([String].self, forKey: .ingredientList)
    }
}

extension CookingExperience {
    var level: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

/// Every recipe in the app, from Recipes.json. That file is generated from TheMealDB by tools/build_recipes.py,
/// which also tags each dish's contents and works out its rarity.
let recipeCatalog: [Recipe] = {
    guard let url = Bundle.main.url(forResource: "Recipes", withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
        assertionFailure("Recipes.json is missing from the app bundle")
        return []
    }
    do {
        return try JSONDecoder().decode([Recipe].self, from: data)
    } catch {
        assertionFailure("Recipes.json didn't decode: \(error)")
        return []
    }
}()

enum StarterPack {
    static let size = 8

    /// Eight cards: a Legendary to finish on, an Epic, and the closest skill matches spread across the cook's
    /// cuisines. Only dishes that fit every restriction are used; when the chosen cuisines run short, other
    /// cuisines fill in, so a pack is only smaller when fewer than eight dishes in the whole catalog fit.
    /// Cards are ordered lowest rarity first, so the rarest card is always the last reveal.
    static func build(experience: CookingExperience, cuisines: Set<String>, restrictions: Set<String> = []) -> [Recipe] {
        let allowed = recipeCatalog.filter { $0.fits(restrictions) }
        let pool = allowed.filter { cuisines.contains($0.cuisine) }
        let others = allowed.filter { !cuisines.contains($0.cuisine) }
        let distance = { (recipe: Recipe) in abs(recipe.skill.level - experience.level) }

        /// Prefers a nearby card of this tier from a chosen cuisine, then any from a chosen cuisine, then any that fits.
        func pick(_ tier: RarityTier) -> Recipe? {
            [pool, others].map { $0.filter { $0.tier == tier }.shuffled() }.lazy.compactMap { group in
                group.first { distance($0) <= 1 } ?? group.first
            }.first
        }

        var picks = [pick(.legendary), pick(.epic)].compactMap { $0 }
        let guaranteed = Set(picks)
        var byCuisine = cuisines.sorted().shuffled().map { cuisine in
            pool.filter { $0.cuisine == cuisine && $0.tier < .epic }
                .shuffled()
                .sorted { distance($0) < distance($1) }
        }
        while picks.count < size, byCuisine.contains(where: { !$0.isEmpty }) {
            for index in byCuisine.indices where !byCuisine[index].isEmpty && picks.count < size {
                picks.append(byCuisine[index].removeFirst())
            }
        }
        let fillers = (others + pool).filter { !guaranteed.contains($0) && !picks.contains($0) }
            .shuffled()
            .sorted { distance($0) < distance($1) }
        picks += fillers.prefix(size - picks.count)

        return picks.sorted { $0.score < $1.score }
    }
}
