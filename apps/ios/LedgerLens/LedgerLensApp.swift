import SwiftUI

@main
struct LedgerLensApp: App {
    @StateObject private var sessionStore = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView(sessionStore: sessionStore)
                .task {
                    await sessionStore.checkSession()
                }
        }
    }
}
