import SwiftUI

struct ContentView: View {
    @State private var model = OnboardingModel()

    var body: some View {
        Group {
            if let pack = model.unopenedPack {
                PackOpeningView(recipes: pack, restrictions: model.restrictions, onFinish: model.collectPack)
            } else if model.isFinished {
                MainTabView(model: model)
            } else {
                NavigationStack(path: $model.path) {
                    LoginView(model: model)
                        .navigationBarHidden(true)
                        .background(Color.paper.ignoresSafeArea())
                        .navigationDestination(for: OnboardingRoute.self) { route in
                            destination(for: route)
                                .navigationBarHidden(true)
                                .background(Color.paper.ignoresSafeArea())
                        }
                }
            }
        }
        .preferredColorScheme(.light)
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

#Preview {
    ContentView()
}
