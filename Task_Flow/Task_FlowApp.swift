import SwiftUI
import FirebaseCore

@main
struct Task_FlowApp: App {
    @StateObject private var auth: AuthStore
    @StateObject private var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        let sharedAuth = AuthStore()
        _auth = StateObject(wrappedValue: sharedAuth)
        _store = StateObject(wrappedValue: AppStore(auth: sharedAuth))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
}
