import CoreMotion
import SwiftUI

/// The printed card. `tilt` runs from -1 to 1 on each axis and drives the holographic foil.
struct RecipeCardView: View {
    let recipe: Recipe
    let width: CGFloat
    var tilt: CGPoint = .zero
    var time: Double = 0

    private var height: CGFloat { width * 1.4 }
    private var unit: CGFloat { width / 300 }
    private var tier: RarityTier { recipe.tier }
    private var isHolo: Bool { tier.isHolographic }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20 * unit)
                .fill(isHolo ? Color(hex: 0x15131F) : .white)
            if isHolo {
                // Sits under the content so the sparkle never covers the dish or the text.
                HolographicFoil(tilt: tilt, time: time, unit: unit)
                    .allowsHitTesting(false)
            }
            VStack(alignment: .leading, spacing: 10 * unit) {
                header
                art
                Text(recipe.name)
                    .font(.system(size: 22 * unit, weight: .bold))
                    .foregroundStyle(isHolo ? .white : Color.brandText)
                    .lineLimit(2, reservesSpace: true)
                    .minimumScaleFactor(0.8)
                HStack {
                    Text(recipe.skill.rawValue)
                    Spacer()
                    Text(minutesText)
                }
                .font(.system(size: 13 * unit, weight: .medium))
                .foregroundStyle(isHolo ? .white.opacity(0.75) : Color.gray4)
            }
            .padding(16 * unit)
        }
        .frame(width: width, height: height)
        .clipShape(.rect(cornerRadius: 20 * unit))
        .overlay {
            RoundedRectangle(cornerRadius: 20 * unit)
                .strokeBorder(borderStyle, lineWidth: (isHolo ? 5 : 4) * unit)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(recipe.name), \(tier.name) \(recipe.cuisine) recipe card")
    }

    private var header: some View {
        HStack {
            Text(recipe.cuisine.uppercased())
                .font(.system(size: 12 * unit, weight: .semibold))
                .tracking(1)
                .foregroundStyle(isHolo ? .white.opacity(0.8) : Color.gray4)
            Spacer()
            HStack(spacing: 1 * unit) {
                ForEach(0..<tier.stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                }
            }
            .font(.system(size: 11 * unit))
            .foregroundStyle(tier.color)
        }
    }

    private var art: some View {
        Text(recipe.emoji)
            .font(.system(size: 104 * unit))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                isHolo ? Color.white.opacity(0.08) : Color.brandSecondary,
                in: .rect(cornerRadius: 12 * unit)
            )
    }

    private var minutesText: String {
        recipe.minutes < 120 ? "\(recipe.minutes) min" : "\(recipe.minutes / 60) hr"
    }

    private var borderStyle: AnyShapeStyle {
        guard isHolo else { return AnyShapeStyle(tier.color) }
        return AnyShapeStyle(AngularGradient(
            colors: [Color(hex: 0xF7E08A), Color(hex: 0xB8860B), .white, Color(hex: 0xD4A72C), Color(hex: 0xF7E08A)],
            center: .center,
            angle: .degrees(tilt.x * 90)
        ))
    }
}

/// Rainbow sheen, twinkling star foil and a moving glare, all shifted by the card's tilt.
struct HolographicFoil: View {
    let tilt: CGPoint
    let time: Double
    let unit: CGFloat

    private static let spectrum: [Color] = [
        Color(hex: 0xFF4D6D), Color(hex: 0xFFB347), Color(hex: 0xFFF275), Color(hex: 0x5CFFB1),
        Color(hex: 0x4DD8FF), Color(hex: 0x8C7BFF), Color(hex: 0xFF6FD8), Color(hex: 0xFF4D6D),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: Self.spectrum + Self.spectrum,
                startPoint: UnitPoint(x: -0.8 + tilt.x * 0.7, y: -0.8 + tilt.y * 0.7),
                endPoint: UnitPoint(x: 1.8 + tilt.x * 0.7, y: 1.8 + tilt.y * 0.7)
            )
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
        RoundedRectangle(cornerRadius: 20 * width / 300)
            .fill(LinearGradient(colors: [.brandPrimary, Color(hex: 0x6E1F1F)], startPoint: .top, endPoint: .bottom))
            .overlay {
                VStack(spacing: 10 * width / 300) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 54 * width / 300))
                    Text("SUPPER CLUB")
                        .font(.system(size: 16 * width / 300, weight: .semibold))
                        .tracking(3 * width / 300)
                }
                .foregroundStyle(Color.brandSecondary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20 * width / 300)
                    .strokeBorder(Color.brandSecondary.opacity(0.6), lineWidth: 4 * width / 300)
                    .padding(8 * width / 300)
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
