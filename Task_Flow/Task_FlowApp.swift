import SwiftUI
import FirebaseCore

@main
struct Task_FlowApp: App {
    @StateObject private var authStore: AuthStore
    @StateObject private var appStore: AppStore

    init() {
        FirebaseApp.configure()

        let auth = AuthStore()
        _authStore = StateObject(wrappedValue: auth)
        _appStore = StateObject(wrappedValue: AppStore(auth: auth))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authStore)
                .environmentObject(appStore)
        }
    }
}
