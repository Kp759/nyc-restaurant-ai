import AuthenticationServices
import UIKit

/// Presents Sign in with Apple without `SignInWithAppleButton`, which can crash
/// on device when the capability isn't in the provisioning profile.
final class AppleSignInController: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private var rawNonce = ""
    private var completion: ((Result<(ASAuthorizationAppleIDCredential, String), Error>) -> Void)?

    func signIn(completion: @escaping (Result<(ASAuthorizationAppleIDCredential, String), Error>) -> Void) {
        self.completion = completion
        rawNonce = SupabaseAuthClient.randomNonce()

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = SupabaseAuthClient.sha256(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            let handler = completion
            completion = nil
            DispatchQueue.main.async { handler?(.failure(SupabaseAuthError.invalidResponse)) }
            return
        }
        let handler = completion
        let nonce = rawNonce
        completion = nil
        DispatchQueue.main.async { handler?(.success((credential, nonce))) }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let handler = completion
        completion = nil
        DispatchQueue.main.async { handler?(.failure(error)) }
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
