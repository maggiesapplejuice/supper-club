import SwiftUI

struct PackOpeningView: View {
    let recipes: [Recipe]
    var restrictions: Set<String> = []
    let onFinish: () -> Void

    private enum Stage { case sealed, bursting, reveal, summary }

    private let packSize = CGSize(width: 260, height: 400)
    private let stripHeight: CGFloat = 58
    private let cardWidth: CGFloat = 270

    @State private var stage = Stage.sealed
    @State private var tear = 0.0
    @State private var lastTick = 0.0
    @State private var tearStartProgress = 0.0
    @State private var stripGone = false
    @State private var packDropped = false
    @State private var flash = 0.0
    @State private var deckRisen = false

    @State private var index = 0
    @State private var dragX: CGFloat = 0
    @State private var isFaceUp = true
    @State private var flipAngle = 0.0
    @State private var isBuildingUp = false
    @State private var isFlipping = false
    @State private var detailRecipe: Recipe?
    @State private var cardsLanded = false
    @State private var tapSpin = 0.0
    @State private var enterScale: CGFloat = 1
    @State private var tapPop: CGFloat = 1
    @State private var tapBursts = 0

    @State private var sparks: [Spark] = []
    @State private var haptics = PackHaptics()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var current: Recipe { recipes[index] }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            // Rays only behind the sealed pack; cards are revealed on pure black.
            if stage == .sealed || stage == .bursting {
                LightRays(color: glowColor, speed: 0.08)
                    .opacity(0.9)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
            switch stage {
            case .sealed, .bursting: packStage
            case .reveal: revealStage
            case .summary: summaryStage
            }
            SparkLayer(sparks: sparks)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            Color.white
                .opacity(flash)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear { haptics.prepare() }
        .sensoryFeedback(.success, trigger: stage == .summary)
        .sheet(item: $detailRecipe) { recipe in
            RarityDetailView(recipe: recipe)
        }
    }

    // MARK: Background

    /// The whole opening happens on black, lit by the color of whatever is on screen.
    private var foreground: Color { .white }
    private var glowColor: Color {
        switch stage {
        case .sealed, .bursting: .mango
        case .reveal: isFaceUp ? (current.tier == .common ? .sunflower : current.tier.accent) : .butter
        case .summary: .bubblegum
        }
    }
    /// Lower tiers arrive smaller, so a rarer card feels bigger the moment it lands.
    private var revealScale: CGFloat { 0.84 + 0.04 * CGFloat(current.tier.rawValue) }

    // MARK: Sealed pack

    private var packStage: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("Your starter pack")
                    .font(.display(30))
                Text("\(recipes.count) recipe cards inside")
                    .font(.text(14))
                    .foregroundStyle(.white.opacity(0.7))
                dietBadge
            }
            .foregroundStyle(.white)
            .opacity(stage == .sealed ? 1 : 0)
            ZStack {
                deckInsidePack
                tearablePack
                    .offset(y: packDropped ? 900 : 0)
                    .rotationEffect(.degrees(packDropped ? 6 : 0))
            }
            .frame(width: packSize.width, height: packSize.height)
            Label("Swipe across the top to tear it open", systemImage: "hand.draw")
                .font(.display(14))
                .foregroundStyle(Color.lemon)
                .opacity(stage == .sealed && tear == 0 ? 1 : 0)
                .phaseAnimator([0.45, 1]) { label, opacity in label.opacity(opacity) } animation: { _ in .easeInOut(duration: 0.9) }
        }
    }

    private var deckInsidePack: some View {
        CardBackView(width: cardWidth * 0.85)
            .offset(y: deckRisen ? 0 : 60)
            .scaleEffect(deckRisen ? 1.1 : 0.9)
            .opacity(stage == .bursting ? 1 : 0)
    }

    private var tearablePack: some View {
        TimelineView(.animation) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let foil = PackFoil(size: packSize, time: time, cardCount: recipes.count)
            let width = packSize.width
            // The sealed pack floats and breathes so it begs to be opened.
            let bob = stage == .sealed && tear == 0 ? sin(time * 2) * 6 : 0
            let sway = stage == .sealed && tear == 0 ? sin(time * 1.3) * 1.5 : 0

            ZStack(alignment: .topLeading) {
                foil.mask(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: width, height: packSize.height - stripHeight)
                        .offset(y: stripHeight)
                }
                foil.mask(alignment: .topLeading) {
                    Rectangle()
                        .frame(width: width * (1 - tear), height: stripHeight)
                        .offset(x: width * tear)
                }
                foil.mask(alignment: .topLeading) {
                    Rectangle().frame(width: width * tear, height: stripHeight)
                }
                .rotationEffect(
                    .degrees(-20 * tear),
                    anchor: UnitPoint(x: tear, y: stripHeight / packSize.height)
                )
                .offset(x: stripGone ? -340 : 0, y: stripGone ? -520 : 0)
                .rotationEffect(.degrees(stripGone ? -60 : 0))
                .opacity(stripGone ? 0 : 1)

                // The glowing slit opening along the tear.
                Capsule()
                    .fill(Color.lemon)
                    .frame(width: width * tear, height: 6)
                    .shadow(color: .lemon, radius: 10)
                    .offset(y: stripHeight - 3)
            }
            .frame(width: width, height: packSize.height, alignment: .topLeading)
            .shadow(color: Color.mango.opacity(0.55 + 0.25 * sin(time * 3)), radius: 34)
            .offset(y: bob)
            .rotationEffect(.degrees(sway))
        }
        .scaleEffect(1 + tear * 0.03)
        .contentShape(.rect)
        .gesture(tearGesture)
        .accessibilityElement()
        .accessibilityLabel("Sealed starter pack")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Open pack") { burstOpen() }
    }

    private var tearGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { value in
                guard stage == .sealed else { return }
                let moved = abs(value.translation.width) / (packSize.width * 0.8)
                let progress = min(1, max(tearStartProgress, tearStartProgress + moved))
                guard progress > tear else { return }
                tear = progress
                if tear - lastTick >= 0.025 {
                    lastTick = tear
                    haptics.tearTick(progress: tear)
                    spawnTearSparks()
                    if tear > 0.6 && !reduceMotion { flash = 0.08 * tear }
                }
                if tear >= 1 { burstOpen() }
            }
            .onEnded { _ in tearStartProgress = tear }
    }

    private func burstOpen() {
        guard stage == .sealed else { return }
        stage = .bursting
        tear = 1
        haptics.packBurst()
        for color in Color.accents {
            spawnBurst(color: color, count: 14)
        }
        spawnBurst(color: .white, count: 30)
        if !reduceMotion { flash = 0.85 }
        withAnimation(.easeOut(duration: 0.45)) {
            flash = 0
            stripGone = true
        }
        withAnimation(.spring(duration: 0.6, bounce: 0.35)) { deckRisen = true }
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation(.easeIn(duration: 0.5)) { packDropped = true }
            try? await Task.sleep(for: .seconds(0.55))
            stage = .reveal
            arrive(at: 0)
        }
    }

    // MARK: Card reveal

    private var revealStage: some View {
        VStack(spacing: 20) {
            HStack(spacing: 6) {
                ForEach(recipes.indices, id: \.self) { position in
                    Capsule()
                        .fill(position <= index ? Color.lemon : .white.opacity(0.25))
                        .frame(width: position == index ? 22 : 8, height: 8)
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.4), value: index)
            .accessibilityLabel("Card \(index + 1) of \(recipes.count)")
            ZStack {
                if index + 1 < recipes.count {
                    CardBackView(width: cardWidth)
                        .scaleEffect(revealScale * 0.94)
                        .offset(y: 10)
                        .opacity(0.8)
                }
                revealCard
            }
            .frame(height: cardWidth * 1.4 + 24)
            cardCaption
        }
        .padding(.horizontal, 20)
    }

    private var revealCard: some View {
        TimelineView(.animation(paused: !isBuildingUp)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let shake = isBuildingUp && !reduceMotion ? sin(time * 70) * 5 : 0
            Group {
                if isFaceUp {
                    LiveCardView(
                        recipe: current,
                        width: cardWidth,
                        extraTilt: CGPoint(x: dragX / 180, y: 0)
                    )
                    .scaleEffect(revealScale)
                    .shadow(color: glowColor.opacity(0.35 + 0.12 * Double(current.tier.rawValue)), radius: 18 + 8 * CGFloat(current.tier.rawValue))
                } else {
                    CardBackView(width: cardWidth)
                        .shadow(color: Color.lemon.opacity(0.9), radius: isBuildingUp ? 60 : 24)
                }
            }
            .rotation3DEffect(.degrees(flipAngle + tapSpin), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .scaleEffect(tapPop * enterScale)
            .background { ShockRings(trigger: tapBursts, color: glowColor) }
            .rotationEffect(.degrees(Double(dragX) / 18 + shake * 0.3))
            .offset(x: dragX + shake)
        }
        .contentShape(.rect)
        .gesture(swipeGesture)
        .onTapGesture {
            if isFaceUp {
                celebrateTap()
            } else {
                flipHoloCard()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: isFaceUp ? "Next card" : "Flip card") {
            if isFaceUp { showNext() } else { flipHoloCard() }
        }
        .accessibilityAction(named: "See rarity details") {
            if isFaceUp { detailRecipe = current }
        }
    }

    private var cardCaption: some View {
        VStack(spacing: 6) {
            if isFaceUp {
                Text(current.tier.name)
                    .font(current.tier == .common ? .display(20) : .display(22 + 6 * CGFloat(current.tier.rawValue)))
                    .foregroundStyle(current.tier == .common ? Color.white.opacity(0.8) : (current.tier == .legendary ? .white : current.tier.accent))
                    .shadow(color: glowColor.opacity(0.6), radius: 12)
                    .id(index)
                    .transition(.scale(scale: 1.6).combined(with: .opacity))
                Text(index + 1 < recipes.count
                    ? "Swipe for the next card · Tap to see its rarity"
                    : "Swipe to finish · Tap to see its rarity")
                    .font(.text(13))
                    .foregroundStyle(foreground.opacity(0.7))
            } else {
                Text("Something special")
                    .font(.display(28))
                    .foregroundStyle(foreground)
                Text("Tap to flip")
                    .font(.text(13))
                    .foregroundStyle(foreground.opacity(0.7))
            }
        }
        .multilineTextAlignment(.center)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard isFaceUp, !isFlipping else { return }
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { dragX = value.translation.width }
            }
            .onEnded { value in
                guard isFaceUp, !isFlipping else { return }
                if abs(value.predictedEndTranslation.width) > 110 {
                    showNext(direction: value.translation.width < 0 ? -1 : 1)
                } else {
                    withAnimation(.spring(duration: 0.4, bounce: 0.4)) { dragX = 0 }
                }
            }
    }

    private func showNext(direction: CGFloat = 1) {
        haptics.cardFlick()
        withAnimation(.easeIn(duration: 0.2)) { dragX = direction * 520 }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            if index + 1 < recipes.count {
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) {
                    dragX = 0
                    enterScale = 0.9
                    index += 1
                }
                withAnimation(.spring(duration: 0.4, bounce: 0.35)) { enterScale = 1 }
                arrive(at: index)
            } else {
                withAnimation(.easeOut(duration: 0.3)) { stage = .summary }
            }
        }
    }

    private func arrive(at position: Int) {
        let recipe = recipes[position]
        if recipe.tier.isHolographic {
            isFaceUp = false
            haptics.cardReveal(.rare)
        } else {
            isFaceUp = true
            haptics.cardReveal(recipe.tier)
            // Every card gets confetti in its own color; rarer cards get more.
            spawnBurst(color: recipe.tier == .common ? .sunflower : recipe.tier.accent, count: 10 + 14 * recipe.tier.rawValue)
            if recipe.tier >= .rare {
                spawnBurst(color: .lemon, count: 8 * recipe.tier.rawValue)
            }
        }
    }

    /// Tapping a revealed card spins it, sends out color rings and confetti, then opens its rarity details.
    private func celebrateTap() {
        guard !isFlipping else { return }
        isFlipping = true
        haptics.cardReveal(current.tier)
        tapBursts += 1
        let colors = current.tier == .common ? [Color.sunflower, .blush, .mint] : [current.tier.accent, .butter, .rose, .sky]
        for color in colors {
            spawnBurst(color: color, count: 18)
        }
        withAnimation(.spring(duration: 0.55, bounce: 0.35)) { tapSpin += 360 }
        withAnimation(.spring(duration: 0.25, bounce: 0.6)) { tapPop = 1.12 }
        Task {
            try? await Task.sleep(for: .seconds(0.25))
            withAnimation(.spring(duration: 0.35, bounce: 0.5)) { tapPop = 1 }
            try? await Task.sleep(for: .seconds(0.35))
            isFlipping = false
            detailRecipe = current
        }
    }

    private func flipHoloCard() {
        guard !isFaceUp, !isFlipping else { return }
        isFlipping = true
        isBuildingUp = true
        let buildUp = 1.1
        haptics.legendaryBuildUp(duration: buildUp)
        Task {
            try? await Task.sleep(for: .seconds(buildUp))
            isBuildingUp = false
            withAnimation(.easeIn(duration: 0.12)) { flipAngle = 90 }
            try? await Task.sleep(for: .seconds(0.12))
            isFaceUp = true
            flipAngle = -90
            haptics.legendaryHit()
            spawnBurst(color: .white, count: 80)
            for color in HolographicFoil.spectrum.prefix(6) {
                spawnBurst(color: color, count: 14)
            }
            if !reduceMotion { flash = 0.9 }
            withAnimation(.easeOut(duration: 0.6)) { flash = 0 }
            withAnimation(.spring(duration: 0.55, bounce: 0.4)) { flipAngle = 0 }
            isFlipping = false
        }
    }

    // MARK: Diet

    private var filters: [String] { recipeFilters(in: restrictions) }

    /// Says the pack was matched to the cook's diet, and owns up when few recipes fit.
    @ViewBuilder
    private var dietBadge: some View {
        if !filters.isEmpty {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Sparkle().fill(Color.ink).frame(width: 11, height: 11)
                    Text("Every card fits your diet")
                        .font(.display(12))
                }
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 12)
                .frame(height: 28)
                .background(Color.matcha, in: .capsule)
                .overlay { Capsule().stroke(.white, lineWidth: 1.5) }
                Text(filters.joined(separator: " · "))
                    .font(.text(12))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                if recipes.count < StarterPack.size {
                    Text("Only \(recipes.count) of our recipes fit all of these, so your pack is smaller.")
                        .font(.text(12))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 30)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: Summary

    private var summaryStage: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("Your starter pack")
                    .font(.display(28))
                    .foregroundStyle(.white)
                Text("Tap a card to see what makes it rare")
                    .font(.text(14))
                    .foregroundStyle(foreground.opacity(0.7))
                dietBadge
                    .padding(.top, 6)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                ForEach(Array(recipes.reversed().enumerated()), id: \.element.id) { position, recipe in
                    Button { detailRecipe = recipe } label: {
                        LiveCardView(recipe: recipe, width: 82)
                    }
                    .scaleEffect(cardsLanded ? 1 : 0.4)
                    .opacity(cardsLanded ? 1 : 0)
                    .animation(.spring(duration: 0.5, bounce: 0.5).delay(Double(position) * 0.06), value: cardsLanded)
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows rarity details")
                }
            }
            Spacer()
            PrimaryButton(title: "Add to my collection", action: onFinish)
        }
        .padding(20)
        .onAppear { cardsLanded = true }
    }

    // MARK: Sparks

    private func spawnTearSparks() {
        guard !reduceMotion else { return }
        let center = CGPoint(x: packCenterX + packSize.width * (tear - 0.5), y: packTearY)
        addSparks((0..<8).map { _ in
            Spark(
                origin: center,
                velocity: CGVector(dx: .random(in: -70...110), dy: .random(in: -180 ... -30)),
                color: [Color.lemon, .mango, .tomato, .white].randomElement()!,
                size: .random(in: 3...6),
                life: .random(in: 0.3...0.6)
            )
        })
    }

    private func spawnBurst(color: Color, count: Int) {
        guard !reduceMotion, count > 0 else { return }
        let center = CGPoint(x: packCenterX, y: packCenterY)
        addSparks((0..<count).map { _ in
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = Double.random(in: 90...520)
            return Spark(
                origin: center,
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                color: color,
                size: .random(in: 4...10),
                life: .random(in: 0.5...1.3)
            )
        })
    }

    private func addSparks(_ new: [Spark]) {
        let now = Date()
        sparks.removeAll { now.timeIntervalSince($0.born) > $0.life }
        sparks.append(contentsOf: new)
        // Once the longest-lived spark is gone, empty the list so the spark layer pauses.
        let longest = new.map(\.life).max() ?? 0
        Task {
            try? await Task.sleep(for: .seconds(longest + 0.05))
            let later = Date()
            sparks.removeAll { later.timeIntervalSince($0.born) > $0.life }
        }
    }

    // Sparks are drawn across the full screen, so these approximate the pack's screen position.
    private let packCenterX: CGFloat = 201
    private let packCenterY: CGFloat = 437
    private var packTearY: CGFloat { packCenterY - packSize.height / 2 + stripHeight }
}

private struct PackFoil: View {
    let size: CGSize
    let time: Double
    let cardCount: Int

    var body: some View {
        let shift = sin(time * 0.8) * 0.35
        ZStack {
            // Holographic foil that slowly shifts, with a moving glare across it.
            LinearGradient(
                colors: HolographicFoil.spectrum + HolographicFoil.spectrum,
                startPoint: UnitPoint(x: -0.6 + shift, y: -0.4),
                endPoint: UnitPoint(x: 1.6 + shift, y: 1.4)
            )
            .opacity(0.85)
            LinearGradient(
                colors: [.clear, .white.opacity(0.55), .clear],
                startPoint: UnitPoint(x: -0.4 + shift * 2, y: 0),
                endPoint: UnitPoint(x: 0.4 + shift * 2, y: 1)
            )
            .blendMode(.plusLighter)
            VStack(spacing: 8) {
                ChefBubble(diameter: 160)
                Text("Supper Club")
                    .font(.display(30))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(.white, in: .capsule)
                    .overlay { Capsule().stroke(Color.ink, lineWidth: 2.5) }
                Text("STARTER PACK · \(cardCount) CARDS")
                    .font(.display(12))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 26)
                    .background(Color.ink, in: .capsule)
            }
            .foregroundStyle(Color.ink)
            VStack {
                CrimpEdge()
                Spacer()
                CrimpEdge()
            }
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.ink, lineWidth: 3)
        }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: 10))
    }
}

/// Three color rings that ripple out from the card when it's tapped.
private struct ShockRings: View {
    let trigger: Int
    let color: Color

    @State private var expand = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke([color, Color.butter, Color.rose][index], lineWidth: 6)
                    .frame(width: 240, height: 240)
                    .scaleEffect(expand ? 2.2 + 0.4 * CGFloat(index) : 0.6)
                    .opacity(expand ? 0 : 0.9)
                    .animation(.easeOut(duration: 0.7).delay(0.08 * Double(index)), value: expand)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) {
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) { expand = false }
            Task {
                try? await Task.sleep(for: .milliseconds(20))
                expand = true
            }
        }
    }
}

/// Slowly turning sunburst behind the pack and cards, tinted by what's on screen.
private struct LightRays: View {
    let color: Color
    let speed: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { timeline in
            let angle = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * speed
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height * 0.48)
                let reach = hypot(size.width, size.height)
                let rays = 18
                for index in 0..<rays {
                    let start = angle + Double(index) / Double(rays) * 2 * .pi
                    let end = start + .pi / Double(rays)
                    var ray = Path()
                    ray.move(to: center)
                    ray.addLine(to: CGPoint(x: center.x + cos(start) * reach, y: center.y + sin(start) * reach))
                    ray.addLine(to: CGPoint(x: center.x + cos(end) * reach, y: center.y + sin(end) * reach))
                    ray.closeSubpath()
                    context.fill(ray, with: .radialGradient(
                        Gradient(colors: [color.opacity(0.55), color.opacity(0)]),
                        center: center, startRadius: 0, endRadius: reach * 0.55
                    ))
                }
            }
        }
    }
}

private struct CrimpEdge: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<40, id: \.self) { _ in
                Rectangle()
                    .fill(Color.ink.opacity(0.85))
                    .frame(width: 3, height: 14)
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }
}

private struct Spark: Identifiable {
    let id = UUID()
    let born = Date()
    let origin: CGPoint
    let velocity: CGVector
    let color: Color
    let size: CGFloat
    let life: Double
}

private struct SparkLayer: View {
    let sparks: [Spark]

    var body: some View {
        TimelineView(.animation(paused: sparks.isEmpty)) { timeline in
            Canvas { context, _ in
                for spark in sparks {
                    let age = timeline.date.timeIntervalSince(spark.born)
                    guard age < spark.life else { continue }
                    let fade = 1 - age / spark.life
                    // A touch of gravity so sparks arc instead of drifting straight.
                    let point = CGPoint(
                        x: spark.origin.x + spark.velocity.dx * age,
                        y: spark.origin.y + spark.velocity.dy * age + 260 * age * age
                    )
                    let radius = spark.size * fade
                    let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Sparkle().path(in: rect), with: .color(spark.color.opacity(fade)))
                }
            }
        }
    }
}

#Preview {
    PackOpeningView(
        recipes: StarterPack.build(experience: .intermediate, cuisines: ["Italian", "Thai"]),
        onFinish: {}
    )
}
