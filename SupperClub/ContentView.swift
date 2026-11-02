import SwiftUI

struct ContentView: View {
    @State private var model = OnboardingModel()

    var body: some View {
        if model.isFinished {
            HomePlaceholderView()
        } else {
            NavigationStack(path: $model.path) {
                LoginView(model: model)
                    .navigationBarHidden(true)
                    .navigationDestination(for: OnboardingRoute.self) { route in
                        destination(for: route)
                            .navigationBarHidden(true)
                    }
            }
        }
    }

    @ViewBuilder
    private func destination(for route: OnboardingRoute) -> some View {
        switch route {
        case .signUp: SignUpView(model: model)
        case .experience: ExperienceStepView(model: model)
        case .cuisines: CuisineStepView(model: model)
        case .restrictions: RestrictionStepView(model: model)
        case .location: LocationStepView(model: model)
        }
    }
}

/// Stands in for the Discover screen until the trading flow is built.
private struct HomePlaceholderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.largeTitle)
                .foregroundStyle(Color.brandPrimary)
            Text("You're all set")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.brandText)
            Text("The trading flow goes here next.")
                .foregroundStyle(Color.gray4)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
