import Foundation
import FirebaseCore

/// Point d'entrée unique vers Firebase.
///
/// `FirebaseApp.configure()` lève une exception fatale si `GoogleService-Info.plist`
/// est absent du bundle. On vérifie donc sa présence d'abord : tant que le fichier
/// n'a pas été déposé dans le projet, l'application démarre quand même et
/// fonctionne en local, sans synchronisation.
enum FirebaseSupport {
    private(set) static var isAvailable = false

    static func configureIfPossible() {
        guard !isAvailable else { return }
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            #if DEBUG
            print("[Scornade] GoogleService-Info.plist absent : synchronisation désactivée, "
                  + "les données restent sur l'appareil.")
            #endif
            return
        }
        FirebaseApp.configure()
        isAvailable = true
    }
}
