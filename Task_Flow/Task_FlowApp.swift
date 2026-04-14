import SwiftUI
import FirebaseCore
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct Task_FlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var auth: AuthStore
    @StateObject private var store: AppStore
    @AppStorage("tf_dark_mode") private var darkMode = false

    init() {
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
