import SwiftUI

/// Hand-built ink characters: thick round outlines, solid black shapes and two dot eyes.
/// Everything is drawn on a 100 x 100 grid and scaled to `size`.
enum InkGlyph {
    case bowl, soup, salad, noodles, mushroom, dumpling, fish, meat, egg, bread, veg, taco
    case sprout, broccoli, wheat, nut, milk, shrimp, flame, knife, chef

    init(emoji: String) {
        switch emoji {
        case "🍚", "🍛": self = .bowl
        case "🍲": self = .soup
        case "🥗", "🍱": self = .salad
        case "🍜", "🍝", "🥢": self = .noodles
        case "🍄": self = .mushroom
        case "🥟", "🥞": self = .dumpling
        case "🐟", "🍣": self = .fish
        case "🦆", "🍗", "🐖", "🍖", "🥩": self = .meat
        case "🥚", "🍳", "🍮": self = .egg
        case "🥪", "🥖", "🥐", "🧀", "🍰", "🥧": self = .bread
        case "🌮", "🫔": self = .taco
        case "🌱", "🌿", "🥬", "🌸": self = .sprout
        case "🥦": self = .broccoli
        case "🌾": self = .wheat
        case "🌰", "🫘": self = .nut
        case "🥛": self = .milk
        case "🦐": self = .shrimp
        case "🔥", "🍫", "🍢": self = .flame
        case "🔪": self = .knife
        case "👩‍🍳": self = .chef
        default: self = .veg
        }
    }
}

struct InkGlyphView: View {
    let glyph: InkGlyph
    let size: CGFloat

    init(emoji: String, size: CGFloat) {
        glyph = InkGlyph(emoji: emoji)
        self.size = size
    }

    var body: some View {
        Canvas { context, canvas in
            context.scaleBy(x: canvas.width / 100, y: canvas.height / 100)
            var pen = InkPen(context: context)
            pen.draw(glyph)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private struct InkPen {
    var context: GraphicsContext
    let line: CGFloat = 5

    private func outline(_ path: Path, fill: Color = .white) {
        context.fill(path, with: .color(fill))
        context.stroke(path, with: .color(.ink), style: StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round))
    }

    private func stroke(_ path: Path, width: CGFloat? = nil) {
        context.stroke(path, with: .color(.ink), style: StrokeStyle(lineWidth: width ?? line, lineCap: .round, lineJoin: .round))
    }

    private func solid(_ path: Path) {
        context.fill(path, with: .color(.ink))
    }

    private func eyes(_ left: CGPoint, _ right: CGPoint, radius: CGFloat = 3.2) {
        for eye in [left, right] {
            solid(Path(ellipseIn: CGRect(x: eye.x - radius, y: eye.y - radius, width: radius * 2, height: radius * 2)))
        }
    }

    private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private func curve(_ points: [CGPoint]) -> Path {
        var path = Path()
        path.move(to: points[0])
        for index in stride(from: 1, to: points.count - 1, by: 2) {
            path.addQuadCurve(to: points[index + 1], control: points[index])
        }
        return path
    }

    private func bowlBody() -> Path {
        var path = Path()
        path.move(to: p(12, 48))
        path.addLine(to: p(88, 48))
        path.addCurve(to: p(66, 88), control1: p(88, 68), control2: p(78, 82))
        path.addLine(to: p(34, 88))
        path.addCurve(to: p(12, 48), control1: p(22, 82), control2: p(12, 68))
        path.closeSubpath()
        return path
    }

    mutating func draw(_ glyph: InkGlyph) {
        switch glyph {
        case .bowl:
            stroke(curve([p(36, 34), p(28, 26), p(36, 18), p(44, 10), p(36, 4)]))
            stroke(curve([p(62, 34), p(54, 26), p(62, 18), p(70, 10), p(62, 4)]))
            var rice = Path()
            rice.addArc(center: p(50, 48), radius: 30, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            solid(rice)
            outline(bowlBody())
            eyes(p(40, 64), p(60, 64))
        case .soup:
            for x: CGFloat in [32, 50, 68] {
                stroke(curve([p(x, 40), p(x - 8, 30), p(x, 20), p(x + 8, 10), p(x, 2)]))
            }
            outline(bowlBody())
            stroke(curve([p(22, 56), p(36, 50), p(50, 56), p(64, 62), p(78, 56)]), width: 4)
            eyes(p(40, 70), p(60, 70))
        case .salad:
            var left = Path()
            left.move(to: p(46, 50))
            left.addCurve(to: p(14, 18), control1: p(40, 26), control2: p(26, 14))
            left.addCurve(to: p(46, 50), control1: p(10, 36), control2: p(24, 50))
            solid(left)
            var right = Path()
            right.move(to: p(54, 50))
            right.addCurve(to: p(86, 14), control1: p(58, 26), control2: p(72, 10))
            right.addCurve(to: p(54, 50), control1: p(90, 34), control2: p(76, 50))
            outline(right)
            outline(Path(ellipseIn: CGRect(x: 38, y: 24, width: 20, height: 20)))
            outline(bowlBody())
            eyes(p(40, 64), p(60, 64))
        case .noodles:
            stroke(Path { $0.addLines([p(46, 42), p(90, 6)]) })
            stroke(Path { $0.addLines([p(56, 44), p(96, 16)]) })
            stroke(curve([p(30, 48), p(22, 34), p(32, 24), p(40, 34), p(34, 48)]))
            stroke(curve([p(44, 48), p(36, 30), p(48, 22), p(58, 32), p(52, 48)]))
            outline(bowlBody())
            eyes(p(40, 64), p(60, 64))
        case .mushroom:
            var stem = Path()
            stem.addRoundedRect(in: CGRect(x: 34, y: 46, width: 32, height: 44), cornerSize: CGSize(width: 13, height: 13))
            outline(stem)
            var cap = Path()
            cap.move(to: p(8, 50))
            cap.addCurve(to: p(92, 50), control1: p(10, 2), control2: p(90, 2))
            cap.addCurve(to: p(8, 50), control1: p(70, 60), control2: p(30, 60))
            cap.closeSubpath()
            solid(cap)
            for spot in [CGRect(x: 28, y: 22, width: 13, height: 13), CGRect(x: 56, y: 16, width: 16, height: 16), CGRect(x: 72, y: 36, width: 8, height: 8)] {
                context.fill(Path(ellipseIn: spot), with: .color(.white))
            }
            eyes(p(43, 68), p(57, 68))
        case .dumpling:
            var body = Path()
            body.move(to: p(8, 68))
            body.addCurve(to: p(92, 68), control1: p(14, 12), control2: p(86, 12))
            body.addCurve(to: p(8, 68), control1: p(76, 90), control2: p(24, 90))
            body.closeSubpath()
            outline(body)
            for x: CGFloat in [28, 42, 58, 72] {
                stroke(Path { $0.addLines([p(x, 26 + abs(50 - x) * 0.25), p(50 + (x - 50) * 0.85, 40 + abs(50 - x) * 0.2)]) }, width: 4)
            }
            eyes(p(40, 62), p(60, 62))
        case .fish:
            var tail = Path()
            tail.addLines([p(72, 50), p(95, 28), p(95, 72)])
            tail.closeSubpath()
            solid(tail)
            outline(Path(ellipseIn: CGRect(x: 6, y: 24, width: 72, height: 52)))
            stroke(curve([p(44, 30), p(54, 50), p(44, 70)]), width: 4)
            eyes(p(20, 46), p(32, 46))
        case .meat:
            stroke(Path { $0.addLines([p(62, 62), p(88, 88)]) }, width: 11)
            for knob in [CGRect(x: 80, y: 74, width: 12, height: 12), CGRect(x: 76, y: 84, width: 12, height: 12)] {
                outline(Path(ellipseIn: knob))
            }
            var body = Path()
            body.move(to: p(14, 40))
            body.addCurve(to: p(66, 16), control1: p(14, 12), control2: p(44, 4))
            body.addCurve(to: p(70, 70), control1: p(88, 28), control2: p(86, 58))
            body.addCurve(to: p(14, 40), control1: p(44, 86), control2: p(14, 72))
            body.closeSubpath()
            solid(body)
            context.fill(Path(ellipseIn: CGRect(x: 28, y: 28, width: 34, height: 28)), with: .color(.white))
            eyes(p(38, 42), p(52, 42))
        case .egg:
            var white = Path()
            white.move(to: p(14, 54))
            white.addCurve(to: p(52, 12), control1: p(6, 28), control2: p(30, 8))
            white.addCurve(to: p(90, 50), control1: p(76, 14), control2: p(96, 28))
            white.addCurve(to: p(52, 90), control1: p(86, 74), control2: p(78, 92))
            white.addCurve(to: p(14, 54), control1: p(28, 88), control2: p(20, 80))
            white.closeSubpath()
            outline(white)
            solid(Path(ellipseIn: CGRect(x: 30, y: 28, width: 40, height: 40)))
            for eye in [p(42, 46), p(58, 46)] {
                context.fill(Path(ellipseIn: CGRect(x: eye.x - 3.2, y: eye.y - 3.2, width: 6.4, height: 6.4)), with: .color(.white))
            }
        case .bread:
            var slice = Path()
            slice.move(to: p(22, 88))
            slice.addLine(to: p(22, 44))
            slice.addCurve(to: p(50, 12), control1: p(4, 28), control2: p(24, 10))
            slice.addCurve(to: p(78, 44), control1: p(76, 10), control2: p(96, 28))
            slice.addLine(to: p(78, 88))
            slice.closeSubpath()
            outline(slice)
            eyes(p(40, 50), p(60, 50))
            stroke(curve([p(44, 64), p(50, 70), p(56, 64)]), width: 4)
        case .veg:
            stroke(curve([p(50, 26), p(50, 12), p(62, 6)]), width: 7)
            var body = Path()
            body.move(to: p(50, 22))
            body.addCurve(to: p(78, 66), control1: p(68, 22), control2: p(80, 44))
            body.addCurve(to: p(50, 94), control1: p(78, 84), control2: p(64, 94))
            body.addCurve(to: p(22, 66), control1: p(36, 94), control2: p(22, 84))
            body.addCurve(to: p(50, 22), control1: p(20, 44), control2: p(32, 22))
            body.closeSubpath()
            solid(body)
            context.fill(Path(ellipseIn: CGRect(x: 32, y: 44, width: 36, height: 26)), with: .color(.white))
            eyes(p(43, 56), p(57, 56))
        case .taco:
            for x: CGFloat in [26, 44, 62] {
                solid(Path(ellipseIn: CGRect(x: x, y: 22, width: 22, height: 22)))
            }
            var shell = Path()
            shell.move(to: p(8, 78))
            shell.addCurve(to: p(92, 78), control1: p(14, 20), control2: p(86, 20))
            shell.closeSubpath()
            outline(shell)
            eyes(p(40, 60), p(60, 60))
        case .sprout:
            stroke(curve([p(50, 92), p(50, 70), p(50, 46)]), width: 6)
            var left = Path()
            left.move(to: p(50, 50))
            left.addCurve(to: p(8, 26), control1: p(44, 30), control2: p(26, 20))
            left.addCurve(to: p(50, 50), control1: p(10, 44), control2: p(28, 56))
            solid(left)
            var right = Path()
            right.move(to: p(50, 42))
            right.addCurve(to: p(92, 12), control1: p(56, 20), control2: p(74, 8))
            right.addCurve(to: p(50, 42), control1: p(92, 32), control2: p(72, 46))
            outline(right)
            eyes(p(66, 26), p(77, 24), radius: 2.6)
        case .broccoli:
            var stalk = Path()
            stalk.addRoundedRect(in: CGRect(x: 36, y: 50, width: 28, height: 42), cornerSize: CGSize(width: 8, height: 8))
            outline(stalk)
            for blob in [CGRect(x: 8, y: 26, width: 38, height: 38), CGRect(x: 54, y: 26, width: 38, height: 38), CGRect(x: 30, y: 6, width: 40, height: 40), CGRect(x: 30, y: 30, width: 40, height: 30)] {
                solid(Path(ellipseIn: blob))
            }
            eyes(p(43, 70), p(57, 70))
        case .wheat:
            stroke(Path { $0.addLines([p(50, 96), p(50, 22)]) })
            for y: CGFloat in [32, 50, 68] {
                solid(Path(ellipseIn: CGRect(x: 22, y: y - 10, width: 26, height: 15)).applying(rotation(-30, around: p(35, y))))
                solid(Path(ellipseIn: CGRect(x: 52, y: y - 10, width: 26, height: 15)).applying(rotation(30, around: p(65, y))))
            }
            solid(Path(ellipseIn: CGRect(x: 42, y: 4, width: 16, height: 26)))
        case .nut:
            var body = Path()
            body.move(to: p(14, 46))
            body.addLine(to: p(86, 46))
            body.addCurve(to: p(50, 94), control1: p(84, 72), control2: p(62, 86))
            body.addCurve(to: p(14, 46), control1: p(38, 86), control2: p(16, 72))
            body.closeSubpath()
            outline(body)
            var cap = Path()
            cap.move(to: p(10, 46))
            cap.addCurve(to: p(90, 46), control1: p(16, 8), control2: p(84, 8))
            cap.closeSubpath()
            solid(cap)
            eyes(p(40, 62), p(60, 62))
        case .milk:
            var carton = Path()
            carton.addLines([p(26, 38), p(40, 18), p(60, 18), p(74, 38), p(74, 92), p(26, 92)])
            carton.closeSubpath()
            outline(carton)
            var top = Path()
            top.addRoundedRect(in: CGRect(x: 40, y: 6, width: 20, height: 12), cornerSize: CGSize(width: 3, height: 3))
            solid(top)
            eyes(p(41, 60), p(59, 60))
            stroke(curve([p(44, 74), p(50, 80), p(56, 74)]), width: 4)
        case .shrimp:
            var body = Path()
            body.move(to: p(84, 30))
            body.addCurve(to: p(26, 24), control1: p(70, 6), control2: p(40, 6))
            body.addCurve(to: p(32, 88), control1: p(4, 44), control2: p(10, 78))
            body.addLine(to: p(42, 70))
            body.addCurve(to: p(50, 42), control1: p(32, 62), control2: p(36, 48))
            body.addCurve(to: p(84, 30), control1: p(62, 36), control2: p(76, 42))
            body.closeSubpath()
            solid(body)
            context.fill(Path(ellipseIn: CGRect(x: 56, y: 18, width: 8, height: 8)), with: .color(.white))
            context.fill(Path(ellipseIn: CGRect(x: 68, y: 22, width: 8, height: 8)), with: .color(.white))
            stroke(curve([p(84, 30), p(96, 18), p(92, 6)]), width: 3.5)
        case .flame:
            var flame = Path()
            flame.move(to: p(50, 6))
            flame.addCurve(to: p(80, 62), control1: p(58, 30), control2: p(82, 36))
            flame.addCurve(to: p(50, 94), control1: p(80, 82), control2: p(66, 94))
            flame.addCurve(to: p(20, 62), control1: p(34, 94), control2: p(20, 82))
            flame.addCurve(to: p(36, 34), control1: p(20, 50), control2: p(28, 42))
            flame.addCurve(to: p(50, 6), control1: p(38, 44), control2: p(50, 28))
            flame.closeSubpath()
            solid(flame)
            context.fill(Path(ellipseIn: CGRect(x: 34, y: 54, width: 32, height: 28)), with: .color(.white))
            eyes(p(44, 67), p(56, 67), radius: 2.6)
        case .knife:
            var blade = Path()
            blade.move(to: p(12, 88))
            blade.addCurve(to: p(68, 12), control1: p(24, 56), control2: p(44, 26))
            blade.addLine(to: p(76, 28))
            blade.addLine(to: p(30, 88))
            blade.closeSubpath()
            outline(blade)
            stroke(Path { $0.addLines([p(72, 22), p(90, 6)]) }, width: 11)
        case .chef:
            drawChef()
        }
    }

    private func rotation(_ degrees: CGFloat, around point: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: point.x, y: point.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -point.x, y: -point.y)
    }

    private func drawChef() {
        var head = Path()
        head.addRoundedRect(in: CGRect(x: 26, y: 40, width: 48, height: 50), cornerSize: CGSize(width: 22, height: 22))
        outline(head)
        var hat = Path()
        hat.move(to: p(30, 44))
        hat.addLine(to: p(30, 30))
        hat.addCurve(to: p(50, 8), control1: p(8, 22), control2: p(24, 0))
        hat.addCurve(to: p(70, 30), control1: p(76, 0), control2: p(92, 22))
        hat.addLine(to: p(70, 44))
        hat.closeSubpath()
        solid(hat)
        eyes(p(42, 62), p(58, 62))
    }
}

/// The Supper Club mascot: a chef drawn like the reference characters, with a sparkle either side.
struct ChefCharacter: View {
    let size: CGFloat
    var showsSparkles = true

    var body: some View {
        ZStack {
            Canvas { context, canvas in
                context.scaleBy(x: canvas.width / 200, y: canvas.height / 200)
                draw(in: context)
            }
            if showsSparkles {
                Sparkle().fill(Color.ink)
                    .frame(width: size * 0.17, height: size * 0.17)
                    .offset(x: -size * 0.38, y: -size * 0.2)
                Sparkle().fill(Color.ink)
                    .frame(width: size * 0.09, height: size * 0.09)
                    .offset(x: -size * 0.43, y: -size * 0.36)
                Sparkle().fill(Color.ink)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .offset(x: size * 0.39, y: size * 0.08)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func draw(in context: GraphicsContext) {
        let style = StrokeStyle(lineWidth: 6.5, lineCap: .round, lineJoin: .round)
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

        // Jacket, cut off at the bottom like a portrait.
        var jacket = Path()
        jacket.move(to: p(46, 198))
        jacket.addCurve(to: p(84, 124), control1: p(50, 160), control2: p(62, 134))
        jacket.addLine(to: p(122, 124))
        jacket.addCurve(to: p(156, 198), control1: p(142, 134), control2: p(154, 162))
        jacket.closeSubpath()
        context.fill(jacket, with: .color(.white))
        context.stroke(jacket, with: .color(.ink), style: style)
        for line in [[p(103, 142), p(103, 198)], [p(68, 172), p(66, 198)], [p(136, 172), p(138, 198)]] {
            context.stroke(Path { $0.addLines(line) }, with: .color(.ink), style: style)
        }

        // Neckerchief.
        var scarf = Path()
        scarf.addLines([p(82, 122), p(124, 122), p(103, 152)])
        scarf.closeSubpath()
        context.fill(scarf, with: .color(.ink))
        context.stroke(scarf, with: .color(.ink), style: style)

        // Head.
        var head = Path()
        head.move(to: p(66, 78))
        head.addCurve(to: p(104, 132), control1: p(62, 112), control2: p(80, 132))
        head.addCurve(to: p(142, 78), control1: p(128, 132), control2: p(146, 112))
        head.closeSubpath()
        context.fill(head, with: .color(.white))
        context.stroke(head, with: .color(.ink), style: style)
        for eye in [p(90, 94), p(116, 94)] {
            context.fill(Path(ellipseIn: CGRect(x: eye.x - 4.5, y: eye.y - 4.5, width: 9, height: 9)), with: .color(.ink))
        }

        // Curl of hair and the solid chef's hat.
        var hat = Path()
        hat.move(to: p(66, 80))
        hat.addLine(to: p(66, 58))
        hat.addCurve(to: p(72, 18), control1: p(36, 52), control2: p(40, 18))
        hat.addCurve(to: p(134, 18), control1: p(82, 0), control2: p(122, 0))
        hat.addCurve(to: p(142, 58), control1: p(168, 18), control2: p(172, 52))
        hat.addLine(to: p(142, 80))
        hat.closeSubpath()
        context.fill(hat, with: .color(.ink))
    }
}
