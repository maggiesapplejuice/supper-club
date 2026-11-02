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

    var color: Color { self == .common ? .gray4 : .ink }
}

struct RarityFactor: Identifiable {
    let name: String
    let detail: String
    let points: Int

    var id: String { name }
    static let maxPoints = 25
}

struct Recipe: Identifiable, Hashable {
    let name: String
    let emoji: String
    let cuisine: String
    let skill: CookingExperience
    let minutes: Int
    let technique: Int
    let ingredients: Int
    let heritage: Int
    let tradeScarcity: Int

    var id: String { name }
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
}

extension CookingExperience {
    var level: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

private typealias Dish = (name: String, emoji: String, minutes: Int)

// Rarity points are placeholders until there's real trading data. Each cuisine lists eight dishes in
// the order of `slots`, so every cuisine can supply cards at every skill level and rarity.
private let slots: [(skill: CookingExperience, technique: Int, ingredients: Int, heritage: Int, trade: Int)] = [
    (.beginner, 5, 5, 8, 6),
    (.beginner, 10, 12, 12, 12),
    (.intermediate, 14, 11, 14, 12),
    (.intermediate, 18, 22, 25, 25),
    (.advanced, 20, 14, 17, 15),
    (.advanced, 23, 22, 24, 23),
    (.professional, 22, 16, 17, 15),
    (.professional, 25, 18, 20, 20),
]

private func recipes(_ cuisine: String, _ dishes: [Dish]) -> [Recipe] {
    zip(slots, dishes).map { slot, dish in
        // Moves a few points between technique and ingredients so cards differ without changing tier.
        let shift = dish.name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 5 - 2
        return Recipe(
            name: dish.name,
            emoji: dish.emoji,
            cuisine: cuisine,
            skill: slot.skill,
            minutes: dish.minutes,
            technique: slot.technique + shift,
            ingredients: slot.ingredients - shift,
            heritage: slot.heritage,
            tradeScarcity: slot.trade
        )
    }
}

let recipeCatalog: [Recipe] = [
    recipes("Chinese", [
        ("Egg Fried Rice", "🍚", 15), ("Scallion Pancakes", "🥞", 40), ("Mapo Tofu", "🌶️", 30),
        ("Yunnan Wild Mushroom Hot Pot", "🍄", 60), ("Xiao Long Bao", "🥟", 180),
        ("Buddha Jumps Over the Wall", "🍲", 480), ("Peking Duck", "🦆", 1440), ("Hand-Pulled Lanzhou Noodles", "🍜", 120),
    ]),
    recipes("French", [
        ("Croque Monsieur", "🥪", 20), ("Ratatouille", "🍆", 60), ("Coq au Vin", "🍗", 120),
        ("Black Truffle Scrambled Eggs", "🍳", 25), ("Butter Croissants", "🥐", 720),
        ("Bouillabaisse de Marseille", "🐟", 150), ("Grand Marnier Soufflé", "🍮", 60), ("Canard à la Presse", "🦆", 180),
    ]),
    recipes("Greek", [
        ("Horiatiki Salad", "🥗", 15), ("Tzatziki with Pita", "🥒", 25), ("Spanakopita", "🥧", 75),
        ("Chios Mastic Rice Pudding", "🍮", 50), ("Moussaka", "🍆", 150),
        ("Lamb Kleftiko", "🍖", 300), ("Galaktoboureko", "🍰", 120), ("Kokoretsi", "🔥", 240),
    ]),
    recipes("Indian", [
        ("Dal Tadka", "🍲", 35), ("Jeera Aloo", "🥔", 25), ("Chana Masala", "🫘", 45),
        ("Kashmiri Morel Pulao", "🍄", 60), ("Butter Chicken", "🍛", 90),
        ("Hyderabadi Dum Biryani", "🍚", 180), ("Malai Kofta", "🍛", 90), ("Galouti Kebab", "🍢", 240),
    ]),
    recipes("Italian", [
        ("Spaghetti Aglio e Olio", "🍝", 20), ("Tomato Bruschetta", "🍅", 15), ("Risotto alla Milanese", "🍚", 40),
        ("Wild Mushroom & Truffle Risotto", "🍄", 45), ("Hand-Rolled Orecchiette", "🍝", 90),
        ("Culatello Tortellini in Brodo", "🥟", 240), ("Osso Buco", "🍖", 180), ("Sfogliatella", "🥐", 300),
    ]),
    recipes("Japanese", [
        ("Tamago Kake Gohan", "🍚", 10), ("Miso Soup", "🍲", 15), ("Chicken Katsu Curry", "🍛", 50),
        ("Matsutake Gohan", "🍄", 60), ("Tonkotsu Ramen", "🍜", 720),
        ("Wagyu Sukiyaki", "🥩", 45), ("Edomae Nigiri", "🍣", 120), ("Hand-Cut Juwari Soba", "🍜", 90),
    ]),
    recipes("Korean", [
        ("Kimchi Fried Rice", "🍚", 15), ("Gyeran-jjim", "🥚", 15), ("Bibimbap", "🥗", 45),
        ("Temple Doenjang Jjigae", "🍲", 40), ("Yangnyeom Fried Chicken", "🍗", 70),
        ("Royal Court Sinseollo", "🍲", 180), ("Homemade Baechu Kimchi", "🥬", 1440), ("Gujeolpan", "🍱", 150),
    ]),
    recipes("Mexican", [
        ("Guacamole", "🥑", 10), ("Cheese Quesadillas", "🧀", 15), ("Chicken Fajitas", "🌮", 35),
        ("Huitlacoche Quesadillas", "🌽", 35), ("Pork Tamales", "🫔", 180),
        ("Mole Negro Oaxaqueño", "🍫", 480), ("Cochinita Pibil", "🐖", 480), ("Chiles en Nogada", "🌶️", 180),
    ]),
    recipes("Thai", [
        ("Pad Krapow", "🌿", 15), ("Kai Jeow Omelette", "🍳", 10), ("Pad Thai", "🍜", 30),
        ("Khao Yam Rice Salad", "🍚", 45), ("Massaman Curry", "🍛", 150),
        ("Gaeng Tai Pla", "🐟", 120), ("Khao Soi", "🍜", 90), ("Chor Muang Dumplings", "🌸", 180),
    ]),
    recipes("Vietnamese", [
        ("Gỏi Cuốn", "🥢", 25), ("Bánh Mì", "🥖", 30), ("Bún Chả", "🍢", 60),
        ("Cao Lầu of Hội An", "🍜", 90), ("Phở Bò", "🍜", 480),
        ("Chả Cá Lã Vọng", "🐟", 90), ("Bánh Xèo", "🥞", 60), ("Bánh Bèo of Huế", "🍚", 120),
    ]),
].flatMap { $0 }

enum StarterPack {
    static let size = 6

    /// One Legendary near the cook's skill level, plus the closest skill matches spread across their cuisines.
    /// Only dishes that fit every restriction are used; when the chosen cuisines run short, other cuisines fill in.
    /// Cards are ordered lowest rarity first, so the holographic card is always the last reveal.
    static func build(experience: CookingExperience, cuisines: Set<String>, restrictions: Set<String> = []) -> [Recipe] {
        let allowed = recipeCatalog.filter { $0.fits(restrictions) }
        let pool = allowed.filter { cuisines.contains($0.cuisine) }
        let others = allowed.filter { !cuisines.contains($0.cuisine) }
        let distance = { (recipe: Recipe) in abs(recipe.skill.level - experience.level) }

        // Prefer a nearby Legendary from a chosen cuisine, then any from a chosen cuisine, then any that fits.
        let legendaries = [pool, others].map { $0.filter { $0.tier == .legendary }.shuffled() }
        let holo = legendaries.lazy.compactMap { group in
            group.first { distance($0) <= 1 } ?? group.first
        }.first

        var byCuisine = cuisines.sorted().shuffled().map { cuisine in
            pool.filter { $0.cuisine == cuisine && $0.tier != .legendary }
                .shuffled()
                .sorted { distance($0) < distance($1) }
        }

        var picks: [Recipe] = []
        while picks.count < size - 1, byCuisine.contains(where: { !$0.isEmpty }) {
            for index in byCuisine.indices where !byCuisine[index].isEmpty && picks.count < size - 1 {
                picks.append(byCuisine[index].removeFirst())
            }
        }
        let fillers = others.filter { $0.tier != .legendary }.shuffled().sorted { distance($0) < distance($1) }
        picks += fillers.prefix(size - 1 - picks.count)

        return picks.sorted { $0.score < $1.score } + (holo.map { [$0] } ?? [])
    }
}
