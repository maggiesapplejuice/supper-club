import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    // Ink on paper. The only color in the app is the Legendary holographic foil.
    static let paper = Color(hex: 0xFFFDFB)
    static let ink = Color(hex: 0x111111)
    static let brandPrimary = ink
    static let brandSecondary = Color(hex: 0xF3F3F3)
    static let brandText = ink
    static let gray4 = Color(hex: 0x6B6B6B)
    static let gray3 = Color(hex: 0xA8A8A8)
    static let gray2 = Color(hex: 0xE4E4E4)
    static let gray1 = Color(hex: 0xF5F5F5)
}

extension Font {
    /// Chunky slab for titles and buttons. Both faces ship with iOS.
    static func display(_ size: CGFloat) -> Font {
        .custom("Rockwell-Bold", size: size, relativeTo: .headline)
    }

    /// Typewriter face for supporting text.
    static func text(_ size: CGFloat) -> Font {
        .custom("AmericanTypewriter", size: size, relativeTo: .body)
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
