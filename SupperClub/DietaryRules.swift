import Foundation

/// What a dish contains, at the level dietary restrictions care about.
enum Ingredient: String, CaseIterable {
    case beef, pork, lamb, poultry, fish, shellfish, egg, dairy
    case gluten, peanut, treeNut, soy, sesame, mustard, celery, sulfites, corn
    case nightshade, alliums, mushroom, legumes, rootVeg
    case starch, sugar, alcohol, caffeine, fermented, salty, seedOil
    case spicy, highFat, acidic, rawProtein
    case cooked

    var label: String {
        switch self {
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
private let paleo: Set<Ingredient> = [.starch, .legumes, .peanut, .soy, .dairy, .sugar, .corn, .seedOil]
private let lowFODMAP: Set<Ingredient> = [.alliums, .gluten, .legumes, .dairy, .mushroom]
private let fibrous: Set<Ingredient> = [.legumes, .treeNut, .peanut, .sesame, .corn, .mushroom]

/// What each listed restriction rules out. Restrictions missing here, like Organic or anything typed in,
/// are about sourcing or too specific to check, so they don't hide recipes.
private let excludedIngredients: [String: Set<Ingredient>] = [
    "Vegetarian": meat.union([.fish, .shellfish]),
    "Vegan": meat.union([.fish, .shellfish, .egg, .dairy]),
    "Pescatarian": meat,
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

    "Kosher": [.pork, .shellfish],
    "Halal": [.pork, .alcohol],
    "Jain": meat.union([.fish, .shellfish, .egg, .alliums, .rootVeg, .mushroom]),
    "Sattvic (no onion or garlic)": meat.union([.fish, .shellfish, .egg, .alliums, .mushroom, .alcohol, .caffeine]),
    "Ital": meat.union([.fish, .shellfish, .alcohol]),
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
    "PKU": meat.union([.fish, .shellfish, .egg, .dairy, .legumes, .soy, .treeNut, .peanut]),
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
    var contents: Set<Ingredient> { recipeContents[name] ?? [] }

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

/// Raw is the exception, so `.cooked` is added to every dish not listed in `rawDishes`.
private let rawDishes: Set<String> = ["Guacamole", "Horiatiki Salad"]

private let recipeContents: [String: Set<Ingredient>] = Dictionary(uniqueKeysWithValues: taggedDishes.map { name, contents in
    (name, rawDishes.contains(name) ? contents : contents.union([.cooked]))
})

// Typical versions of each dish. Real recipes vary, so these are a best guess until cards carry ingredient lists.
private let taggedDishes: [String: Set<Ingredient>] = [
    // Chinese
    "Egg Fried Rice": [.egg, .starch, .soy, .gluten, .alliums, .seedOil, .salty],
    "Scallion Pancakes": [.gluten, .starch, .alliums, .seedOil, .highFat],
    "Mapo Tofu": [.soy, .beef, .nightshade, .fermented, .gluten, .alliums, .salty, .seedOil, .spicy],
    "Yunnan Wild Mushroom Hot Pot": [.mushroom, .poultry, .alliums, .salty],
    "Xiao Long Bao": [.pork, .gluten, .starch, .soy, .alliums, .alcohol, .fermented, .salty, .highFat],
    "Buddha Jumps Over the Wall": [.shellfish, .fish, .poultry, .pork, .mushroom, .alcohol, .soy, .gluten, .salty, .fermented, .sulfites],
    "Peking Duck": [.poultry, .gluten, .starch, .sugar, .soy, .sesame, .fermented, .alliums, .salty, .highFat],
    "Hand-Pulled Lanzhou Noodles": [.gluten, .starch, .beef, .alliums, .nightshade, .seedOil, .salty, .spicy],
    // French
    "Croque Monsieur": [.pork, .dairy, .gluten, .starch, .mustard, .fermented, .salty, .highFat],
    "Ratatouille": [.nightshade, .alliums, .acidic],
    "Coq au Vin": [.poultry, .pork, .alcohol, .sulfites, .mushroom, .alliums, .dairy, .gluten, .fermented, .highFat],
    "Black Truffle Scrambled Eggs": [.egg, .dairy, .mushroom, .highFat],
    "Butter Croissants": [.gluten, .dairy, .egg, .starch, .sugar, .highFat],
    "Bouillabaisse de Marseille": [.fish, .shellfish, .nightshade, .alliums, .gluten, .egg, .rootVeg, .starch, .acidic],
    "Grand Marnier Soufflé": [.egg, .dairy, .sugar, .alcohol, .gluten, .highFat, .acidic],
    "Canard à la Presse": [.poultry, .alcohol, .sulfites, .dairy, .fermented, .highFat],
    // Greek
    "Horiatiki Salad": [.dairy, .nightshade, .alliums, .fermented, .salty, .acidic],
    "Tzatziki with Pita": [.dairy, .gluten, .starch, .alliums],
    "Spanakopita": [.gluten, .dairy, .egg, .alliums, .starch, .highFat],
    "Chios Mastic Rice Pudding": [.dairy, .starch, .sugar],
    "Moussaka": [.lamb, .nightshade, .dairy, .egg, .gluten, .alliums, .rootVeg, .highFat, .acidic],
    "Lamb Kleftiko": [.lamb, .rootVeg, .starch, .alliums, .dairy, .nightshade, .highFat, .acidic],
    "Galaktoboureko": [.gluten, .dairy, .egg, .sugar, .starch, .highFat],
    "Kokoretsi": [.lamb, .highFat],
    // Indian
    "Dal Tadka": [.legumes, .alliums, .nightshade, .dairy, .spicy, .acidic],
    "Jeera Aloo": [.rootVeg, .starch, .nightshade, .seedOil, .spicy],
    "Chana Masala": [.legumes, .alliums, .nightshade, .seedOil, .spicy, .acidic],
    "Kashmiri Morel Pulao": [.mushroom, .starch, .dairy, .treeNut, .alliums],
    "Butter Chicken": [.poultry, .dairy, .nightshade, .treeNut, .alliums, .sugar, .highFat, .acidic],
    "Hyderabadi Dum Biryani": [.lamb, .starch, .dairy, .alliums, .nightshade, .seedOil, .spicy, .highFat],
    "Malai Kofta": [.dairy, .treeNut, .rootVeg, .nightshade, .alliums, .seedOil, .starch, .sugar, .highFat],
    "Galouti Kebab": [.lamb, .alliums, .dairy, .highFat],
    // Italian
    "Spaghetti Aglio e Olio": [.gluten, .starch, .alliums, .nightshade, .spicy],
    "Tomato Bruschetta": [.gluten, .starch, .nightshade, .alliums, .acidic],
    "Risotto alla Milanese": [.starch, .dairy, .alcohol, .sulfites, .alliums, .beef],
    "Wild Mushroom & Truffle Risotto": [.starch, .dairy, .mushroom, .alcohol, .sulfites, .alliums],
    "Hand-Rolled Orecchiette": [.gluten, .starch, .alliums, .fish, .nightshade, .spicy],
    "Culatello Tortellini in Brodo": [.gluten, .egg, .pork, .beef, .dairy, .starch, .fermented, .salty, .highFat],
    "Osso Buco": [.beef, .alcohol, .sulfites, .gluten, .celery, .alliums, .nightshade, .dairy, .highFat, .acidic],
    "Sfogliatella": [.gluten, .dairy, .egg, .sugar, .starch, .highFat],
    // Japanese
    "Tamago Kake Gohan": [.egg, .starch, .soy, .gluten, .salty, .rawProtein],
    "Miso Soup": [.soy, .fermented, .fish, .salty, .alliums],
    "Chicken Katsu Curry": [.poultry, .gluten, .egg, .starch, .seedOil, .alliums, .rootVeg, .sugar, .highFat],
    "Matsutake Gohan": [.mushroom, .starch, .soy, .gluten, .fish, .alcohol, .salty],
    "Tonkotsu Ramen": [.pork, .gluten, .starch, .egg, .soy, .alliums, .sesame, .salty, .fermented, .highFat],
    "Wagyu Sukiyaki": [.beef, .soy, .gluten, .sugar, .alcohol, .egg, .mushroom, .alliums, .salty, .highFat, .rawProtein],
    "Edomae Nigiri": [.fish, .shellfish, .starch, .sugar, .soy, .gluten, .fermented, .acidic, .rawProtein],
    "Hand-Cut Juwari Soba": [.starch, .soy, .gluten, .fish, .alcohol, .salty],
    // Korean
    "Kimchi Fried Rice": [.starch, .fermented, .nightshade, .fish, .shellfish, .egg, .pork, .alliums, .sesame, .seedOil, .salty, .soy, .gluten, .spicy, .acidic],
    "Gyeran-jjim": [.egg, .alliums, .salty, .shellfish, .sesame],
    "Bibimbap": [.starch, .egg, .beef, .sesame, .soy, .gluten, .nightshade, .fermented, .sugar, .alliums, .spicy],
    "Temple Doenjang Jjigae": [.soy, .fermented, .nightshade, .mushroom, .salty, .rootVeg],
    "Yangnyeom Fried Chicken": [.poultry, .gluten, .starch, .seedOil, .nightshade, .sugar, .soy, .alliums, .peanut, .sesame, .spicy, .highFat],
    "Royal Court Sinseollo": [.beef, .fish, .shellfish, .egg, .mushroom, .treeNut, .soy, .gluten, .sesame],
    "Homemade Baechu Kimchi": [.fermented, .fish, .shellfish, .nightshade, .alliums, .sugar, .salty, .spicy, .acidic],
    "Gujeolpan": [.gluten, .beef, .shellfish, .egg, .mushroom, .sesame, .soy],
    // Mexican
    "Guacamole": [.alliums, .nightshade, .spicy, .acidic],
    "Cheese Quesadillas": [.dairy, .corn, .starch, .highFat],
    "Chicken Fajitas": [.poultry, .nightshade, .alliums, .gluten, .starch, .seedOil, .acidic],
    "Huitlacoche Quesadillas": [.corn, .mushroom, .dairy, .alliums, .nightshade, .starch, .highFat],
    "Pork Tamales": [.pork, .corn, .starch, .nightshade, .alliums, .spicy, .highFat],
    "Mole Negro Oaxaqueño": [.poultry, .nightshade, .caffeine, .sugar, .treeNut, .sesame, .gluten, .alliums, .seedOil, .sulfites, .spicy],
    "Cochinita Pibil": [.pork, .alliums, .nightshade, .corn, .starch, .spicy, .highFat, .acidic],
    "Chiles en Nogada": [.pork, .beef, .nightshade, .treeNut, .dairy, .sugar, .egg, .sulfites, .alliums, .highFat],
    // Thai
    "Pad Krapow": [.poultry, .nightshade, .alliums, .fish, .soy, .gluten, .shellfish, .sugar, .egg, .starch, .seedOil, .salty, .spicy],
    "Kai Jeow Omelette": [.egg, .fish, .seedOil, .salty, .starch],
    "Pad Thai": [.starch, .egg, .shellfish, .peanut, .soy, .fish, .sugar, .alliums, .nightshade, .seedOil, .salty, .spicy, .acidic],
    "Khao Yam Rice Salad": [.starch, .fish, .fermented, .shellfish, .alliums, .salty, .acidic],
    "Massaman Curry": [.beef, .peanut, .rootVeg, .nightshade, .alliums, .fish, .shellfish, .sugar, .seedOil, .spicy, .highFat],
    "Gaeng Tai Pla": [.fish, .fermented, .shellfish, .nightshade, .alliums, .salty, .spicy, .acidic],
    "Khao Soi": [.poultry, .gluten, .egg, .starch, .nightshade, .alliums, .fish, .shellfish, .seedOil, .sugar, .spicy, .highFat],
    "Chor Muang Dumplings": [.starch, .pork, .alliums, .fish, .sugar],
    // Vietnamese
    "Gỏi Cuốn": [.shellfish, .pork, .starch, .peanut, .soy, .gluten, .sugar, .alliums, .acidic],
    "Bánh Mì": [.gluten, .starch, .pork, .egg, .soy, .sugar, .fermented, .alliums, .nightshade, .salty, .spicy, .acidic],
    "Bún Chả": [.pork, .starch, .fish, .sugar, .alliums, .nightshade, .salty, .acidic],
    "Cao Lầu of Hội An": [.pork, .starch, .soy, .alliums, .sugar, .seedOil],
    "Phở Bò": [.beef, .starch, .fish, .alliums, .sugar, .salty, .acidic],
    "Chả Cá Lã Vọng": [.fish, .starch, .peanut, .shellfish, .fermented, .alliums, .seedOil, .highFat],
    "Bánh Xèo": [.shellfish, .pork, .starch, .seedOil, .fish, .sugar, .alliums, .legumes, .highFat],
    "Bánh Bèo of Huế": [.starch, .shellfish, .pork, .fish, .seedOil, .sugar, .alliums, .highFat],
]
