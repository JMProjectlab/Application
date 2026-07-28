import SwiftUI

@main
struct ScornadeApp: App {
    @StateObject private var store = Store()
    @Environment(\.scenePhase) private var scenePhase

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
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { store.reloadFromCloud() }
        }
    }
}
