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
            Color.black.ignoresSafeArea()
            backgroundGlow
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
        .preferredColorScheme(.dark)
        .onAppear { haptics.prepare() }
        .sheet(item: $detailRecipe) { recipe in
            RarityDetailView(recipe: recipe)
                .preferredColorScheme(.light)
        }
    }

    // MARK: Background

    @ViewBuilder
    private var backgroundGlow: some View {
        let color: Color = switch stage {
        case .sealed, .bursting: .brandPrimary
        case .reveal: isFaceUp ? current.tier.color : RarityTier.legendary.color
        case .summary: RarityTier.legendary.color
        }
        RadialGradient(colors: [color.opacity(0.55), .clear], center: .center, startRadius: 20, endRadius: 340)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: index)
            .animation(.easeInOut(duration: 0.4), value: isFaceUp)
    }

    // MARK: Sealed pack

    private var packStage: some View {
        VStack(spacing: 28) {
            Text(stage == .sealed ? "Your starter pack" : " ")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
            ZStack {
                deckInsidePack
                tearablePack
                    .offset(y: packDropped ? 900 : 0)
                    .rotationEffect(.degrees(packDropped ? 6 : 0))
            }
            .frame(width: packSize.width, height: packSize.height)
            Label("Swipe across the top to tear it open", systemImage: "hand.draw")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
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

                // Light spilling out of the tear.
                Capsule()
                    .fill(Color(hex: 0xFFE9A8))
                    .frame(width: width * tear, height: 4)
                    .blur(radius: 3)
                    .shadow(color: Color(hex: 0xFFD166), radius: 14 * tear)
                    .offset(y: stripHeight - 2)
            }
            .frame(width: width, height: packSize.height, alignment: .topLeading)
        }
        .scaleEffect(1 + tear * 0.03)
        .shadow(color: .black.opacity(0.5), radius: 18, y: 12)
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
        spawnBurst(color: Color(hex: 0xFFD166), count: 70)
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
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            ZStack {
                if index + 1 < recipes.count {
                    CardBackView(width: cardWidth)
                        .scaleEffect(0.94)
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
                    .shadow(color: current.tier.color.opacity(0.8), radius: 30)
                } else {
                    CardBackView(width: cardWidth)
                        .shadow(color: RarityTier.legendary.color, radius: isBuildingUp ? 50 : 26)
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
                Text(current.tier.name.uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(current.tier.color)
                    .brightness(0.25)
                Text(index + 1 < recipes.count
                    ? "Swipe for the next card · Tap to see its rarity"
                    : "Swipe to finish · Tap to see its rarity")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Text("SOMETHING SPECIAL")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(RarityTier.legendary.color)
                Text("Tap to flip")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
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
            spawnBurst(color: Color(hex: 0xFFE9A8), count: 110)
            spawnBurst(color: Color(hex: 0x8C7BFF), count: 40)
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
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Tap a card to see what makes it rare")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
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
                color: Color(hex: 0xFFD166),
                size: .random(in: 1.5...3.5),
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
                size: .random(in: 2...5),
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
            LinearGradient(
                colors: [Color(hex: 0xC94A4A), .brandPrimary, Color(hex: 0x6E1F1F)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [.clear, .white.opacity(0.32), .clear, .white.opacity(0.14), .clear],
                startPoint: UnitPoint(x: -0.5 + shift, y: 0),
                endPoint: UnitPoint(x: 1.5 + shift, y: 1)
            )
            .blendMode(.plusLighter)
            VStack(spacing: 10) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 54))
                Text("SUPPER CLUB")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(4)
                Text("STARTER PACK")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(3)
                Text("6 RECIPE CARDS")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .opacity(0.8)
                    .padding(.top, 24)
            }
            .foregroundStyle(Color.brandSecondary)
            VStack {
                CrimpEdge()
                Spacer()
                CrimpEdge()
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: 4))
    }
}

private struct CrimpEdge: View {
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<52, id: \.self) { _ in
                Rectangle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 3, height: 16)
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
                    context.fill(Path(ellipseIn: rect), with: .color(spark.color.opacity(fade)))
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
