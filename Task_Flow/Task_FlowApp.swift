import SwiftUI
import FirebaseCore

@main
struct Task_FlowApp: App {
    @StateObject private var auth: AuthStore
    @StateObject private var store: AppStore

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        let authStore = AuthStore()
        let appStore = AppStore(auth: authStore)

        _auth = StateObject(wrappedValue: authStore)
        _store = StateObject(wrappedValue: appStore)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
        }
    }
}
