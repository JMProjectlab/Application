import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var store: Store
    @Environment(\.locale) private var locale
    @State private var authError: String?
    @State private var currentNonce: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(Color.brand).frame(width: 80, height: 80)
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.brandLight)
                        .frame(width: 34, height: 46)
                        .rotationEffect(.degrees(-10)).offset(x: -3, y: 2)
                    RoundedRectangle(cornerRadius: 7).fill(.white).frame(width: 34, height: 46)
                    Text("Sc").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.ink)
                }
                Text("Scornade").font(.jmDisplay).jmTightTracking(34)
                Text("Comptez. Gagnez. Recommencez.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                    // Firebase exige un nonce haché : il lie le jeton d'identité
                    // renvoyé par Apple à cette demande précise, ce qui empêche
                    // qu'un jeton intercepté serve à se connecter ailleurs.
                    let nonce = AppleNonce.random()
                    currentNonce = nonce
                    request.nonce = AppleNonce.sha256(nonce)
                } onCompletion: { result in
                    handleApple(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 8) {
                    Rectangle().fill(Color(.separator)).frame(height: 0.5)
                    Text("ou").font(.caption).foregroundStyle(.secondary)
                    Rectangle().fill(Color(.separator)).frame(height: 0.5)
                }
                .padding(.vertical, 2)

                Button { store.signInGuest() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person")
                        Text("Continuer en mode invité").fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.brandLight)
                    .foregroundStyle(Color.brandDark)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("En mode invité, vos données sont sauvegardées uniquement sur cet appareil.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .alert("Connexion impossible", isPresented: .constant(authError != nil)) {
            Button("OK") { authError = nil }
        } message: {
            Text(authError ?? "")
        }
    }

    private func handleApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else {
                authError = String(localized: "Identifiants Apple non reconnus.", locale: locale)
                return
            }
            // Apple ne transmet le nom qu'à la toute première connexion : on le
            // capte ici, sinon on retombera sur le libellé générique.
            let name = [cred.fullName?.givenName, cred.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            let displayName = name.isEmpty ? "Joueur Apple" : name

            // Sans Firebase configuré, on reste sur une session purement locale
            // plutôt que d'échouer : l'app doit rester utilisable.
            guard FirebaseSupport.isAvailable,
                  let nonce = currentNonce,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                store.signIn(id: cred.user, name: displayName, email: cred.email, mode: .apple)
                return
            }

            let credential = OAuthProvider.appleCredential(withIDToken: token,
                                                           rawNonce: nonce,
                                                           fullName: cred.fullName)
            Auth.auth().signIn(with: credential) { authResult, error in
                currentNonce = nil
                if let error {
                    authError = error.localizedDescription
                    return
                }
                store.signIn(id: authResult?.user.uid ?? cred.user,
                             name: displayName,
                             email: cred.email ?? authResult?.user.email,
                             mode: .apple)
            }
        case .failure(let error):
            currentNonce = nil
            // L'utilisateur qui referme la feuille Apple n'a pas besoin d'alerte.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            authError = error.localizedDescription
        }
    }
}

/// Nonce à usage unique pour « Se connecter avec Apple » via Firebase.
enum AppleNonce {
    static func random(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var byte: UInt8 = 0
            guard SecRandomCopyBytes(kSecRandomDefault, 1, &byte) == errSecSuccess else { continue }
            if byte < charset.count {
                result.append(charset[Int(byte)])
                remaining -= 1
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
