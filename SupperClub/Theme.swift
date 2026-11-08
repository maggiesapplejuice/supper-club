import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    // Sun Club x Rainbow Spaces: warm cream, soft brights, plum type.
    static let paper = Color(hex: 0xFBF7EA)
    /// Text and line color: Sun Club's purple.
    static let ink = Color(hex: 0x6D3A52)
    static let plum = Color(hex: 0x6D3A52)
    static let brandPrimary = ink
    static let brandSecondary = Color(hex: 0xF1EBE2)
    static let brandText = ink
    static let gray4 = Color(hex: 0x8C7280)
    static let gray3 = Color(hex: 0xBBA9B2)
    static let gray2 = Color(hex: 0xEADFD8)
    static let gray1 = Color(hex: 0xF4EEE6)

    // Brights
    static let rose = Color(hex: 0xDA74A3)       // Sun Club Pink
    static let sunflower = Color(hex: 0xF6B719)  // Rainbow Sun
    static let tangerine = Color(hex: 0xF08C21)
    static let poppy = Color(hex: 0xE8622E)
    static let sage = Color(hex: 0xB4B534)       // Matcha
    static let grape = Color(hex: 0x9B67AC)
    static let periwinkle = Color(hex: 0x6698CC) // Sea
    static let storm = Color(hex: 0x3E4A6B)
    // Pastels
    static let blush = Color(hex: 0xE9ACC8)      // Peony
    static let butter = Color(hex: 0xF2D88F)
    static let mint = Color(hex: 0xC8D378)       // Pistachio
    static let sky = Color(hex: 0xBFD1F4)        // Cloud blue
    static let lilac = Color(hex: 0xCDB7D9)
    static let peach = Color(hex: 0xEEBCA7)
    static let oat = Color(hex: 0xF1EBE2)        // Cloud

    // Older names used around the app, mapped onto the palette
    static let tomato = rose
    static let mango = sunflower
    static let lemon = butter
    static let matcha = sage
    static let blueberry = periwinkle
    static let ube = lilac
    static let bubblegum = blush
    /// The one highlight for anything selected: chips, options, tiles.
    static let highlight = butter

    /// The pastel bubble each food glyph sits on, so dishes read by type at a glance.
    static func tint(forGlyph emoji: String) -> Color {
        switch InkGlyph(emoji: emoji) {
        case .soup, .bowl, .noodles: butter
        case .meat, .taco, .flame: blush
        case .fish, .shrimp: sky
        case .salad, .veg, .sprout, .broccoli: mint
        case .bread, .dumpling, .wheat: peach
        case .egg, .milk: Color(hex: 0xF7EBB5)
        case .mushroom, .nut: lilac
        case .knife: sky
        case .chef: blush
        }
    }

    /// Repeating accents for lists of tiles, like the cuisine grid.
    static let accents: [Color] = [blush, butter, mint, sky, lilac, peach]
}

extension Font {
    /// Headers: a soft serif standing in for Zenon (New York ships with iOS).
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    /// Paragraphs and labels: a clean geometric sans standing in for Soleil.
    static func text(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Regular", size: size, relativeTo: .body)
    }

    /// Bold paragraph weight, for buttons and small caps.
    static func label(_ size: CGFloat) -> Font {
        .custom("AvenirNext-DemiBold", size: size, relativeTo: .body)
    }

    /// Hand-lettered accents standing in for Whitenice, used sparingly.
    static func accent(_ size: CGFloat) -> Font {
        .custom("SnellRoundhand-Bold", size: size, relativeTo: .title)
    }
}

/// The four-point star used throughout the design.
struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: center)
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: center)
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: center)
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: center)
        return path
    }
}

/// The reference's signature shapes: two opposite corners round, two nearly square.
enum Leaf {
    /// Buttons, fields and chips: round top-left and bottom-right.
    static func button(_ radius: CGFloat = 22) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: radius, bottomLeadingRadius: 4, bottomTrailingRadius: radius, topTrailingRadius: 4)
    }

    /// Panels and illustrations: round top-right and bottom-left.
    static func frame(_ radius: CGFloat = 44) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: radius, bottomTrailingRadius: 6, topTrailingRadius: radius)
    }

    /// Selection tiles, like the reference's color swatches: an arched top.
    static func swatch(_ radius: CGFloat = 48) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: radius, bottomLeadingRadius: 6, bottomTrailingRadius: 6, topTrailingRadius: radius)
    }
}

/// Four rounded petals, the reference's flower decoration.
struct Flower: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width / 2, h = rect.height / 2
        for (x, y) in [(rect.minX, rect.minY), (rect.midX, rect.minY), (rect.minX, rect.midY), (rect.midX, rect.midY)] {
            let petal = CGRect(x: x, y: y, width: w, height: h)
            let corner = min(w, h) * 0.95
            // Each petal rounds every corner except the one touching the center.
            let isLeft = x == rect.minX, isTop = y == rect.minY
            path.addPath(UnevenRoundedRectangle(
                topLeadingRadius: isLeft && isTop ? corner : (isTop || isLeft ? corner : 0),
                bottomLeadingRadius: isLeft && !isTop ? corner : (!isTop || isLeft ? corner : 0),
                bottomTrailingRadius: !isLeft && !isTop ? corner : (!isTop || !isLeft ? corner : 0),
                topTrailingRadius: !isLeft && isTop ? corner : (isTop || !isLeft ? corner : 0)
            ).path(in: petal))
        }
        return path
    }
}

/// A spiky starburst, like the reference's sun and star stickers.
struct Burst: Shape {
    var points = 10
    var depth = 0.62

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        var path = Path()
        for index in 0..<(points * 2) {
            let radius = index.isMultiple(of: 2) ? outer : outer * depth
            let angle = Double(index) / Double(points * 2) * 2 * .pi - .pi / 2
            let point = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
