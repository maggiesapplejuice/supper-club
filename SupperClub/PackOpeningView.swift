import SwiftUI

struct PackOpeningView: View {
    let recipes: [Recipe]
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

    @State private var sparks: [Spark] = []
    @State private var haptics = PackHaptics()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var current: Recipe { recipes[index] }

    var body: some View {
        ZStack {
            (isDark ? Color.black : Color.paper)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: isDark)
            switch stage {
            case .sealed, .bursting: packStage
            case .reveal: revealStage
            case .summary: summaryStage
            }
            SparkLayer(sparks: sparks)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            (isDark ? Color.white : Color.ink)
                .opacity(flash)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onAppear { haptics.prepare() }
        .sheet(item: $detailRecipe) { recipe in
            RarityDetailView(recipe: recipe)
        }
    }

    // MARK: Background

    /// The screen inverts to black only for the Legendary, so the foil is the one burst of color.
    private var isDark: Bool { stage == .reveal && current.tier.isHolographic }
    private var foreground: Color { isDark ? .white : .ink }
    /// Lower tiers arrive smaller, so a rarer card feels bigger the moment it lands.
    private var revealScale: CGFloat { 0.84 + 0.04 * CGFloat(current.tier.rawValue) }

    // MARK: Sealed pack

    private var packStage: some View {
        VStack(spacing: 28) {
            Text(stage == .sealed ? "Your starter pack" : " ")
                .font(.display(26))
                .foregroundStyle(Color.ink)
            ZStack {
                deckInsidePack
                tearablePack
                    .offset(y: packDropped ? 900 : 0)
                    .rotationEffect(.degrees(packDropped ? 6 : 0))
            }
            .frame(width: packSize.width, height: packSize.height)
            Label("Swipe across the top to tear it open", systemImage: "hand.draw")
                .font(.text(14))
                .foregroundStyle(Color.gray4)
                .opacity(stage == .sealed && tear == 0 ? 1 : 0)
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
            let foil = PackFoil(size: packSize, time: time)
            let width = packSize.width

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

                // The black slit opening along the tear.
                Capsule()
                    .fill(Color.ink)
                    .frame(width: width * tear, height: 5)
                    .offset(y: stripHeight - 2)
            }
            .frame(width: width, height: packSize.height, alignment: .topLeading)
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
        spawnBurst(color: .ink, count: 70)
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
            Text("\(index + 1) of \(recipes.count)")
                .font(.text(14))
                .foregroundStyle(foreground)
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
                    .shadow(color: .white.opacity(current.tier.isHolographic ? 0.5 : 0), radius: 26)
                } else {
                    CardBackView(width: cardWidth)
                        .shadow(color: .white.opacity(0.8), radius: isBuildingUp ? 44 : 20)
                }
            }
            .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
            .rotationEffect(.degrees(Double(dragX) / 18 + shake * 0.3))
            .offset(x: dragX + shake)
        }
        .contentShape(.rect)
        .gesture(swipeGesture)
        .onTapGesture {
            if isFaceUp {
                detailRecipe = current
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
                    .font(current.tier == .common ? .text(18) : .display(18 + 6 * CGFloat(current.tier.rawValue)))
                    .foregroundStyle(current.tier == .common ? Color.gray4 : foreground)
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
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard isFaceUp, !isFlipping else { return }
                dragX = value.translation.width
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
        withAnimation(.easeIn(duration: 0.2)) { dragX = direction * 520 }
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            if index + 1 < recipes.count {
                dragX = 0
                index += 1
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
            if recipe.tier >= .rare {
                spawnBurst(color: recipe.tier.color, count: 12 * recipe.tier.rawValue)
            }
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

    // MARK: Summary

    private var summaryStage: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("Your starter pack")
                    .font(.display(26))
                    .foregroundStyle(Color.ink)
                Text("Tap a card to see what makes it rare")
                    .font(.text(14))
                    .foregroundStyle(foreground.opacity(0.7))
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 12) {
                ForEach(recipes.reversed()) { recipe in
                    Button { detailRecipe = recipe } label: {
                        LiveCardView(recipe: recipe, width: 110)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Shows rarity details")
                }
            }
            Spacer()
            PrimaryButton(title: "ADD TO MY COLLECTION", action: onFinish)
        }
        .padding(20)
    }

    // MARK: Sparks

    private func spawnTearSparks() {
        guard !reduceMotion else { return }
        let center = CGPoint(x: packCenterX + packSize.width * (tear - 0.5), y: packTearY)
        addSparks((0..<6).map { _ in
            Spark(
                origin: center,
                velocity: CGVector(dx: .random(in: -70...110), dy: .random(in: -180 ... -30)),
                color: .ink,
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
    }

    // Sparks are drawn across the full screen, so these approximate the pack's screen position.
    private let packCenterX: CGFloat = 201
    private let packCenterY: CGFloat = 437
    private var packTearY: CGFloat { packCenterY - packSize.height / 2 + stripHeight }
}

private struct PackFoil: View {
    let size: CGSize
    let time: Double

    var body: some View {
        let shift = sin(time * 0.8) * 0.35
        ZStack {
            Color.white
            LinearGradient(
                colors: [.clear, .black.opacity(0.1), .clear, .black.opacity(0.05), .clear],
                startPoint: UnitPoint(x: -0.5 + shift, y: 0),
                endPoint: UnitPoint(x: 1.5 + shift, y: 1)
            )
            VStack(spacing: 6) {
                ChefCharacter(size: 170)
                Text("Supper Club")
                    .font(.display(30))
                Text("starter pack")
                    .font(.text(15))
                Text("6 recipe cards")
                    .font(.text(12))
                    .foregroundStyle(Color.gray4)
                    .padding(.top, 8)
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

private struct CrimpEdge: View {
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<40, id: \.self) { _ in
                Rectangle()
                    .fill(Color.ink)
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
