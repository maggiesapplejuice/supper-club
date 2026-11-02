import Observation

enum OnboardingRoute: Hashable {
    case signUp
    case experience
    case cuisines
    case restrictions
    case location
}

enum CookingExperience: String, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case professional = "Professional"

    var id: Self { self }

    var detail: String {
        switch self {
        case .beginner: "I'm just starting to learn"
        case .intermediate: "I cook regularly and know basics"
        case .advanced: "I'm confident with complex dishes"
        case .professional: "I work or trained in gastronomy"
        }
    }

    var emoji: String {
        switch self {
        case .beginner: "🌱"
        case .intermediate: "🍳"
        case .advanced: "🔪"
        case .professional: "👩‍🍳"
        }
    }
}

struct OnboardingOption: Identifiable, Hashable {
    let name: String
    let emoji: String

    var id: String { name }
}

// Placeholder emoji stand in for the Figma cuisine photos until those are exported.
let cuisineOptions = [
    OnboardingOption(name: "Chinese", emoji: "🥟"),
    OnboardingOption(name: "French", emoji: "🥐"),
    OnboardingOption(name: "Greek", emoji: "🫒"),
    OnboardingOption(name: "Indian", emoji: "🍛"),
    OnboardingOption(name: "Italian", emoji: "🍝"),
    OnboardingOption(name: "Japanese", emoji: "🍣"),
    OnboardingOption(name: "Korean", emoji: "🍲"),
    OnboardingOption(name: "Mexican", emoji: "🌮"),
    OnboardingOption(name: "Thai", emoji: "🍜"),
    OnboardingOption(name: "Vietnamese", emoji: "🥢"),
]

struct RestrictionGroup: Identifiable {
    let title: String
    let emoji: String
    let options: [String]

    var id: String { title }
}

let restrictionGroups = [
    RestrictionGroup(title: "Diets", emoji: "🥦", options: [
        "Vegetarian", "Vegan", "Pescatarian", "Flexitarian", "Keto", "Paleo", "Whole30",
        "Low-carb", "Low-FODMAP", "Low-sodium", "Diabetic-friendly", "Raw food", "Carnivore",
    ]),
    RestrictionGroup(title: "Allergies & intolerances", emoji: "🌾", options: [
        "Gluten-free", "Celiac", "Dairy-free", "Lactose-free", "Peanut-free", "Tree nut-free",
        "Egg-free", "Soy-free", "Shellfish-free", "Fish-free", "Sesame-free", "Mustard-free",
        "Celery-free", "Lupin-free", "Sulfite-free", "Corn-free", "Nightshade-free",
        "Alpha-gal (no red meat)",
    ]),
    RestrictionGroup(title: "Religious & cultural", emoji: "🥖", options: [
        "Kosher", "Halal", "Jain", "Sattvic (no onion or garlic)", "Ital", "No beef", "No pork",
        "Meatless Fridays",
    ]),
    RestrictionGroup(title: "Sourcing & sensitivities", emoji: "🌱", options: [
        "Non-GMO", "Organic", "Locally sourced", "No seed oils", "No artificial dyes",
        "No added sugar", "Alcohol-free", "Caffeine-free",
    ]),
    RestrictionGroup(title: "Health conditions", emoji: "🍲", options: [
        "IBS", "Crohn's or colitis", "GERD / acid reflux", "Gastroparesis", "Diverticulitis",
        "SIBO", "Fructose malabsorption", "Eosinophilic esophagitis (EoE)", "Gallbladder disease",
        "Pancreatitis", "Gout", "Kidney disease", "Kidney stones", "Heart disease",
        "High blood pressure", "PKU", "G6PD deficiency", "Histamine intolerance / MCAS",
        "Hashimoto's", "Interstitial cystitis", "Migraine triggers", "Low-histamine",
        "AIP (autoimmune protocol)", "Low-oxalate", "Pregnancy-safe",
    ]),
]

@MainActor
@Observable
final class OnboardingModel {
    var path: [OnboardingRoute] = []
    var experience: CookingExperience?
    var cuisines: Set<String> = []
    var restrictions: Set<String> = []
    var isFinished = false
    var collection: [Recipe] = []
    var unopenedPack: [Recipe]?
    var trades: [TradeOffer] = []
    var savedCardIDs: Set<String> = []
    /// Dishes swiped right on Discover, newest first, waiting for an offer in Trading.
    var interested: [Recipe] = []
    /// Chefs the cook saved, newest first.
    var favoriteChefs: [CookProfile] = []

    var pendingCardIDs: Set<String> {
        Set(trades.flatMap { $0.offered.map(\.id) })
    }

    // No backend yet: logging in and signing up only move through the flow.
    func logIn() {
        isFinished = true
    }

    func signUp() {
        path.append(.experience)
    }

    func goBack() {
        path.removeLast()
    }

    func finish() {
        // A very strict combination of restrictions can leave nothing to put in the pack.
        if let experience {
            let pack = StarterPack.build(experience: experience, cuisines: cuisines, restrictions: restrictions)
            unopenedPack = pack.isEmpty ? nil : pack
        }
        isFinished = true
    }

    func send(offered: [Recipe], requested: Recipe) {
        trades.insert(TradeOffer(offered: offered, requested: requested), at: 0)
        interested.removeAll { $0 == requested }
    }

    func markInterested(_ recipe: Recipe) {
        guard !interested.contains(recipe) else { return }
        interested.insert(recipe, at: 0)
    }

    func isFavorite(_ chef: CookProfile) -> Bool {
        favoriteChefs.contains(chef)
    }

    func toggleFavorite(_ chef: CookProfile) {
        if let index = favoriteChefs.firstIndex(of: chef) {
            favoriteChefs.remove(at: index)
        } else {
            favoriteChefs.insert(chef, at: 0)
        }
    }

    func removeInterest(_ recipe: Recipe) {
        interested.removeAll { $0 == recipe }
    }

    func cancel(_ trade: TradeOffer) {
        trades.removeAll { $0.id == trade.id }
    }

    func collectPack() {
        collection += unopenedPack ?? []
        unopenedPack = nil
    }
}
