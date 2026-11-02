import CoreLocation
import SwiftUI

// The sign-up screen counts as step 1 of 5.
private let totalSteps = 5

/// Shared layout: header and title at the top, scrolling content, fixed buttons at the bottom.
private struct StepScaffold<Content: View, Footer: View>: View {
    let step: Int
    let title: String
    let subtitle: String
    let onBack: () -> Void
    @ViewBuilder var content: () -> Content
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(step: step, total: totalSteps, onBack: onBack)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            ScrollView {
                VStack(spacing: 20) {
                    StepTitle(title: title, subtitle: subtitle)
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            VStack(spacing: 12, content: footer)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
    }
}

struct ExperienceStepView: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        StepScaffold(
            step: 2,
            title: "How much experience do you have with cooking?",
            subtitle: "This helps us recommend recipes that match your skill level.",
            onBack: model.goBack
        ) {
            VStack(spacing: 12) {
                ForEach(CookingExperience.allCases) { level in
                    OptionRow(
                        emoji: level.emoji,
                        title: level.rawValue,
                        subtitle: level.detail,
                        isSelected: model.experience == level
                    ) {
                        model.experience = level
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "CONTINUE →", isEnabled: model.experience != nil) {
                model.path.append(.cuisines)
            }
        }
    }
}

struct CuisineStepView: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        StepScaffold(
            step: 3,
            title: "Which cuisines do you enjoy?",
            subtitle: "Select all that apply. This helps us tailor your recipe feed.",
            onBack: model.goBack
        ) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 12) {
                ForEach(cuisineOptions) { cuisine in
                    CuisineTile(cuisine: cuisine, isSelected: model.cuisines.contains(cuisine.name)) {
                        model.cuisines.formSymmetricDifference([cuisine.name])
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "CONTINUE →", isEnabled: !model.cuisines.isEmpty) {
                model.path.append(.restrictions)
            }
        }
    }
}

private struct CuisineTile: View {
    let cuisine: OnboardingOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(cuisine.emoji)
                    .font(.system(size: 52))
                    .frame(maxWidth: .infinity, minHeight: 104)
                    .background(Color.brandSecondary, in: .rect(cornerRadius: 8))
                Text(cuisine.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.brandText)
            }
            .padding(8)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandPrimary : Color.gray2, lineWidth: isSelected ? 1.5 : 1)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white, Color.brandPrimary)
                        .padding(4)
                }
            }
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct RestrictionStepView: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        StepScaffold(
            step: 4,
            title: "Any allergies or dietary restrictions?",
            subtitle: "Select all that apply. We'll filter your results accordingly.",
            onBack: model.goBack
        ) {
            VStack(spacing: 12) {
                ForEach(restrictionOptions) { option in
                    OptionRow(
                        emoji: option.emoji,
                        title: option.name,
                        isSelected: model.restrictions.contains(option.name)
                    ) {
                        model.restrictions.formSymmetricDifference([option.name])
                    }
                }
            }
        } footer: {
            PrimaryButton(title: "CONTINUE →", isEnabled: !model.restrictions.isEmpty) {
                model.path.append(.location)
            }
            SecondaryButton(title: "Skip") {
                model.restrictions.removeAll()
                model.path.append(.location)
            }
        }
    }
}

struct LocationStepView: View {
    let model: OnboardingModel
    @State private var permission = LocationPermission()

    var body: some View {
        VStack(spacing: 0) {
            StepHeader(step: 5, total: totalSteps, onBack: model.goBack)
                .padding(.bottom, 20)
            LocalMapIllustration()
            Text("Discover local recipe trades")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.brandText)
                .padding(.top, 28)
            Text("Connect with neighbors and swap authentic home-cooked recipes. Enable location to see what's cooking nearby.")
                .font(.system(size: 14))
                .foregroundStyle(Color.gray4)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            Spacer()
            VStack(spacing: 12) {
                PrimaryButton(title: "Share My Location", systemImage: "mappin.circle") {
                    permission.request(completion: model.finish)
                }
                SecondaryButton(title: "Not Now", action: model.finish)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
    }
}

private struct LocalMapIllustration: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Canvas { context, size in
                let spacing: CGFloat = 24
                for x in stride(from: spacing, to: size.width, by: spacing) {
                    let line = Path { $0.addLines([CGPoint(x: x, y: 0), CGPoint(x: x, y: size.height)]) }
                    context.stroke(line, with: .color(Color.brandPrimary.opacity(0.12)), lineWidth: 2)
                }
                for y in stride(from: spacing, to: size.height, by: spacing) {
                    let line = Path { $0.addLines([CGPoint(x: 0, y: y), CGPoint(x: size.width, y: y)]) }
                    context.stroke(line, with: .color(Color.brandPrimary.opacity(0.12)), lineWidth: 2)
                }
            }
            .background(Color.brandSecondary.opacity(0.5))
            HStack(alignment: .top, spacing: 8) {
                NearbyCard(emoji: "🍝", name: "Pasta al Limone", distance: "0.3 mi")
                NearbyCard(emoji: "🌮", name: "Chicken Fajitas", distance: "0.5 mi")
                NearbyCard(emoji: "🍣", name: "Sushi Platter", distance: "0.7 mi")
            }
            .padding(12)
            .frame(maxHeight: .infinity, alignment: .top)
            Label("YOU ARE HERE", systemImage: "mappin.circle")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color.brandPrimary, in: .capsule)
                .padding(.bottom, 16)
        }
        .frame(height: 240)
        .clipShape(.rect(cornerRadius: 14))
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(Color.gray2) }
        .accessibilityHidden(true)
    }
}

private struct NearbyCard: View {
    let emoji: String
    let name: String
    let distance: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.brandSecondary, in: .rect(cornerRadius: 6))
            Text(name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.brandText)
                .lineLimit(2, reservesSpace: true)
            Label(distance, systemImage: "mappin")
                .font(.system(size: 10))
                .foregroundStyle(Color.brandPrimary)
        }
        .padding(6)
        .background(.white, in: .rect(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

@MainActor
private final class LocationPermission: NSObject, @preconcurrency CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: (() -> Void)?

    func request(completion: @escaping () -> Void) {
        guard manager.authorizationStatus == .notDetermined else {
            completion()
            return
        }
        self.completion = completion
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else { return }
        completion?()
        completion = nil
    }
}

#Preview("Experience") {
    ExperienceStepView(model: OnboardingModel())
}

#Preview("Cuisines") {
    CuisineStepView(model: OnboardingModel())
}

#Preview("Restrictions") {
    RestrictionStepView(model: OnboardingModel())
}

#Preview("Location") {
    LocationStepView(model: OnboardingModel())
}
