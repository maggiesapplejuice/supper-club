import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case discover = "Discover"
    case inventory = "Inventory"
    case profile = "Profile"

    var id: Self { self }

    var systemImage: String {
        switch self {
        case .discover: "safari.fill"
        case .inventory: "rectangle.stack.fill"
        case .profile: "person.fill"
        }
    }
}

struct MainTabView: View {
    let model: OnboardingModel
    @State private var tab = MainTab.discover

    var body: some View {
        // Each tab places the bar in its own root screen, so pushed screens cover it.
        switch tab {
        case .discover: DiscoverView(model: model, tab: $tab)
        case .inventory: InventoryView(model: model, tab: $tab)
        case .profile: ProfileView(model: model, tab: $tab)
        }
    }
}

struct InkTabBar: View {
    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 22) {
            ForEach(MainTab.allCases) { item in
                let isSelected = item == selection
                Button { selection = item } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 18))
                            .foregroundStyle(isSelected ? .white : Color.ink)
                            .frame(width: 54, height: 54)
                            .background(isSelected ? Color.ink : .white, in: .circle)
                            .overlay { Circle().stroke(Color.ink, lineWidth: 2) }
                        Text(item.rawValue)
                            .font(isSelected ? .display(11) : .text(11))
                            .foregroundStyle(Color.ink)
                    }
                }
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .background(Color.paper)
    }
}

struct InkChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? .display(13) : .text(13))
                .foregroundStyle(isSelected ? .white : Color.ink)
                .padding(.horizontal, 14)
                .frame(height: 34)
                .background(isSelected ? Color.ink : .white, in: .capsule)
                .overlay { Capsule().stroke(Color.ink, lineWidth: 2) }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct InkSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .bold))
            TextField(placeholder, text: $text)
                .font(.text(14))
                .autocorrectionDisabled()
        }
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(.white, in: .capsule)
        .overlay { Capsule().stroke(Color.ink, lineWidth: 2) }
    }
}

struct InventoryView: View {
    let model: OnboardingModel
    @Binding var tab: MainTab
    @State private var detailRecipe: Recipe?

    private var sorted: [Recipe] { model.collection.sorted { $0.score > $1.score } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("My Recipe Cards")
                    .font(.display(30))
                    .foregroundStyle(Color.ink)
                if !model.pendingCardIDs.isEmpty {
                    pendingBanner
                }
                if sorted.isEmpty {
                    Text("Cards you collect will show up here.")
                        .font(.text(15))
                        .foregroundStyle(Color.gray4)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 18) {
                        ForEach(sorted) { recipe in
                            Button { detailRecipe = recipe } label: {
                                LiveCardView(recipe: recipe, width: 160)
                                    .compositingGroup()
                                    .opacity(model.pendingCardIDs.contains(recipe.id) ? 0.4 : 1)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint("Shows rarity details")
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color.paper)
        .safeAreaInset(edge: .bottom) { InkTabBar(selection: $tab) }
        .sheet(item: $detailRecipe) { recipe in
            RarityDetailView(recipe: recipe)
        }
    }

    private var pendingBanner: some View {
        HStack(spacing: 12) {
            Sparkle().fill(Color.ink).frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pending trade")
                    .font(.display(15))
                Text("\(model.pendingCardIDs.count) cards are part of an outgoing trade.")
                    .font(.text(13))
                    .foregroundStyle(Color.gray4)
            }
            Spacer()
        }
        .foregroundStyle(Color.ink)
        .padding(14)
        .background(Color.gray1, in: .rect(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.ink, lineWidth: 2) }
        .accessibilityElement(children: .combine)
    }
}

struct ProfileView: View {
    let model: OnboardingModel
    @Binding var tab: MainTab

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ChefCharacter(size: 170)
                VStack(spacing: 4) {
                    Text(model.experience?.rawValue ?? "Home Cook")
                        .font(.display(30))
                    Text(model.cuisines.sorted().joined(separator: ", ").lowercased())
                        .font(.text(14))
                        .foregroundStyle(Color.gray4)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(Color.ink)
                HStack(spacing: 12) {
                    stat("\(model.collection.count)", "cards")
                    stat("\(model.collection.filter { $0.tier.isHolographic }.count)", "legendary")
                    stat("\(model.trades.count)", "pending")
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color.paper)
        .safeAreaInset(edge: .bottom) { InkTabBar(selection: $tab) }
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.display(24))
            Text(label).font(.text(12)).foregroundStyle(Color.gray4)
        }
        .foregroundStyle(Color.ink)
        .frame(maxWidth: .infinity, minHeight: 82)
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.ink, lineWidth: 2) }
        .accessibilityElement(children: .combine)
    }
}
