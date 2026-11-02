import SwiftUI

struct OfferCardsView: View {
    @Bindable var model: OnboardingModel
    let requested: Recipe
    @Binding var path: [DiscoverRoute]
    let onSent: () -> Void

    private enum Step { case choosing, confirming, sent }

    private let maxCards = 5

    @State private var step = Step.choosing
    @State private var selection: [Recipe] = []
    @State private var search = ""
    @State private var tier: RarityTier?
    @State private var detailRecipe: Recipe?

    private var cards: [Recipe] {
        model.collection
            .filter { (tier == nil || $0.tier == tier) && (search.isEmpty || $0.name.localizedCaseInsensitiveContains(search)) }
            .sorted { $0.score > $1.score }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                topBar
                InkSearchField(placeholder: "search your inventory", text: $search)
                    .padding(.horizontal, 20)
                tierChips
                cardGrid
                sendBar
            }
            if step != .choosing {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
            }
            if step == .confirming {
                confirmModal
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .zIndex(2)
            }
            if step == .sent {
                sentModal
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                    .zIndex(3)
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.3), value: step)
        .sensoryFeedback(.selection, trigger: selection)
        .sensoryFeedback(.success, trigger: step) { _, new in new == .sent }
        .sheet(item: $detailRecipe) { recipe in
            RarityDetailView(recipe: recipe)
        }
    }

    private var topBar: some View {
        HStack {
            Button { path.removeLast() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .overlay { RoundedRectangle(cornerRadius: 13).stroke(Color.ink, lineWidth: 2) }
            }
            .accessibilityLabel("Back")
            Text("Select Cards to Offer")
                .font(.display(19))
                .foregroundStyle(Color.ink)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var tierChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                InkChip(title: "All", isSelected: tier == nil) { tier = nil }
                ForEach(RarityTier.allCases) { item in
                    InkChip(title: item.name, isSelected: tier == item) { tier = item }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .scrollEdgeFade()
    }

    @ViewBuilder
    private var cardGrid: some View {
        if model.collection.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Text("No cards to offer yet")
                    .font(.display(20))
                Text("Cards you collect will show up here.")
                    .font(.text(14))
                    .foregroundStyle(Color.gray4)
                Spacer()
            }
            .foregroundStyle(Color.ink)
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible())], spacing: 18) {
                    ForEach(cards) { card in
                        OfferTile(
                            card: card,
                            isSelected: selection.contains(card),
                            isPending: model.pendingCardIDs.contains(card.id),
                            onTap: { toggle(card) },
                            onInspect: { detailRecipe = card }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }

    private var sendBar: some View {
        VStack(spacing: 6) {
            PrimaryButton(title: "SEND TRADE", isEnabled: !selection.isEmpty) {
                step = .confirming
            }
            Text("\(selection.count) of \(maxCards) cards selected")
                .font(.text(12))
                .foregroundStyle(Color.gray4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    private func toggle(_ card: Recipe) {
        if let index = selection.firstIndex(of: card) {
            selection.remove(at: index)
        } else if selection.count < maxCards {
            selection.append(card)
        }
    }

    // MARK: Confirm

    private var confirmModal: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Confirm Trade Request")
                    .font(.display(22))
                Text("Review your offer before sending.")
                    .font(.text(13))
                    .foregroundStyle(Color.gray4)
            }
            .foregroundStyle(Color.ink)

            tradeFaceOff

            VStack(alignment: .leading, spacing: 0) {
                Text("YOU ARE TRADING")
                    .font(.display(11))
                    .tracking(1)
                    .foregroundStyle(Color.gray4)
                    .padding(.bottom, 6)
                ForEach(Array(selection.enumerated()), id: \.element.id) { index, card in
                    if index > 0 { Divider() }
                    tradeRow(card)
                }
            }
            .padding(14)
            .background(Color.gray1, in: .rect(cornerRadius: 18))

            VStack(spacing: 10) {
                PrimaryButton(title: "CONFIRM REQUEST") {
                    model.send(offered: selection, requested: requested)
                    step = .sent
                    Task {
                        try? await Task.sleep(for: .seconds(1.6))
                        onSent()
                    }
                }
                SecondaryButton(title: "Cancel") { step = .choosing }
            }

            Label("\(requested.owner.name) will get a notification.", systemImage: "info.circle.fill")
                .font(.text(12))
                .foregroundStyle(Color.gray4)
        }
        .padding(20)
        .background(Color.paper, in: .rect(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).stroke(Color.ink, lineWidth: 2.5) }
        .padding(.horizontal, 16)
    }

    /// Your cards and theirs side by side, leaning in, with the swap between them.
    private var tradeFaceOff: some View {
        HStack(alignment: .top, spacing: 6) {
            tradeSide(label: "you give") {
                CardFan(recipes: selection, cardWidth: 112)
                    .rotationEffect(.degrees(-4))
            }
            tradeSide(label: "you get") {
                LiveCardView(recipe: requested, width: 112)
                    .rotationEffect(.degrees(4))
            }
        }
        .overlay {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color.ink, in: .circle)
                .overlay { Circle().stroke(Color.paper, lineWidth: 3) }
                .offset(y: 14)
                .accessibilityHidden(true)
        }
    }

    private func tradeSide<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 10) {
            Text(label.uppercased())
                .font(.display(11))
                .tracking(1)
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 10)
                .frame(height: 22)
                .overlay { Capsule().stroke(Color.ink, lineWidth: 1.5) }
            content()
                .frame(height: 170)
        }
        .frame(maxWidth: .infinity)
    }

    private func tradeRow(_ card: Recipe) -> some View {
        HStack(spacing: 10) {
            RecipeCardView(recipe: card, width: 34)
            Text(card.tier.name.uppercased())
                .font(.display(9))
                .foregroundStyle(card.tier >= .rare ? .white : Color.ink)
                .padding(.horizontal, 7)
                .frame(height: 20)
                .background(card.tier >= .rare ? Color.ink : .white, in: .rect(cornerRadius: 5))
                .overlay { RoundedRectangle(cornerRadius: 5).stroke(Color.ink, lineWidth: 1.5) }
            Text(card.name)
                .font(.display(14))
                .foregroundStyle(Color.ink)
                .lineLimit(1)
            Spacer(minLength: 4)
            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.ink, in: .circle)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var sentModal: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.ink)
                Sparkle().fill(.white).frame(width: 46, height: 46)
            }
            .frame(width: 84, height: 84)
            Text("Trade request sent!")
                .font(.display(22))
                .foregroundStyle(Color.ink)
            Text("we'll notify the recipient")
                .font(.text(14))
                .foregroundStyle(Color.gray4)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.paper, in: .rect(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).stroke(Color.ink, lineWidth: 2.5) }
        .padding(.horizontal, 28)
        .accessibilityElement(children: .combine)
    }
}

private struct OfferTile: View {
    let card: Recipe
    let isSelected: Bool
    let isPending: Bool
    let onTap: () -> Void
    let onInspect: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                LiveCardView(recipe: card, width: 160)
                    .compositingGroup()
                    .opacity(isPending ? 0.35 : 1)
            }
            .buttonStyle(.plain)
            .disabled(isPending)
            .accessibilityValue(isPending ? "In a pending trade" : (isSelected ? "Selected" : "Not selected"))
            .accessibilityAddTraits(isSelected ? .isSelected : [])

            Button(action: onInspect) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ink)
                    .frame(width: 32, height: 32)
                    .background(.white, in: .circle)
                    .overlay { Circle().stroke(Color.ink, lineWidth: 2) }
            }
            .accessibilityLabel("See rarity of \(card.name)")
            .offset(x: -10, y: 118)
        }
        .overlay(alignment: .topLeading) {
            if isSelected {
                ZStack {
                    Circle().fill(Color.ink)
                    Circle().stroke(Color.white, lineWidth: 2)
                    Sparkle().fill(.white).frame(width: 18, height: 18)
                }
                .frame(width: 36, height: 36)
                .offset(x: 10, y: 34)
                .allowsHitTesting(false)
            } else if isPending {
                Text("Pending")
                    .font(.display(11))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .frame(height: 24)
                    .background(Color.ink, in: .capsule)
                    .offset(x: -4, y: -6)
            }
        }
        .scaleEffect(isSelected ? 1.03 : 1)
        .animation(.spring(duration: 0.3, bounce: 0.5), value: isSelected)
    }
}

/// Offered cards fanned out like a hand, so the trade reads visually.
struct CardFan: View {
    let recipes: [Recipe]
    let cardWidth: CGFloat

    var body: some View {
        ZStack {
            ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                let middle = Double(recipes.count - 1) / 2
                let position = Double(index) - middle
                RecipeCardView(recipe: recipe, width: cardWidth)
                    .rotationEffect(.degrees(position * 9), anchor: .bottom)
                    .offset(x: position * cardWidth * 0.16)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(recipes.map(\.name).joined(separator: ", "))
    }
}
