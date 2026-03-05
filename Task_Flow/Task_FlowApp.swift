import SwiftUI

@main
struct Task_FlowApp: App {
    @StateObject private var auth = AuthStore()
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
        }
    }
}
