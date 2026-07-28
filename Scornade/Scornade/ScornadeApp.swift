import SwiftUI

@main
struct ScornadeApp: App {
    @StateObject private var store = Store()

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
    }
}
