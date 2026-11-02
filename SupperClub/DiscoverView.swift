import SwiftUI

enum DiscoverRoute: Hashable {
    case inspect(Recipe)
    case offer(Recipe)
    /// The swipe deck, for one city or for every dish when `city` is nil.
    case swipe(city: String?)
}

struct DiscoverView: View {
    @Bindable var model: OnboardingModel
    @Binding var tab: MainTab

    private enum Segment: String, CaseIterable, Identifiable {
        case discover = "Discover"
        case trading = "Trading"
        var id: Self { self }
    }

    @State private var path: [DiscoverRoute] = []
    @State private var segment = Segment.discover
    @State private var search = ""
    @State private var cuisine: String?
    @State private var feed: [Recipe] = []
    @State private var dietOnly = true

    private var results: [Recipe] {
        feed.filter { recipe in
            !model.collection.contains(recipe)
                && (cuisine == nil || recipe.cuisine == cuisine)
                && (!dietOnly || recipe.fits(model.restrictions))
                && (search.isEmpty
                    || recipe.name.localizedCaseInsensitiveContains(search)
                    || recipe.cuisine.localizedCaseInsensitiveContains(search)
                    || recipe.city.name.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                header
                segmentPicker
                switch segment {
                case .discover: discoverContent
                case .trading:
                    TradingListView(model: model) { recipe in
                        path.append(.offer(recipe))
                    }
                }
            }
            .background(Color.paper.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { InkTabBar(selection: $tab) }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: DiscoverRoute.self) { route in
                destination(for: route)
                    .toolbarVisibility(.hidden, for: .navigationBar)
                    .background(Color.paper.ignoresSafeArea())
            }
        }
        .onAppear {
            if feed.isEmpty {
                // Cuisines the cook picked come first; rarity stays a surprise within each group.
                let shuffled = recipeCatalog.shuffled()
                feed = shuffled.filter { model.cuisines.contains($0.cuisine) }
                    + shuffled.filter { !model.cuisines.contains($0.cuisine) }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: DiscoverRoute) -> some View {
        switch route {
        case .inspect(let recipe):
            InspectCardView(model: model, recipe: recipe, path: $path)
        case .offer(let recipe):
            OfferCardsView(model: model, requested: recipe, path: $path) {
                path.removeAll()
                segment = .trading
            }
        case .swipe(let city):
            SwipeDeckView(
                model: model,
                title: city ?? "All dishes",
                recipes: results.filter { city == nil || $0.city.name == city },
                onInspect: { path.append(.inspect($0)) },
                onBack: { path.removeLast() },
                onOpenTrading: {
                    path.removeAll()
                    segment = .trading
                }
            )
        }
    }

    private var header: some View {
        HStack {
            Color.clear.frame(width: 44, height: 44)
            Spacer()
            Text("Supper Club")
                .font(.display(20))
                .foregroundStyle(Color.ink)
            Spacer()
            Button { segment = .trading } label: {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.ink, in: .circle)
            }
            .accessibilityLabel("Trade updates")
        }
        .padding(.horizontal, 20)
    }

    private var segmentPicker: some View {
        HStack(spacing: 4) {
            ForEach(Segment.allCases) { item in
                Button { segment = item } label: {
                    Text(item.rawValue)
                        .font(segment == item ? .display(14) : .text(14))
                        .foregroundStyle(segment == item ? .white : Color.ink)
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(segment == item ? Color.ink : .clear, in: .capsule)
                }
                .accessibilityAddTraits(segment == item ? .isSelected : [])
            }
        }
        .padding(4)
        .overlay { Capsule().stroke(Color.ink, lineWidth: 2) }
        .padding(.horizontal, 20)
    }

    private var discoverContent: some View {
        VStack(spacing: 10) {
            InkSearchField(placeholder: "search dishes, cuisines or cities", text: $search)
                .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    if !model.restrictions.isEmpty {
                        InkChip(title: "Fits my diet", isSelected: dietOnly) { dietOnly.toggle() }
                        Rectangle()
                            .fill(Color.ink)
                            .frame(width: 2, height: 22)
                            .accessibilityHidden(true)
                    }
                    InkChip(title: "All", isSelected: cuisine == nil) { cuisine = nil }
                    ForEach(cuisineOptions) { option in
                        InkChip(title: option.name, isSelected: cuisine == option.name) {
                            cuisine = option.name
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .scrollEdgeFade()

            DiscoverGlobe(
                recipes: results,
                onInspect: { path.append(.inspect($0)) },
                onSwipe: { path.append(.swipe(city: $0?.name)) }
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 4)
        }
    }
}

/// Dishes the cook swiped right on, then their outgoing requests.
/// Nothing can answer requests until there's a backend, so they stay pending.
private struct TradingListView: View {
    let model: OnboardingModel
    let onOffer: (Recipe) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if model.interested.isEmpty && model.trades.isEmpty {
                    VStack(spacing: 10) {
                        InkGlyphView(emoji: "🥟", size: 90)
                        Text("No trades yet")
                            .font(.display(20))
                        Text("Swipe right on a dish in Discover and it shows up here.")
                            .font(.text(14))
                            .foregroundStyle(Color.gray4)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                }
                if !model.interested.isEmpty {
                    sectionTitle("Interested", count: model.interested.count)
                    ForEach(model.interested) { recipe in
                        InterestedRow(recipe: recipe, onOffer: { onOffer(recipe) }) {
                            model.removeInterest(recipe)
                        }
                    }
                }
                if !model.trades.isEmpty {
                    sectionTitle("Sent requests", count: model.trades.count)
                        .padding(.top, model.interested.isEmpty ? 0 : 10)
                    ForEach(model.trades) { trade in
                        TradeRow(trade: trade) { model.cancel(trade) }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    private func sectionTitle(_ title: String, count: Int) -> some View {
        Text("\(title) · \(count)")
            .font(.display(17))
            .foregroundStyle(Color.ink)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct InterestedRow: View {
    let recipe: Recipe
    let onOffer: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RecipeCardView(recipe: recipe, width: 72)
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.display(16))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                Text("\(recipe.owner.shortName) · \(recipe.city.name)")
                    .font(.text(12))
                    .foregroundStyle(Color.gray4)
                HStack(spacing: 8) {
                    Button(action: onOffer) {
                        Text("Make an offer")
                            .font(.display(13))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(Color.ink, in: .capsule)
                    }
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.ink)
                            .frame(width: 36, height: 36)
                            .overlay { Circle().stroke(Color.ink, lineWidth: 2) }
                    }
                    .accessibilityLabel("Remove \(recipe.name)")
                }
                .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.ink, lineWidth: 2) }
    }
}

private struct TradeRow: View {
    let trade: TradeOffer
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pending")
                    .font(.display(12))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(Color.ink, in: .capsule)
                Spacer()
                Text("to \(trade.requested.owner.shortName)")
                    .font(.text(13))
                    .foregroundStyle(Color.gray4)
            }
            HStack(spacing: 12) {
                CardFan(recipes: trade.offered, cardWidth: 64)
                    .frame(maxWidth: .infinity)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .accessibilityLabel("for")
                RecipeCardView(recipe: trade.requested, width: 64)
                    .frame(maxWidth: .infinity)
            }
            SecondaryButton(title: "Cancel trade", action: onCancel)
        }
        .padding(14)
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(Color.ink, lineWidth: 2) }
    }
}
