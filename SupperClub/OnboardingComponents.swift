import SwiftUI

/// The main call to action: a pink leaf shape with white caps.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isEnabled = true
    var fill: Color = .rose
    let action: () -> Void

    @State private var taps = 0

    private var textColor: Color { [.sage, .ink, .rose, .grape, .poppy, .periwinkle, .storm].contains(fill) ? .white : .ink }

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title.uppercased())
                    .tracking(1.2)
            }
            .font(.label(15))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(isEnabled ? fill : Color.blush, in: Leaf.button())
            .opacity(isEnabled ? 1 : 0.6)
        }
        .buttonStyle(PressDownStyle())
        .disabled(!isEnabled)
        .sensoryFeedback(.impact(weight: .medium), trigger: taps)
    }
}

/// Squashes the button slightly while pressed.
struct PressDownStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.2, bounce: 0.5), value: configuration.isPressed)
    }
}

/// The quieter choice: a butter leaf shape with plum caps.
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    @State private var taps = 0

    var body: some View {
        Button {
            taps += 1
            action()
        } label: {
            Text(title.uppercased())
                .tracking(1.2)
                .font(.label(14))
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.butter, in: Leaf.button())
        }
        .buttonStyle(PressDownStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: taps)
    }
}

struct BrandHeader: View {
    /// Food stickers orbiting the chef: emoji, color, angle in degrees.
    private let stickers: [(String, Color, Double)] = [
        ("🍜", .butter, 200), ("🐟", .sky, 245), ("🥦", .mint, 295), ("🍰", .blush, 340), ("🌮", .peach, 20),
        ("🍳", .lilac, 160),
    ]

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                ChefBubble(diameter: 156)
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    ZStack {
                        ForEach(Array(stickers.enumerated()), id: \.offset) { index, sticker in
                            let angle = (sticker.2 + sin(time * 0.8 + Double(index)) * 4) * .pi / 180
                            GlyphBubble(emoji: sticker.0, diameter: 42, fill: sticker.1)
                                .rotationEffect(.degrees(sin(time * 1.4 + Double(index)) * 8))
                                .offset(x: cos(angle) * 118, y: sin(angle) * 92)
                        }
                    }
                }
                .accessibilityHidden(true)
            }
            .frame(height: 180)
            SupperClubLogo(size: 54)
                .padding(.top, 6)
            Text("Trade Recipes With The World")
                .font(.label(15))
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity)
        .background(alignment: .topLeading) {
            // Scattered stickers like the references' illustration sheets.
            ZStack {
                Burst().fill(Color.sunflower).frame(width: 34, height: 34).offset(x: 22, y: 8)
                Flower().fill(Color.blush).frame(width: 26, height: 26).offset(x: 330, y: 150)
                Sparkle().fill(Color.sage).frame(width: 18, height: 18).offset(x: 60, y: 168)
                Burst(points: 8, depth: 0.5).fill(Color.sky).frame(width: 24, height: 24).offset(x: 344, y: 12)
            }
            .accessibilityHidden(true)
        }
    }
}

struct LabeledField<Accessory: View>: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    @ViewBuilder var accessory: () -> Accessory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.label(13))
                    .foregroundStyle(Color.ink)
                Spacer()
                accessory()
            }
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboard)
                }
            }
            .textInputAutocapitalization(label == "Full Name" ? .words : .never)
            .autocorrectionDisabled()
            .font(.text(14))
            .padding(.horizontal, 20)
            .frame(height: 52)
            .background(Color.white, in: Leaf.button(18))
            .overlay { Leaf.button(18).strokeBorder(Color.gray2, lineWidth: 1.5) }
        }
    }
}

extension LabeledField where Accessory == EmptyView {
    init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboard: UIKeyboardType = .default
    ) {
        self.init(label: label, placeholder: placeholder, text: text, isSecure: isSecure, keyboard: keyboard) {
            EmptyView()
        }
    }
}

struct InkProgressBar: View {
    let value: Double
    var fill: Color = .tomato

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(fill)
                .frame(width: proxy.size.width * min(1, max(0, value)))
        }
        .frame(height: 12)
        .background(Color.blush, in: .capsule)
        .clipShape(.capsule)
    }
}

struct StepHeader: View {
    let step: Int
    let total: Int
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 44, height: 44)
                    .background(Color.butter, in: Leaf.button(16))
            }
            .accessibilityLabel("Back")
            InkProgressBar(value: Double(step) / Double(total))
                .accessibilityLabel("Step \(step) of \(total)")
            Text("\(step)/\(total)")
                .font(.text(13))
                .foregroundStyle(Color.ink)
        }
    }
}

struct StepTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.display(24))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle)
                .font(.text(14))
                .foregroundStyle(Color.gray4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Row used by the experience and dietary steps.
struct OptionRow: View {
    let emoji: String
    let title: String
    var subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                GlyphBubble(emoji: emoji, diameter: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.display(15))
                        .foregroundStyle(Color.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.text(13))
                            .foregroundStyle(Color.gray4)
                    }
                }
                Spacer()
                ZStack {
                    Circle().fill(isSelected ? Color.sage : Color.gray1)
                    if isSelected {
                        Sparkle().fill(.white).frame(width: 13, height: 13)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .padding(12)
            .background(isSelected ? Color.butter : .white, in: Leaf.button(26))
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
