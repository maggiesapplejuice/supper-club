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
    @Bindable var model: OnboardingModel
    @Binding var tab: MainTab

    private enum EditSheet: String, Identifiable {
        case skill, cuisines, restrictions
        var id: Self { self }
    }

    @State private var editing: EditSheet?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ChefCharacter(size: 150)
                VStack(spacing: 4) {
                    Text(model.experience?.rawValue ?? "Home Cook")
                        .font(.display(30))
                    Text(model.experience?.detail ?? "Tell us how you cook")
                        .font(.text(14))
                        .foregroundStyle(Color.gray4)
                }
                .foregroundStyle(Color.ink)
                HStack(spacing: 12) {
                    stat("\(model.collection.count)", "cards")
                    stat("\(model.collection.filter { $0.tier.isHolographic }.count)", "legendary")
                    stat("\(model.trades.count)", "pending")
                }
                section("Skill level", edit: .skill) {
                    if let experience = model.experience {
                        HStack(spacing: 12) {
                            InkGlyphView(emoji: experience.emoji, size: 40)
                            Text(experience.rawValue)
                                .font(.display(16))
                                .foregroundStyle(Color.ink)
                            Spacer()
                        }
                    } else {
                        emptyNote("Not set yet")
                    }
                }
                section("Favorite cuisines", edit: .cuisines) {
                    if model.cuisines.isEmpty {
                        emptyNote("None picked yet")
                    } else {
                        FlowLayout {
                            ForEach(cuisineOptions.filter { model.cuisines.contains($0.name) }) { cuisine in
                                HStack(spacing: 6) {
                                    InkGlyphView(emoji: cuisine.emoji, size: 22)
                                    Text(cuisine.name).font(.display(13))
                                }
                            }
                            .modifier(ProfileTag())
                        }
                    }
                }
                section("Dietary restrictions", edit: .restrictions) {
                    if model.restrictions.isEmpty {
                        emptyNote("No restrictions")
                    } else {
                        FlowLayout {
                            ForEach(orderedRestrictions, id: \.self) { restriction in
                                Text(restriction).font(.display(13))
                            }
                            .modifier(ProfileTag())
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
        }
        .background(Color.paper)
        .safeAreaInset(edge: .bottom) { InkTabBar(selection: $tab) }
        .sheet(item: $editing) { sheet in
            editSheet(sheet)
        }
    }

    /// Restrictions in the same order as the picker, with anything custom at the end.
    private var orderedRestrictions: [String] {
        let listed = restrictionGroups.flatMap(\.options)
        return listed.filter(model.restrictions.contains)
            + model.restrictions.subtracting(listed).sorted()
    }

    private func section<Content: View>(_ title: String, edit: EditSheet, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.display(17))
                    .foregroundStyle(Color.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { editing = edit } label: {
                    Text("Edit")
                        .font(.display(12))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .overlay { Capsule().stroke(Color.ink, lineWidth: 2) }
                }
                .accessibilityLabel("Edit \(title.lowercased())")
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: .rect(cornerRadius: 22))
        .overlay { RoundedRectangle(cornerRadius: 22).stroke(Color.ink, lineWidth: 2) }
    }

    private func emptyNote(_ text: String) -> some View {
        Text(text)
            .font(.text(14))
            .foregroundStyle(Color.gray4)
    }

    private func editSheet(_ sheet: EditSheet) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(sheetTitle(sheet))
                    .font(.display(22))
                    .foregroundStyle(Color.ink)
                Spacer()
                Button { editing = nil } label: {
                    Text("Done")
                        .font(.display(14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .frame(height: 38)
                        .background(Color.ink, in: .capsule)
                }
            }
            .padding(20)
            ScrollView {
                Group {
                    switch sheet {
                    case .skill:
                        VStack(spacing: 12) {
                            ForEach(CookingExperience.allCases) { level in
                                OptionRow(
                                    emoji: level.emoji,
                                    title: level.rawValue,
                                    subtitle: level.detail,
                                    isSelected: model.experience == level
                                ) {
                                    model.experience = level
                                }
                            }
                        }
                    case .cuisines:
                        CuisinePicker(selection: $model.cuisines)
                    case .restrictions:
                        RestrictionPicker(selection: $model.restrictions)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.paper)
        .presentationDragIndicator(.visible)
    }

    private func sheetTitle(_ sheet: EditSheet) -> String {
        switch sheet {
        case .skill: "Skill level"
        case .cuisines: "Favorite cuisines"
        case .restrictions: "Dietary restrictions"
        }
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

/// Read-only outlined capsule for the profile's tag lists.
private struct ProfileTag: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(Color.gray1, in: .capsule)
            .overlay { Capsule().stroke(Color.ink, lineWidth: 1.5) }
    }
}
