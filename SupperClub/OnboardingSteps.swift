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
            CuisinePicker(selection: $model.cuisines)
        } footer: {
            PrimaryButton(title: "CONTINUE →", isEnabled: !model.cuisines.isEmpty) {
                model.path.append(.restrictions)
            }
        }
    }
}

struct RestrictionStepView: View {
    @Bindable var model: OnboardingModel

    var body: some View {
        StepScaffold(
            step: 4,
            title: "Any allergies or dietary restrictions?",
            subtitle: "Optional. Select all that apply, even the niche ones, or skip if none apply.",
            onBack: model.goBack
        ) {
            RestrictionPicker(selection: $model.restrictions)
        } footer: {
            // Nothing selected is a fine answer, so the button never blocks the cook.
            PrimaryButton(title: model.restrictions.isEmpty ? "SKIP, NO RESTRICTIONS →" : "CONTINUE →") {
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
                .padding(.bottom, 24)
            NearbyIllustration()
            VStack(spacing: 10) {
                Text("Find cooks near you")
                    .font(.display(28))
                    .foregroundStyle(Color.ink)
                Text("Share your location and we'll show recipes from home cooks in your area first. You can change this anytime in Settings.")
                    .font(.text(15))
                    .foregroundStyle(Color.gray4)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 28)
            Spacer()
            VStack(spacing: 12) {
                PrimaryButton(title: "Share my location", systemImage: "location.fill") {
                    permission.request(completion: model.finish)
                }
                SecondaryButton(title: "Skip for now", action: model.finish)
                HStack(spacing: 6) {
                    Sparkle().fill(Color.sunflower).frame(width: 12, height: 12)
                    Text("Next up: open your free starter pack")
                        .font(.label(13))
                        .foregroundStyle(Color.ink)
                }
                .padding(.top, 4)
            }
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
    }
}

/// A pin among nearby dishes, in the references' sticker style.
private struct NearbyIllustration: View {
    var body: some View {
        ZStack {
            Leaf.frame().fill(Color.sky.opacity(0.55))
            Circle().fill(Color.butter).frame(width: 150, height: 150)
            Image(systemName: "mappin")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Color.rose)
            GlyphBubble(emoji: "🍝", diameter: 54, fill: .blush).offset(x: -110, y: -50)
            GlyphBubble(emoji: "🌮", diameter: 48, fill: .mint).offset(x: 118, y: -36)
            GlyphBubble(emoji: "🍣", diameter: 46, fill: .lilac).offset(x: 90, y: 72)
            Flower().fill(Color.blush).frame(width: 28, height: 28).offset(x: -120, y: 70)
            Burst().fill(Color.sunflower).frame(width: 30, height: 30).offset(x: 130, y: -88)
            Sparkle().fill(Color.ink).frame(width: 16, height: 16).offset(x: -60, y: -92)
        }
        .frame(height: 250)
        .accessibilityHidden(true)
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
