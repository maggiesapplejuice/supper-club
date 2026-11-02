import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    // Values from the Figma style guide.
    static let brandPrimary = Color(hex: 0xB23A3A)
    static let brandSecondary = Color(hex: 0xF8E7D6)
    static let brandText = Color(hex: 0x1F1F1F)
    static let gray4 = Color(hex: 0x495057)
    static let gray3 = Color(hex: 0xACB5BD)
    static let gray2 = Color(hex: 0xDDE2E5)
    static let gray1 = Color(hex: 0xF8F9FA)
}
