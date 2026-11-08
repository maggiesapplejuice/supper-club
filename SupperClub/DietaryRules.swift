import Foundation

/// What a dish contains, at the level dietary restrictions care about.
enum Ingredient: String, CaseIterable {
    case beef, pork, lamb, poultry, gelatin, fish, shellfish, egg, dairy
    case gluten, peanut, treeNut, soy, sesame, mustard, celery, sulfites, corn
    case nightshade, alliums, mushroom, legumes, rootVeg
    case starch, sugar, alcohol, caffeine, fermented, salty, seedOil
    case spicy, highFat, acidic, rawProtein
    case cooked

    var label: String {
        switch self {
        case .lamb: "lamb or goat"
        case .treeNut: "tree nuts"
        case .rootVeg: "root vegetables"
        case .alliums: "onion or garlic"
        case .starch: "rice, noodles or bread"
        case .sugar: "added sugar"
        case .seedOil: "seed oil"
        case .fermented: "fermented or aged foods"
        case .salty: "high sodium"
        case .nightshade: "nightshades"
        case .mushroom: "mushrooms"
        case .legumes: "legumes"
        case .sulfites: "sulfites"
        case .spicy: "chili heat"
        case .highFat: "rich or fried"
        case .acidic: "tomato, citrus or vinegar"
        case .rawProtein: "raw fish or egg"
        case .cooked: "cooked food"
        default: rawValue
        }
    }
}

private let meat: Set<Ingredient> = [.beef, .pork, .lamb, .poultry]
/// Meat plus what's made from it, for diets that avoid animal products rather than just meat dishes.
private let animal: Set<Ingredient> = meat.union([.gelatin])
private let paleo: Set<Ingredient> = [.starch, .legumes, .peanut, .soy, .dairy, .sugar, .corn, .seedOil]
private let lowFODMAP: Set<Ingredient> = [.alliums, .gluten, .legumes, .dairy, .mushroom]
private let fibrous: Set<Ingredient> = [.legumes, .treeNut, .peanut, .sesame, .corn, .mushroom]

/// What each listed restriction rules out. Restrictions missing here, like Organic or anything typed in,
/// are about sourcing or too specific to check, so they don't hide recipes.
private let excludedIngredients: [String: Set<Ingredient>] = [
    "Vegetarian": animal.union([.fish, .shellfish]),
    "Vegan": animal.union([.fish, .shellfish, .egg, .dairy]),
    "Pescatarian": animal,
    "Keto": [.starch, .sugar],
    "Paleo": paleo,
    "Whole30": paleo.union([.alcohol]),
    "Low-carb": [.starch, .sugar],
    "Low-FODMAP": lowFODMAP,
    "Low-sodium": [.salty],
    "Diabetic-friendly": [.sugar],
    "Raw food": [.cooked],
    "Carnivore": [.starch, .legumes, .sugar, .mushroom, .rootVeg, .soy],

    "Gluten-free": [.gluten],
    "Celiac": [.gluten],
    "Dairy-free": [.dairy],
    "Lactose-free": [.dairy],
    "Peanut-free": [.peanut],
    "Tree nut-free": [.treeNut],
    "Egg-free": [.egg],
    "Soy-free": [.soy],
    "Shellfish-free": [.shellfish],
    "Fish-free": [.fish],
    "Sesame-free": [.sesame],
    "Mustard-free": [.mustard],
    "Celery-free": [.celery],
    "Lupin-free": [],
    "Sulfite-free": [.sulfites],
    "Corn-free": [.corn],
    "Nightshade-free": [.nightshade],
    "Alpha-gal (no red meat)": [.beef, .pork, .lamb],

    "Kosher": [.pork, .shellfish, .gelatin],
    "Halal": [.pork, .alcohol, .gelatin],
    "Jain": animal.union([.fish, .shellfish, .egg, .alliums, .rootVeg, .mushroom]),
    "Sattvic (no onion or garlic)": animal.union([.fish, .shellfish, .egg, .alliums, .mushroom, .alcohol, .caffeine]),
    "Ital": animal.union([.fish, .shellfish, .alcohol]),
    "No beef": [.beef],
    "No pork": [.pork],

    "No seed oils": [.seedOil],
    "No artificial dyes": [],
    "No added sugar": [.sugar],
    "Alcohol-free": [.alcohol],
    "Caffeine-free": [.caffeine],
    "Low-histamine": [.fermented, .fish, .shellfish, .alcohol],
    "AIP (autoimmune protocol)": paleo.union([.nightshade, .egg, .treeNut, .sesame, .caffeine, .alcohol]),
    "Low-oxalate": [.legumes, .soy, .treeNut, .peanut, .caffeine, .rootVeg],

    // Common trigger foods for each condition. Everyone's triggers differ, so this is a starting filter,
    // not medical advice.
    "IBS": lowFODMAP.union([.spicy]),
    "Crohn's or colitis": fibrous.union([.spicy, .highFat, .alcohol, .caffeine]),
    "GERD / acid reflux": [.spicy, .acidic, .highFat, .alliums, .caffeine, .alcohol],
    "Gastroparesis": fibrous.union([.highFat]),
    "Diverticulitis": fibrous,
    "SIBO": lowFODMAP.union([.sugar]),
    "Fructose malabsorption": [.sugar, .alliums, .gluten],
    "Eosinophilic esophagitis (EoE)": [.dairy, .gluten, .egg, .soy, .peanut, .treeNut, .fish, .shellfish],
    "Gallbladder disease": [.highFat],
    "Pancreatitis": [.highFat, .alcohol],
    "Gout": [.beef, .lamb, .pork, .fish, .shellfish, .alcohol, .sugar],
    "Kidney disease": [.salty, .fermented, .rootVeg, .nightshade, .dairy, .legumes, .treeNut, .peanut],
    "Kidney stones": [.legumes, .soy, .treeNut, .peanut, .caffeine, .rootVeg, .salty],
    "Heart disease": [.salty, .highFat],
    "High blood pressure": [.salty, .alcohol],
    "PKU": animal.union([.fish, .shellfish, .egg, .dairy, .legumes, .soy, .treeNut, .peanut]),
    "G6PD deficiency": [.legumes],
    "Histamine intolerance / MCAS": [.fermented, .fish, .shellfish, .alcohol, .acidic],
    "Hashimoto's": [.gluten],
    "Interstitial cystitis": [.acidic, .spicy, .caffeine, .alcohol],
    "Migraine triggers": [.fermented, .alcohol, .caffeine],
    "Pregnancy-safe": [.rawProtein, .alcohol],
]

/// Restrictions that actually hide recipes, in the order the picker lists them.
func recipeFilters(in restrictions: Set<String>) -> [String] {
    restrictionGroups.flatMap(\.options).filter {
        restrictions.contains($0) && (excludedIngredients[$0] != nil || $0 == "Meatless Fridays")
    }
}

struct DietConflict: Hashable {
    let restriction: String
    let reason: String
}

extension Recipe {
    /// Every chosen restriction this dish breaks, with what breaks it.
    func conflicts(with restrictions: Set<String>, on date: Date = .now) -> [DietConflict] {
        restrictions.sorted().compactMap { restriction in
            var excluded = excludedIngredients[restriction] ?? []
            if restriction == "Meatless Fridays" && Calendar.current.component(.weekday, from: date) == 6 {
                excluded = meat
            }
            var reasons = Ingredient.allCases.filter(contents.intersection(excluded).contains).map(\.label)
            // Kosher rules out meat and dairy in the same dish, not either one alone.
            if restriction == "Kosher" && !contents.isDisjoint(with: meat) && contents.contains(.dairy) {
                reasons.append("meat with dairy")
            }
            guard !reasons.isEmpty else { return nil }
            return DietConflict(restriction: restriction, reason: reasons.joined(separator: ", "))
        }
    }

    func fits(_ restrictions: Set<String>) -> Bool {
        conflicts(with: restrictions).isEmpty
    }
}
