import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthStore

    var body: some View {
        Group {
            if auth.isLoggedIn {
                MainTabView()   // ✅ dashboard after login
            } else {
                AuthView()      // ✅ login screen
            }
        }
    }
}
