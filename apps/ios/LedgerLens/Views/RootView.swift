import SwiftUI

struct RootView: View {
    @ObservedObject var sessionStore: SessionStore

    var body: some View {
        Group {
            switch sessionStore.state {
            case .unknown:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .authenticated:
                MainTabView(sessionStore: sessionStore)
            case .unauthenticated:
                AuthStackView(sessionStore: sessionStore)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: sessionStore.state.isAuthenticated)
    }
}

struct AuthStackView: View {
    @ObservedObject var sessionStore: SessionStore
    @StateObject private var authViewModel: AuthViewModel

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        _authViewModel = StateObject(wrappedValue: AuthViewModel(sessionStore: sessionStore))
    }

    var body: some View {
        NavigationStack {
            LoginView(viewModel: authViewModel)
                .navigationDestination(for: AuthRoute.self) { _ in
                    SignupView(viewModel: authViewModel)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink(value: AuthRoute.signup) {
                            Text("Sign Up")
                        }
                    }
                }
        }
    }
}

enum AuthRoute: Hashable {
    case signup
}

extension SessionStore.State {
    var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
}
