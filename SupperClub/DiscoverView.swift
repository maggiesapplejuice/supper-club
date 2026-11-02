import SwiftUI

enum DiscoverRoute: Hashable {
    case inspect(Recipe)
    case offer(Recipe)
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
    @State private var visibleID: String?
    @State private var surpriseCount = 0

    private var results: [Recipe] {
        feed.filter { recipe in
            !model.collection.contains(recipe)
                && (cuisine == nil || recipe.cuisine == cuisine)
                && (search.isEmpty
                    || recipe.name.localizedCaseInsensitiveContains(search)
                    || recipe.cuisine.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                header
                segmentPicker
                switch segment {
                case .discover: discoverContent
                case .trading: TradingListView(model: model)
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
        .sensoryFeedback(.impact(weight: .medium), trigger: surpriseCount)
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
            HStack(spacing: 8) {
                InkSearchField(placeholder: "search recipes or cuisines", text: $search)
                Button(action: surpriseMe) {
                    HStack(spacing: 5) {
                        Sparkle().fill(.white).frame(width: 12, height: 12)
                        Text("Surprise")
                            .font(.display(13))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(Color.ink, in: .capsule)
                }
                .accessibilityLabel("Surprise me with a random recipe")
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
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

            if results.isEmpty {
                ContentUnavailableView("No recipes found", systemImage: "magnifyingglass")
                    .font(.text(14))
            } else {
                feedList
            }
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(results) { recipe in
                    FeedPost(recipe: recipe) {
                        path.append(.inspect(recipe))
                    }
                    .containerRelativeFrame(.vertical)
                    .scrollTransition(axis: .vertical) { content, phase in
                        // Cards tip in and out as they pass, then settle when centered.
                        content
                            .scaleEffect(phase.isIdentity ? 1 : 0.82)
                            .rotationEffect(.degrees(phase.value * 5))
                            .opacity(phase.isIdentity ? 1 : 0.35)
                    }
                    .id(recipe.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $visibleID)
        .sensoryFeedback(.selection, trigger: visibleID)
    }

    private func surpriseMe() {
        guard let pick = results.randomElement() else { return }
        surpriseCount += 1
        path.append(.inspect(pick))
    }
}

/// One full-height post in the feed: who has it, the card, and a way in.
private struct FeedPost: View {
    let recipe: Recipe
    let onInspect: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(280, (proxy.size.height - 130) / 1.4)
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    InkGlyphView(emoji: "👩‍🍳", size: 34)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(recipe.owner.name)
                            .font(.display(14))
                        Text("wants to trade · \(recipe.cuisine.lowercased())")
                            .font(.text(12))
                            .foregroundStyle(Color.gray4)
                    }
                    Spacer()
                }
                .foregroundStyle(Color.ink)
                .frame(width: cardWidth)
                .accessibilityElement(children: .combine)

                Button(action: onInspect) {
                    LiveCardView(recipe: recipe, width: cardWidth)
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Button(action: onInspect) {
                        Text("Inspect")
                            .font(.display(14))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(Color.ink, in: .capsule)
                    }
                    ShareLink(item: "Check out \(recipe.name) on Supper Club") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.ink)
                            .frame(width: 46, height: 46)
                            .overlay { Circle().stroke(Color.ink, lineWidth: 2) }
                    }
                    .accessibilityLabel("Share")
                }
                .frame(width: cardWidth)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Outgoing requests. Nothing can answer them until there's a backend, so they stay pending.
private struct TradingListView: View {
    let model: OnboardingModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if model.trades.isEmpty {
                    VStack(spacing: 10) {
                        InkGlyphView(emoji: "🥟", size: 90)
                        Text("No trades yet")
                            .font(.display(20))
                        Text("Inspect a card in Discover and send your first offer.")
                            .font(.text(14))
                            .foregroundStyle(Color.gray4)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(Color.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 50)
                } else {
                    ForEach(model.trades) { trade in
                        TradeRow(trade: trade) { model.cancel(trade) }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
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
