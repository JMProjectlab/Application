import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var store: Store
    @State private var authError: String?

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
                    Text("Sc").font(.system(size: 18, weight: .bold)).foregroundStyle(Color.brand)
                }
                Text("Scornade").font(.system(size: 30, weight: .semibold))
                Text("Comptez. Gagnez. Recommencez.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
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
                authError = "Identifiants Apple non reconnus."
                return
            }
            let name = [cred.fullName?.givenName, cred.fullName?.familyName]
                .compactMap { $0 }.joined(separator: " ")
            store.signIn(id: cred.user,
                         name: name.isEmpty ? "Joueur Apple" : name,
                         email: cred.email,
                         mode: .apple)
        case .failure(let error):
            authError = error.localizedDescription
        }
    }
}
