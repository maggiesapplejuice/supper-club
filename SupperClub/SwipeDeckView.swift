import SwiftUI

/// Dating-app style browsing: swipe right to want a dish (it lands in Trading), left to pass, tap to inspect.
struct SwipeDeckView: View {
    @Bindable var model: OnboardingModel
    let title: String
    let recipes: [Recipe]
    let onInspect: (Recipe) -> Void
    let onBack: () -> Void
    let onOpenTrading: () -> Void

    private enum Choice { case pass, want }

    @State private var passed: Set<String> = []
    @State private var drag = CGSize.zero
    @State private var leaving: Choice?
    @State private var lastWanted: Recipe?
    @State private var decisions = 0
    /// Bumped each time the cook sits on a card too long, which plays a little "swipe me" wiggle.
    @State private var nudges = 0
    @State private var nudgeOffset: CGFloat = 0

    private let swipeThreshold: CGFloat = 110
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var remaining: [Recipe] {
        recipes.filter { !passed.contains($0.id) && !model.interested.contains($0) }
    }

    /// -1 fully left, 1 fully right.
    private var progress: CGFloat { max(-1, min(1, (drag.width + nudgeOffset) / swipeThreshold)) }

    var body: some View {
        VStack(spacing: 14) {
            topBar
            ZStack {
                if remaining.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(remaining.prefix(3).enumerated()).reversed(), id: \.element.id) { depth, recipe in
                        card(recipe, depth: depth)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            actionButtons
        }
        .padding(.bottom, 8)
        .overlay(alignment: .top) { savedToast }
        .sensoryFeedback(.impact(weight: .medium), trigger: decisions)
        .sensoryFeedback(.impact(weight: .light), trigger: nudges)
        // Restarts whenever the top card changes or the cook touches it, so it only fires on a real pause.
        .task(id: "\(remaining.first?.id ?? "")-\(decisions)-\(drag == .zero)") {
            guard drag == .zero, !remaining.isEmpty else { return }
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else { return }
            await nudge()
        }
        .sensoryFeedback(.selection, trigger: abs(progress) >= 1)
    }

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .overlay { RoundedRectangle(cornerRadius: 13).stroke(Color.ink, lineWidth: 2) }
            }
            .accessibilityLabel("Back to the globe")
            Spacer()
            VStack(spacing: 0) {
                Text(title)
                    .font(.display(17))
                Text("\(remaining.count) left")
                    .font(.text(12))
                    .foregroundStyle(Color.gray4)
            }
            .foregroundStyle(Color.ink)
            Spacer()
            Button(action: onOpenTrading) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.ink, in: .circle)
            }
            .accessibilityLabel("Open Trading")
        }
        .padding(.horizontal, 20)
    }

    // MARK: Cards

    private func card(_ recipe: Recipe, depth: Int) -> some View {
        let isTop = depth == 0
        // Cards underneath rise as the top one is dragged away.
        let lift = isTop ? 0 : CGFloat(depth) - min(1, abs(progress))
        return SwipeCard(model: model, recipe: recipe, isTop: isTop)
            .overlay(alignment: .top) { if isTop { stamps } }
            .scaleEffect(1 - 0.05 * lift)
            .offset(y: 16 * lift)
            .offset(isTop ? drag : .zero)
            .offset(x: isTop ? nudgeOffset : 0)
            .rotationEffect(.degrees(isTop ? Double((drag.width + nudgeOffset) / 18) : 0), anchor: .bottom)
            .allowsHitTesting(isTop)
            .gesture(isTop ? dragGesture(recipe) : nil)
            .onTapGesture { if isTop { onInspect(recipe) } }
            .accessibilityAction(named: "Want to trade") { decide(.want, recipe) }
            .accessibilityAction(named: "Pass") { decide(.pass, recipe) }
    }

    private var stamps: some View {
        HStack {
            stamp("TRADE", systemImage: "heart.fill", filled: true)
                .rotationEffect(.degrees(-12))
                .opacity(Double(max(0, progress)))
            Spacer()
            stamp("PASS", systemImage: "xmark", filled: false)
                .rotationEffect(.degrees(12))
                .opacity(Double(max(0, -progress)))
        }
        .padding(.horizontal, 34)
        .padding(.top, 70)
        .allowsHitTesting(false)
    }

    private func stamp(_ text: String, systemImage: String, filled: Bool) -> some View {
        Label(text, systemImage: systemImage)
            .font(.display(22))
            .foregroundStyle(filled ? .white : Color.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(filled ? Color.ink : .white, in: .rect(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).stroke(filled ? .white : Color.ink, lineWidth: 3) }
    }

    /// Leans the card right then left, so the swipe directions are obvious without a tutorial.
    private func nudge() async {
        guard !reduceMotion else { return }
        nudges += 1
        for x: CGFloat in [44, -32, 0] {
            withAnimation(.spring(duration: 0.35, bounce: 0.35)) { nudgeOffset = x }
            try? await Task.sleep(for: .seconds(0.3))
        }
    }

    private func dragGesture(_ recipe: Recipe) -> some Gesture {
        DragGesture()
            .onChanged { value in
                guard leaving == nil else { return }
                drag = value.translation
            }
            .onEnded { value in
                guard leaving == nil else { return }
                let flick = value.predictedEndTranslation.width
                if value.translation.width > swipeThreshold || flick > 320 {
                    decide(.want, recipe)
                } else if value.translation.width < -swipeThreshold || flick < -320 {
                    decide(.pass, recipe)
                } else {
                    withAnimation(.spring(duration: 0.35, bounce: 0.4)) { drag = .zero }
                }
            }
    }

    private func decide(_ choice: Choice, _ recipe: Recipe) {
        guard leaving == nil else { return }
        leaving = choice
        decisions += 1
        withAnimation(.easeIn(duration: 0.25)) {
            drag = CGSize(width: choice == .want ? 520 : -520, height: drag.height + 60)
        }
        Task {
            try? await Task.sleep(for: .seconds(0.25))
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) {
                switch choice {
                case .want:
                    model.markInterested(recipe)
                    lastWanted = recipe
                case .pass:
                    passed.insert(recipe.id)
                }
                drag = .zero
                leaving = nil
            }
        }
    }

    // MARK: Buttons

    private var actionButtons: some View {
        HStack(spacing: 22) {
            roundButton("xmark", size: 62, filled: false, label: "Pass") {
                if let top = remaining.first { decide(.pass, top) }
            }
            roundButton("eye.fill", size: 48, filled: false, label: "Inspect") {
                if let top = remaining.first { onInspect(top) }
            }
            roundButton("heart.fill", size: 62, filled: true, label: "Want to trade") {
                if let top = remaining.first { decide(.want, top) }
            }
        }
        .disabled(remaining.isEmpty)
        .opacity(remaining.isEmpty ? 0.3 : 1)
    }

    private func roundButton(_ systemImage: String, size: CGFloat, filled: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(filled ? .white : Color.ink)
                .frame(width: size, height: size)
                .background(filled ? Color.ink : .white, in: .circle)
                .overlay { Circle().stroke(Color.ink, lineWidth: 2.5) }
        }
        .accessibilityLabel(label)
    }

    // MARK: States

    private var emptyState: some View {
        VStack(spacing: 12) {
            InkGlyphView(emoji: "🥟", size: 90)
            Text("That's every dish here")
                .font(.display(20))
            Text("Head back to the globe to explore another city.")
                .font(.text(14))
                .foregroundStyle(Color.gray4)
                .multilineTextAlignment(.center)
            SecondaryButton(title: "Back to the globe", action: onBack)
                .padding(.top, 8)
        }
        .foregroundStyle(Color.ink)
        .padding(.horizontal, 40)
    }

    @ViewBuilder
    private var savedToast: some View {
        if let lastWanted {
            Button(action: onOpenTrading) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                    Text("\(lastWanted.name) saved to Trading")
                        .lineLimit(1)
                    Text("View")
                        .underline()
                }
                .font(.display(13))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(Color.ink, in: .capsule)
            }
            .padding(.top, 58)
            .padding(.horizontal, 20)
            .transition(.move(edge: .top).combined(with: .opacity))
            .id(lastWanted.id)
            .task(id: lastWanted.id) {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation { self.lastWanted = nil }
            }
        }
    }
}

/// One card in the deck: who's offering it and the card itself.
private struct SwipeCard: View {
    let model: OnboardingModel
    let recipe: Recipe
    let isTop: Bool

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(300, (proxy.size.height - 60) / 1.4)
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    InkGlyphView(emoji: "👩‍🍳", size: 32)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(recipe.owner.name)
                            .font(.display(14))
                        Text("\(recipe.city.name) · \(recipe.cuisine.lowercased())")
                            .font(.text(12))
                            .foregroundStyle(Color.gray4)
                    }
                    Spacer()
                    FavoriteChefButton(model: model, chef: recipe.owner)
                }
                .foregroundStyle(Color.ink)
                .frame(width: cardWidth)
                // Only the top card's owner shows, so the stack underneath reads as plain cards.
                .opacity(isTop ? 1 : 0)
                Group {
                    if isTop {
                        LiveCardView(recipe: recipe, width: cardWidth)
                    } else {
                        RecipeCardView(recipe: recipe, width: cardWidth)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .contain)
        .accessibilityHint("Swipe right to want it for a trade, left to pass, or tap to inspect")
    }
}
