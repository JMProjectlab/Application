import SwiftUI
import GoogleSignIn

@main
struct ScornadeApp: App {
    @StateObject private var store = Store()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("sm.languagePreference") private var languagePreference = "system"

    init() {
        // Doit précéder la création du Store, qui interroge Auth dès son init.
        // L'autoclosure d'un @StateObject n'est évaluée qu'au premier accès au
        // corps de la vue, donc après ce init : l'ordre est garanti.
        FirebaseSupport.configureIfPossible()
    }

    // "system" laisse SwiftUI suivre la langue de l'appareil (comportement par défaut).
    private var localeOverride: Locale? {
        languagePreference == "system" ? nil : Locale(identifier: languagePreference)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if store.currentUser == nil {
                    LoginView()
                } else {
                    HomeView()
                }
            }
            .environmentObject(store)
            .tint(Color.brand)
            .environment(\.locale, localeOverride ?? Locale.autoupdatingCurrent)
            .onOpenURL { url in
                // Retour de la feuille de connexion Google.
                _ = GIDSignIn.sharedInstance.handle(url)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { store.reloadFromCloud() }
        }
    }
}
