import SwiftUI

@main
struct ScornadeApp: App {
    @StateObject private var store = Store()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("sm.languagePreference") private var languagePreference = "system"

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
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { store.reloadFromCloud() }
        }
    }
}
