import CoreMotion
import SwiftUI

/// The printed card. `tilt` runs from -1 to 1 on each axis and drives the holographic foil.
/// Each tier steps up everything at once, so rarity reads at a glance:
/// Common is oat and quiet, Uncommon gets a matcha panel, Rare adds blueberry halftone, a double frame and a
/// colored shadow, Epic goes deep ube with a sunburst, and Legendary is holographic.
struct RecipeCardView: View {
    let recipe: Recipe
    let width: CGFloat
    var tilt: CGPoint = .zero
    var time: Double = 0

    private var height: CGFloat { width * 1.4 }
    private var unit: CGFloat { width / 300 }
    private var tier: RarityTier { recipe.tier }
    private var isHolo: Bool { tier.isHolographic }
    private var isDark: Bool { tier >= .epic }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24 * unit)
                .fill(isHolo ? Color(hex: 0x3A1E2C) : (isDark ? Color.plum : .white))
            if isHolo {
                // Sits under the content so the sparkle never covers the dish or the text.
                HolographicFoil(tilt: tilt, time: time, unit: unit)
                    .allowsHitTesting(false)
            }
            VStack(alignment: .leading, spacing: 10 * unit) {
                header
                art
                Text(recipe.name)
                    .font(tier == .common ? .text(20 * unit) : .display(nameSize * unit))
                    .foregroundStyle(isDark ? .white : Color.ink)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.8)
                HStack {
                    Text(recipe.skill.rawValue.lowercased())
                    Spacer()
                    Text(minutesText)
                }
                .font(.text(13 * unit))
                .foregroundStyle(isDark ? .white.opacity(0.8) : Color.gray4)
            }
            .padding(tier >= .rare ? 20 * unit : 16 * unit)
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: 24 * unit))
        .overlay {
            RoundedRectangle(cornerRadius: 24 * unit)
                .strokeBorder(borderStyle, lineWidth: borderWidth * unit)
        }
        .overlay {
            if tier >= .rare {
                RoundedRectangle(cornerRadius: 17 * unit)
                    .strokeBorder(isDark ? Color.white : Color.ink, lineWidth: 1.5 * unit)
                    .padding(8 * unit)
            }
        }
        .overlay {
            // Keeps a black card visibly separate from its black shadow.
            if tier == .epic {
                RoundedRectangle(cornerRadius: 24 * unit)
                    .stroke(Color.paper, lineWidth: 3 * unit)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 24 * unit)
                .fill(tier == .rare ? Color.periwinkle : Color.ink)
                .offset(x: shadowOffset * unit, y: shadowOffset * unit)
                .opacity(shadowOffset > 0 ? 1 : 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recipe.name), \(tier.name) \(recipe.cuisine) recipe card")
    }

    private var header: some View {
        HStack {
            Text(recipe.cuisine.lowercased())
                .font(.text(13 * unit))
                .foregroundStyle(isDark ? .white.opacity(0.85) : Color.gray4)
            Spacer()
            HStack(spacing: 2 * unit) {
                ForEach(0..<tier.stars, id: \.self) { _ in
                    Sparkle().frame(width: 14 * unit, height: 14 * unit)
                }
            }
            .foregroundStyle(isDark ? .white : Color.ink)
        }
    }

    private var art: some View {
        // Each dish sits inside a bubble colored by what kind of food it is.
        GlyphBubble(
            emoji: recipe.emoji,
            diameter: glyphSize * unit,
            fill: tier == .legendary ? .white : nil
        )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { TierBackdrop(tier: tier, tilt: tilt, unit: unit) }
            .overlay(alignment: .bottomLeading) { tierLabel }
            .clipShape(.rect(cornerRadius: 16 * unit))
    }

    @ViewBuilder
    private var tierLabel: some View {
        if tier > .common {
            Text(tier.name)
                .font(.display(12 * unit))
                .foregroundStyle(Color.ink)
                .padding(.horizontal, 10 * unit)
                .padding(.vertical, 5 * unit)
                .background(tier == .legendary ? Color.white : tier.accent, in: .capsule)
                .overlay { Capsule().stroke(Color.ink, lineWidth: 1.5 * unit) }
                .padding(8 * unit)
        }
    }

    private var glyphSize: CGFloat {
        switch tier {
        case .common: 120
        case .uncommon: 138
        case .rare: 150
        case .epic: 154
        case .legendary: 160
        }
    }

    private var nameSize: CGFloat {
        switch tier {
        case .common: 20
        case .uncommon: 21
        case .rare: 23
        case .epic: 25
        case .legendary: 26
        }
    }

    private var shadowOffset: CGFloat {
        switch tier {
        case .common, .uncommon: 0
        case .rare: 6
        case .epic, .legendary: 10
        }
    }

    private var minutesText: String {
        recipe.minutes < 120 ? "\(recipe.minutes) min" : "\(recipe.minutes / 60) hr"
    }

    private var borderWidth: CGFloat {
        switch tier {
        case .common: 1.5
        case .uncommon: 3
        case .rare: 5
        case .epic, .legendary: 7
        }
    }

    private var borderStyle: AnyShapeStyle {
        switch tier {
        case .common: AnyShapeStyle(Color.gray2)
        case .uncommon, .rare, .epic: AnyShapeStyle(Color.ink)
        case .legendary:
            AnyShapeStyle(AngularGradient(
                colors: HolographicFoil.spectrum,
                center: .center,
                angle: .degrees(tilt.x * 90)
            ))
        }
    }
}

/// The art panel behind the dish, which gets louder with each tier.
private struct TierBackdrop: View {
    let tier: RarityTier
    let tilt: CGPoint
    let unit: CGFloat

    var body: some View {
        switch tier {
        case .common:
            Color.oat
        case .uncommon:
            Color.mint.opacity(0.6)
        case .rare:
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let spacing = 11 * unit
                let reach = hypot(center.x, center.y)
                for x in stride(from: 0, to: size.width + spacing, by: spacing) {
                    for y in stride(from: 0, to: size.height + spacing, by: spacing) {
                        // Halftone: dots grow toward the panel's edges.
                        let radius = 3.6 * unit * hypot(x - center.x, y - center.y) / reach
                        let dot = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                        context.fill(Path(ellipseIn: dot), with: .color(.periwinkle))
                    }
                }
            }
            .background(Color(hex: 0xE9F0FC))
        case .epic:
            Canvas { context, size in
                drawRays(in: &context, size: size, color: .grape.opacity(0.6))
            }
            .background(Color(hex: 0x4A2538))
        case .legendary:
            ZStack {
                Color.white
                HolographicFoil.rainbow(tilt: tilt).opacity(0.55)
                Canvas { context, size in
                    drawRays(in: &context, size: size, color: .white.opacity(0.55))
                }
            }
        }
    }

    private func drawRays(in context: inout GraphicsContext, size: CGSize, color: Color) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let reach = hypot(size.width, size.height)
        let rays = 14
        for index in 0..<rays {
            let start = Double(index) / Double(rays) * 2 * .pi
            let end = start + .pi / Double(rays)
            var ray = Path()
            ray.move(to: center)
            ray.addLine(to: CGPoint(x: center.x + cos(start) * reach, y: center.y + sin(start) * reach))
            ray.addLine(to: CGPoint(x: center.x + cos(end) * reach, y: center.y + sin(end) * reach))
            ray.closeSubpath()
            context.fill(ray, with: .color(color))
        }
    }
}

/// Rainbow sheen, twinkling star foil and a moving glare, all shifted by the card's tilt.
struct HolographicFoil: View {
    let tilt: CGPoint
    let time: Double
    let unit: CGFloat

    static let spectrum: [Color] = [
        Color(hex: 0xFF4D6D), Color(hex: 0xFFB347), Color(hex: 0xFFF275), Color(hex: 0x5CFFB1),
        Color(hex: 0x4DD8FF), Color(hex: 0x8C7BFF), Color(hex: 0xFF6FD8), Color(hex: 0xFF4D6D),
    ]

    static func rainbow(tilt: CGPoint) -> LinearGradient {
        LinearGradient(
            colors: spectrum + spectrum,
            startPoint: UnitPoint(x: -0.8 + tilt.x * 0.7, y: -0.8 + tilt.y * 0.7),
            endPoint: UnitPoint(x: 1.8 + tilt.x * 0.7, y: 1.8 + tilt.y * 0.7)
        )
    }

    var body: some View {
        ZStack {
            Self.rainbow(tilt: tilt)
            .blendMode(.plusLighter)
            .opacity(0.32)

            Canvas { context, size in
                drawStars(in: &context, size: size)
            }
            .blendMode(.plusLighter)

            RadialGradient(
                colors: [.white.opacity(0.5), .clear],
                center: UnitPoint(x: 0.5 + tilt.x * 0.6, y: 0.5 + tilt.y * 0.6),
                startRadius: 0,
                endRadius: 190 * unit
            )
            .blendMode(.plusLighter)
        }
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize) {
        for index in 0..<340 {
            // Fixed pseudo-random placement, so stars stay put and only their shine changes.
            let seed = Double(index)
            let x = (sin(seed * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1)
            let y = (sin(seed * 78.233) * 12543.8731).truncatingRemainder(dividingBy: 1)
            let point = CGPoint(x: abs(x) * size.width, y: abs(y) * size.height)

            let phase = seed * 1.7 + tilt.x * 7 + tilt.y * 5 + time * 1.2
            let shine = pow(max(0, sin(phase)), 6)
            guard shine > 0.04 else { continue }

            let radius = ((0.5 + 2.2 * abs(x)) * shine + 0.4) * unit
            let hue = (abs(y) + tilt.x * 0.3 + 1).truncatingRemainder(dividingBy: 1)
            let color = Color(hue: hue, saturation: 0.35, brightness: 1).opacity(shine)

            var star = Path()
            star.move(to: CGPoint(x: point.x, y: point.y - radius * 2))
            star.addQuadCurve(to: CGPoint(x: point.x + radius * 2, y: point.y), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x, y: point.y + radius * 2), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x - radius * 2, y: point.y), control: point)
            star.addQuadCurve(to: CGPoint(x: point.x, y: point.y - radius * 2), control: point)
            context.fill(star, with: .color(color))
        }
    }
}

struct CardBackView: View {
    let width: CGFloat

    var body: some View {
        let unit = width / 300
        RoundedRectangle(cornerRadius: 24 * unit)
            .fill(Color.ink)
            .overlay {
                // A slow-turning color wheel behind the chef, so the back looks like a prize, not a blank.
                AngularGradient(colors: Color.accents + [Color.accents[0]], center: .center)
                    .opacity(0.9)
                    .mask {
                        Canvas { context, size in
                            let center = CGPoint(x: size.width / 2, y: size.height / 2)
                            let reach = hypot(size.width, size.height)
                            for index in 0..<16 {
                                let start = Double(index) / 16 * 2 * .pi
                                var ray = Path()
                                ray.move(to: center)
                                ray.addLine(to: CGPoint(x: center.x + cos(start) * reach, y: center.y + sin(start) * reach))
                                ray.addLine(to: CGPoint(x: center.x + cos(start + .pi / 16) * reach, y: center.y + sin(start + .pi / 16) * reach))
                                context.fill(ray, with: .color(.white))
                            }
                        }
                    }
                    .padding(10 * unit)
                    .clipShape(.rect(cornerRadius: 16 * unit))
            }
            .overlay {
                VStack(spacing: 14 * unit) {
                    ChefBubble(diameter: 160 * unit, lineWidth: 4 * unit)
                    Text("Supper Club")
                        .font(.display(24 * unit))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14 * unit)
                        .padding(.vertical, 6 * unit)
                        .background(Color.ink, in: .capsule)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16 * unit)
                    .strokeBorder(.white, lineWidth: 2.5 * unit)
                    .padding(10 * unit)
            }
            .overlay(alignment: .topLeading) {
                Sparkle().fill(Color.lemon).frame(width: 26 * unit, height: 26 * unit).padding(26 * unit)
            }
            .overlay(alignment: .bottomTrailing) {
                Sparkle().fill(Color.lemon).frame(width: 26 * unit, height: 26 * unit).padding(26 * unit)
            }
            .frame(width: width, height: width * 1.4)
            .accessibilityLabel("Face-down card")
    }
}

/// Reads the phone's tilt. The Simulator has no motion data, so it stays at zero there.
@MainActor
final class TiltMotion {
    static let shared = TiltMotion()
    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates()
    }

    var tilt: CGPoint {
        guard let attitude = manager.deviceMotion?.attitude else { return .zero }
        let clamp = { (value: Double) in min(1, max(-1, value)) }
        // Upright-ish reading position is treated as neutral.
        return CGPoint(x: clamp(attitude.roll / 0.6), y: clamp((attitude.pitch - 0.8) / 0.6))
    }
}

/// A card that responds to phone tilt and, when `isDraggable`, to a finger. Holo cards also shimmer on their own.
struct LiveCardView: View {
    let recipe: Recipe
    let width: CGFloat
    var isDraggable = false
    var extraTilt: CGPoint = .zero

    @State private var dragTilt: CGPoint = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: !recipe.tier.isHolographic)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let idle = reduceMotion || !recipe.tier.isHolographic
                ? CGPoint.zero
                : CGPoint(x: sin(time * 0.9) * 0.35, y: cos(time * 0.7) * 0.25)
            let motion = TiltMotion.shared.tilt
            let tilt = CGPoint(
                x: dragTilt.x + idle.x + motion.x + extraTilt.x,
                y: dragTilt.y + idle.y + motion.y + extraTilt.y
            )
            RecipeCardView(recipe: recipe, width: width, tilt: tilt, time: reduceMotion ? 0 : time)
                .rotation3DEffect(.degrees(tilt.x * 14), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
                .rotation3DEffect(.degrees(-tilt.y * 14), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        }
        .onAppear { TiltMotion.shared.start() }
        .gesture(isDraggable ? dragGesture : nil)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragTilt = CGPoint(
                    x: min(1, max(-1, value.translation.width / 120)),
                    y: min(1, max(-1, value.translation.height / 160))
                )
            }
            .onEnded { _ in
                withAnimation(.spring(duration: 0.5, bounce: 0.45)) { dragTilt = .zero }
            }
    }
}
