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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    modePicker
                    socialButtons
                    emailSection
                    guestButton
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 20)
            }
            .background(Color(.systemBackground))
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Bite").font(.display(.largeTitle, weight: .bold))
                Text("NYC").font(.display(.largeTitle, weight: .bold)).foregroundStyle(Theme.accent)
            }
            Text(mode == .login ? "Welcome back — let's find your next great meal." : "Join BiteNYC and save your taste, lists, and reservations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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

    private var socialButtons: some View {
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
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            AuthProviderButton(
                title: "Continue with Google",
                icon: "g.circle.fill",
                paletteIndex: 1
            ) {
                Task {
                    await auth.signInWithGoogle()
                    auth.applySessionToAccount(account)
                }
            }

            AuthProviderButton(
                title: "Continue with Email",
                icon: "envelope.fill",
                paletteIndex: 2
            ) {
                withAnimation(.easeInOut) { showEmailForm.toggle() }
            }
        }
    }

    @ViewBuilder
    private var emailSection: some View {
        if showEmailForm {
            VStack(alignment: .leading, spacing: 14) {
                if mode == .signUp {
                    AuthTextField(title: "Name", text: $name, contentType: .name)
                }
                AuthTextField(title: "Email", text: $email, contentType: .emailAddress, keyboard: .emailAddress)
                AuthTextField(title: "Password", text: $password, contentType: .password, isSecure: true)

                if let error = auth.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: submitEmail) {
                    Text(mode == .login ? "Log in with Email" : "Create Account")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canSubmitEmail)
                .opacity(canSubmitEmail ? 1 : 0.55)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.accent.opacity(0.08))
            )
        }
    }

    private var guestButton: some View {
        VStack(spacing: 8) {
            Button {
                auth.continueAsGuest()
            } label: {
                Text("Continue as guest")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            if !auth.usesRemoteAuth {
                Text("Supabase keys not set — social and email sign-in use local demo mode.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
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

struct AuthProviderButton: View {
    let title: String
    let icon: String
    let paletteIndex: Int
    let action: () -> Void

    private var palette: VibePalette { VibePalette.make(for: title, index: paletteIndex) }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(palette.colors.first?.opacity(0.35) ?? Theme.chipBackground)
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(palette.colors.last ?? Theme.accent)
                }
                .frame(width: 36, height: 36)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(palette.colors.first?.opacity(0.14) ?? Theme.chipBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(palette.colors.last?.opacity(0.22) ?? .clear, lineWidth: 1)
            )
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
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthStore())
        .environmentObject(AccountStore())
        .preferredColorScheme(.dark)
}
