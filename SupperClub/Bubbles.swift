import SwiftUI

/// A food glyph inside a filled, outlined circle. The glyph is sized to sit well inside the circle and is clipped
/// to it, so no stroke ever pokes past the edge.
struct GlyphBubble: View {
    let emoji: String
    let diameter: CGFloat
    var fill: Color?
    var lineWidth: CGFloat = 0

    var body: some View {
        InkGlyphView(emoji: emoji, size: diameter * 0.62)
            .frame(width: diameter, height: diameter)
            .background(fill ?? Color.tint(forGlyph: emoji))
            .clipShape(.circle)
            .overlay { Circle().strokeBorder(Color.ink, lineWidth: lineWidth) }
            .accessibilityHidden(true)
    }
}

/// The chef mascot as a portrait inside a circle: hat to shoulders, cropped at the bottom edge.
struct ChefBubble: View {
    let diameter: CGFloat
    var fill: Color = .butter
    var lineWidth: CGFloat = 0

    var body: some View {
        ChefCharacter(size: diameter * 0.86, showsSparkles: false)
            .offset(y: diameter * 0.1)
            .frame(width: diameter, height: diameter)
            .background(fill)
            .clipShape(.circle)
            .overlay { Circle().strokeBorder(Color.ink, lineWidth: lineWidth) }
            .accessibilityHidden(true)
    }
}


/// The wordmark: chunky rounded caps where the U in SUPPER is a little soup bowl with eyes and steam.
struct SupperClubLogo: View {
    var size: CGFloat = 56

    var body: some View {
        VStack(spacing: -size * 0.12) {
            HStack(alignment: .lastTextBaseline, spacing: size * 0.02) {
                letters("S")
                BowlLetter(size: size)
                    .alignmentGuide(.lastTextBaseline) { $0[.bottom] }
                letters("PPER")
            }
            letters("CLUB")
        }
        .foregroundStyle(Color.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Supper Club")
    }

    private func letters(_ text: String) -> some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .kerning(size * 0.02)
    }
}

/// A bowl shaped like a U: open top, round bottom, two eyes, and steam curling out of it.
private struct BowlLetter: View {
    let size: CGFloat

    var body: some View {
        let width = size * 0.84, height = size * 0.8
        Canvas { context, canvas in
            let w = canvas.width, h = canvas.height
            let top = h * 0.32
            // The bowl: a flat rim with a deep round belly, the same weight as the letters.
            var bowl = Path()
            bowl.move(to: CGPoint(x: 0, y: top))
            bowl.addLine(to: CGPoint(x: w, y: top))
            bowl.addCurve(to: CGPoint(x: w * 0.5, y: h),
                          control1: CGPoint(x: w, y: h * 0.82), control2: CGPoint(x: w * 0.8, y: h))
            bowl.addCurve(to: CGPoint(x: 0, y: top),
                          control1: CGPoint(x: w * 0.2, y: h), control2: CGPoint(x: 0, y: h * 0.82))
            bowl.closeSubpath()
            context.fill(bowl, with: .color(.ink))
            // Eyes, punched out like ROTA's cat.
            for x in [0.36, 0.64] {
                let eye = CGRect(x: w * x - w * 0.06, y: h * 0.52, width: w * 0.12, height: w * 0.14)
                context.fill(Path(ellipseIn: eye), with: .color(.paper))
            }
            // Two curls of steam in rose.
            for x in [0.34, 0.66] {
                var steam = Path()
                steam.move(to: CGPoint(x: w * x, y: top - h * 0.04))
                steam.addCurve(to: CGPoint(x: w * x, y: 0),
                               control1: CGPoint(x: w * (x - 0.14), y: top * 0.66),
                               control2: CGPoint(x: w * (x + 0.14), y: top * 0.33))
                context.stroke(steam, with: .color(.rose), style: StrokeStyle(lineWidth: w * 0.08, lineCap: .round))
            }
        }
        .frame(width: width, height: height)
    }
}
