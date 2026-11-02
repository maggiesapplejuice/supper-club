import Foundation

struct CookProfile {
    let name: String
    let detail: String

    var shortName: String {
        let parts = name.split(separator: " ")
        guard parts.count > 1, let initial = parts.last?.first else { return name }
        return "\(parts[0]) \(initial)."
    }
}

struct PastTrade: Identifiable {
    let from: CookProfile
    let to: CookProfile
    let age: String

    var id: String { from.name + to.name + age }
}

struct TradeOffer: Identifiable {
    let id = UUID()
    let offered: [Recipe]
    let requested: Recipe
}

// Sample people and history until there's a backend. Everything derives from the recipe's name,
// so a card always shows the same details.
private let sampleCooks = [
    CookProfile(name: "Alex Rivera", detail: "Collector"),
    CookProfile(name: "Sarah Mitchell", detail: "Home cook"),
    CookProfile(name: "Marco Keller", detail: "Line cook"),
    CookProfile(name: "Priya Nair", detail: "Supper host"),
    CookProfile(name: "Jun Tanaka", detail: "Collector"),
    CookProfile(name: "Lena Okafor", detail: "Recipe tester"),
]

private let sampleCreators = [
    CookProfile(name: "Chef Julian Rossi", detail: "Milan, IT"),
    CookProfile(name: "Chef Mei Lin", detail: "Taipei, TW"),
    CookProfile(name: "Chef Amara Diallo", detail: "Paris, FR"),
    CookProfile(name: "Chef Rosa Vega", detail: "Oaxaca, MX"),
]

extension Recipe {
    private var seed: Int { name.unicodeScalars.reduce(0) { $0 + Int($1.value) } }

    var owner: CookProfile { sampleCooks[seed % sampleCooks.count] }
    var creator: CookProfile { sampleCreators[seed % sampleCreators.count] }

    /// Rarely traded cards score the most trade-frequency points, so these two always agree.
    var tradeFrequency: String {
        switch tradeScarcity {
        case 20...: "Low"
        case 12..<20: "Medium"
        default: "High"
        }
    }

    var timesTraded: Int { (RarityFactor.maxPoints + 1 - tradeScarcity) * 2 + seed % 3 }

    var createdLabel: String {
        let months = ["Jan", "Mar", "May", "Jun", "Aug", "Oct"]
        return "\(months[seed % months.count]) \(seed % 27 + 1), 2026"
    }

    var cookTimeLabel: String {
        minutes < 120 ? "\(minutes) min" : "\(minutes / 60) hr"
    }

    var recentTrades: [PastTrade] {
        let previous = sampleCooks[(seed + 1) % sampleCooks.count]
        let earlier = sampleCooks[(seed + 2) % sampleCooks.count]
        return [
            PastTrade(from: previous, to: owner, age: "\(seed % 6 + 1)d ago"),
            PastTrade(from: earlier, to: previous, age: "\(seed % 3 + 1)w ago"),
        ]
    }
}
