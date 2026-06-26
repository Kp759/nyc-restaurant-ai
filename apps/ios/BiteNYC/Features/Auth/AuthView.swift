import AuthenticationServices
import SwiftUI

enum AuthMode: String, CaseIterable, Identifiable {
    case login = "Log in"
    case signUp = "Sign up"
    var id: String { rawValue }
}

struct AuthView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var account: AccountStore

    @State private var mode: AuthMode = .login
    @State private var showEmailForm = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var appleNonce = ""

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.accent, Color(red: 0.96, green: 0.18, blue: 0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Theme.accent.opacity(0.12),
                        Color(red: 0.96, green: 0.18, blue: 0.55).opacity(0.08),
                        Color(.systemBackground),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer(minLength: 48)

                        header
                        modePicker
                        authButtons
                        emailSection
                        guestButton

                        Spacer(minLength: 48)
                    }
                    .frame(maxWidth: 400)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 28)
                }
            }
            .overlay {
                if auth.isLoading {
                    ZStack {
                        Color.black.opacity(0.25).ignoresSafeArea()
                        FoodPunLoadingView(quotes: LoadingQuotes.auth, minHeight: 160)
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color(.systemBackground))
                            )
                            .padding(.horizontal, 32)
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Bite").font(.display(.largeTitle, weight: .bold))
                Text("NYC").font(.display(.largeTitle, weight: .bold)).foregroundStyle(Theme.accent)
            }

            Text(mode == .login ? "Welcome back — let's find your next great meal." : "Join BiteNYC and save your taste, lists, and reservations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(AuthMode.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, _ in
            auth.errorMessage = nil
            showEmailForm = false
        }
    }

    private var authButtons: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(mode == .login ? .signIn : .signUp) { request in
                let nonce = SupabaseAuthClient.randomNonce()
                appleNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = SupabaseAuthClient.sha256(nonce)
            } onCompletion: { result in
                switch result {
                case let .success(authorization):
                    if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        Task {
                            await auth.signInWithApple(credential, rawNonce: appleNonce)
                            auth.applySessionToAccount(account)
                        }
                    }
                case let .failure(error):
                    if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                        auth.errorMessage = error.localizedDescription
                    }
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.12), radius: 6, y: 3)

            AuthBrandButton(
                title: "Continue with Google",
                icon: "g.circle.fill",
                style: .google
            ) {
                Task {
                    await auth.signInWithGoogle()
                    auth.applySessionToAccount(account)
                }
            }

            AuthBrandButton(
                title: showEmailForm ? "Hide email form" : "Continue with Email",
                icon: "envelope.fill",
                style: .email
            ) {
                withAnimation(.easeInOut) { showEmailForm.toggle() }
            }
        }
    }

    @ViewBuilder
    private var emailSection: some View {
        if showEmailForm {
            VStack(spacing: 14) {
                if mode == .signUp {
                    AuthTextField(title: "Name", text: $name, contentType: .name)
                }
                AuthTextField(title: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
                AuthTextField(title: "Password", text: $password, contentType: .password, isSecure: true)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                Button(action: submitEmail) {
                    Text(mode == .login ? "Log in with Email" : "Create Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Theme.accent.opacity(0.35), radius: 8, y: 4)
                }
                .disabled(!canSubmitEmail)
                .opacity(canSubmitEmail ? 1 : 0.55)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Theme.accent.opacity(0.2), lineWidth: 1)
                    )
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var guestButton: some View {
        VStack(spacing: 8) {
            Button {
                auth.continueAsGuest()
            } label: {
                Text("Continue as guest")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            if !auth.usesRemoteAuth {
                Text("Supabase keys not set — social and email sign-in use local demo mode.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var canSubmitEmail: Bool {
        let hasEmail = email.contains("@") && password.count >= 6
        return mode == .login ? hasEmail : (!name.trimmingCharacters(in: .whitespaces).isEmpty && hasEmail)
    }

    private func submitEmail() {
        Task {
            if mode == .login {
                await auth.signIn(email: email, password: password)
            } else {
                await auth.signUp(name: name, email: email, password: password)
            }
            auth.applySessionToAccount(account)
        }
    }
}

enum AuthBrandStyle {
    case google, email

    var background: LinearGradient {
        switch self {
        case .google:
            return LinearGradient(
                colors: [
                    Color(red: 0.26, green: 0.52, blue: 0.96),
                    Color(red: 0.18, green: 0.40, blue: 0.88),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .email:
            return LinearGradient(
                colors: [
                    Theme.accent,
                    Color(red: 0.96, green: 0.18, blue: 0.55),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var shadowColor: Color {
        switch self {
        case .google: return Color(red: 0.26, green: 0.52, blue: 0.96)
        case .email: return Theme.accent
        }
    }
}

struct AuthBrandButton: View {
    let title: String
    let icon: String
    let style: AuthBrandStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: style.shadowColor.opacity(0.35), radius: 8, y: 4)
        }
        .buttonStyle(CardPressStyle())
    }
}

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var contentType: UITextContentType?
    var keyboard: UIKeyboardType = .default
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            Group {
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                }
            }
            .textContentType(contentType)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Theme.accent.opacity(0.25), lineWidth: 1)
            )
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthStore())
        .environmentObject(AccountStore())
        .preferredColorScheme(.dark)
}
