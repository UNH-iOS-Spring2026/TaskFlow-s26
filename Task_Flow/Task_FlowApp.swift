import SwiftUI

@main
struct Task_FlowApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var store = AppStore()
    @AppStorage("tf_dark_mode") private var darkMode = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
                .preferredColorScheme(darkMode ? .dark : .light)
        }
    }
}
