import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.system(size: 14, weight: .semibold))
            .tracking(0.6)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.brandPrimary.opacity(isEnabled ? 1 : 0.5), in: .rect(cornerRadius: 10))
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
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.brandPrimary)
                .frame(maxWidth: .infinity, minHeight: 50)
                .overlay {
                    RoundedRectangle(cornerRadius: 10).stroke(Color.brandPrimary)
                }
        }
    }
}

struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife")
                .font(.system(size: 20))
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 56, height: 56)
                .background(Color.gray1, in: .circle)
                .overlay { Circle().stroke(Color.gray2) }
            Text("SUPPER CLUB")
                .font(.system(size: 18, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.brandText)
            Text("Join the global recipe exchange")
                .font(.system(size: 12))
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
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.brandText)
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
            .font(.system(size: 14))
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(Color.gray1, in: .rect(cornerRadius: 10))
            .overlay { RoundedRectangle(cornerRadius: 10).stroke(Color.gray2) }
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

struct StepHeader: View {
    let step: Int
    let total: Int
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.brandText)
                    .frame(width: 36, height: 36)
                    .overlay { Circle().stroke(Color.gray2) }
            }
            .accessibilityLabel("Back")
            ProgressView(value: Double(step), total: Double(total))
                .tint(.brandPrimary)
            Text("\(step)/\(total)")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.gray4)
        }
    }
}

struct StepTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color.brandText)
            Text(subtitle)
                .font(.system(size: 14))
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
                Text(emoji)
                    .font(.system(size: 20))
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.brandSecondary : Color.gray1, in: .rect(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.brandText)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.gray4)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.gray3)
            }
            .padding(12)
            .background(.white, in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandPrimary : Color.gray2, lineWidth: isSelected ? 1.5 : 1)
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
