import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func login() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await sessionStore.login(email: email, password: password)
        } catch APIError.backend(let be) {
            errorMessage = be.error.message
        } catch APIError.httpStatus(401, _) {
            errorMessage = "Invalid email or password."
        } catch {
            errorMessage = (error as? APIError).map { e in
                if case .httpStatus(_, let m) = e, let m = m { return m }
                return String(describing: e)
            } ?? error.localizedDescription
        }
    }

    func signup() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await sessionStore.signup(email: email, password: password)
        } catch APIError.backend(let be) {
            errorMessage = be.error.message
        } catch {
            errorMessage = (error as? APIError).map { e in
                if case .httpStatus(_, let m) = e, let m = m { return m }
                return String(describing: e)
            } ?? error.localizedDescription
        }
    }
}
