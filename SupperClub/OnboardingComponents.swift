import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Sparkle().fill(.white).frame(width: 16, height: 16)
                Spacer()
                HStack(spacing: 8) {
                    if let systemImage {
                        Image(systemName: systemImage)
                    }
                    Text(title)
                }
                .font(.display(14))
                .tracking(0.6)
                Spacer()
                Sparkle().fill(.white).frame(width: 16, height: 16)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.ink.opacity(isEnabled ? 1 : 0.3), in: .capsule)
        }
        .disabled(!isEnabled)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.display(14))
                .foregroundStyle(Color.ink)
                .frame(maxWidth: .infinity, minHeight: 56)
                .overlay { Capsule().stroke(Color.ink, lineWidth: 2) }
        }
    }
}

struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 6) {
            ChefCharacter(size: 150)
            Text("Supper Club")
                .font(.display(30))
                .foregroundStyle(Color.ink)
            Text("join the global recipe exchange")
                .font(.text(13))
                .foregroundStyle(Color.gray4)
        }
        .frame(maxWidth: .infinity)
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
                    .font(.display(13))
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
            .frame(height: 50)
            .background(Color.white, in: .capsule)
            .overlay { Capsule().stroke(Color.ink, lineWidth: 2) }
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

    var body: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(Color.ink)
                .frame(width: proxy.size.width * min(1, max(0, value)))
        }
        .frame(height: 12)
        .background(Color.white, in: .capsule)
        .clipShape(.capsule)
        .overlay { Capsule().stroke(Color.ink, lineWidth: 2) }
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
                    .overlay { RoundedRectangle(cornerRadius: 13).stroke(Color.ink, lineWidth: 2) }
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
                .font(.display(25))
                .foregroundStyle(Color.ink)
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
                InkGlyphView(emoji: emoji, size: 42)
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
                    Circle().stroke(Color.ink, lineWidth: 2)
                    if isSelected {
                        Circle().fill(Color.ink)
                        Sparkle().fill(.white).frame(width: 13, height: 13)
                    }
                }
                .frame(width: 24, height: 24)
            }
            .padding(12)
            .background(isSelected ? Color.gray1 : .white, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.ink : Color.gray2, lineWidth: isSelected ? 2.5 : 2)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
