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

let restrictionOptions = [
    OnboardingOption(name: "Vegetarian", emoji: "🥦"),
    OnboardingOption(name: "Vegan", emoji: "🌱"),
    OnboardingOption(name: "Gluten-free", emoji: "🌾"),
    OnboardingOption(name: "Nut-free", emoji: "🌰"),
    OnboardingOption(name: "Dairy-free", emoji: "🥛"),
    OnboardingOption(name: "Egg-free", emoji: "🥚"),
    OnboardingOption(name: "Shellfish-free", emoji: "🦐"),
]

@MainActor
@Observable
final class OnboardingModel {
    var path: [OnboardingRoute] = []
    var experience: CookingExperience?
    var cuisines: Set<String> = []
    var restrictions: Set<String> = []
    var isFinished = false

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
        isFinished = true
    }
}
