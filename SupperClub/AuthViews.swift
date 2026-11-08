import SwiftUI

struct LoginView: View {
    let model: OnboardingModel
    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool { !email.isEmpty && !password.isEmpty }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BrandHeader()
                    .padding(.bottom, 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back")
                        .font(.display(22))
                        .foregroundStyle(Color.brandText)
                    Text("Please enter your details to sign in")
                        .font(.text(13))
                        .foregroundStyle(Color.gray4)
                }
                LabeledField(label: "Email Address", placeholder: "chef@supperclub.com", text: $email, keyboard: .emailAddress)
                LabeledField(label: "Password", placeholder: "Password", text: $password, isSecure: true) {
                    // Password reset needs a backend.
                    Button("Forgot password?") {}
                        .font(.text(12))
                        .foregroundStyle(Color.brandPrimary)
                }
                PrimaryButton(title: "LOG IN", isEnabled: canSubmit) {
                    model.logIn()
                }
                HStack(spacing: 12) {
                    Rectangle().fill(Color.ink).frame(height: 2)
                    Text("Or continue with")
                        .font(.text(12))
                        .foregroundStyle(Color.gray4)
                        .fixedSize()
                    Rectangle().fill(Color.ink).frame(height: 2)
                }
                HStack(spacing: 12) {
                    SocialButton(title: "Google", systemImage: "globe") { model.signUp() }
                    SocialButton(title: "Apple", systemImage: "apple.logo") { model.signUp() }
                }
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundStyle(Color.gray4)
                    Button("Sign Up") { model.path.append(.signUp) }
                        .underline()
                        .foregroundStyle(Color.brandPrimary)
                }
                .font(.text(13))
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

struct SignUpView: View {
    let model: OnboardingModel
    @State private var fullName = ""
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool {
        !fullName.isEmpty && !username.isEmpty && !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BrandHeader()
                    .padding(.bottom, 10)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create your account")
                        .font(.display(22))
                        .foregroundStyle(Color.brandText)
                    Text("Please enter your details to get started")
                        .font(.text(13))
                        .foregroundStyle(Color.gray4)
                }
                LabeledField(label: "Full Name", placeholder: "Gordon Ramsay", text: $fullName)
                LabeledField(label: "Username", placeholder: "chef_gordon", text: $username)
                LabeledField(label: "Email Address", placeholder: "chef@supperclub.com", text: $email, keyboard: .emailAddress)
                LabeledField(label: "Password", placeholder: "Password", text: $password, isSecure: true)
                PrimaryButton(title: "SIGN UP", isEnabled: canSubmit) {
                    model.signUp()
                }
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(Color.gray4)
                    Button("Log In") { model.path.removeAll() }
                        .underline()
                        .foregroundStyle(Color.brandPrimary)
                }
                .font(.text(13))
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct SocialButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.text(13))
                .foregroundStyle(Color.brandText)
                .frame(maxWidth: .infinity, minHeight: 52)
                .overlay { Capsule().stroke(Color.gray2, lineWidth: 1.5) }
        }
    }
}

#Preview("Log in") {
    LoginView(model: OnboardingModel())
}

#Preview("Sign up") {
    SignUpView(model: OnboardingModel())
}
