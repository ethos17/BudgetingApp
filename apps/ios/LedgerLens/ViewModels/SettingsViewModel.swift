import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var includePendingInBudget = false
    @Published var notifyOnPending = false
    @Published var isLoading = false
    @Published var saveSuccess = false
    @Published var errorMessage: String?

    private let client = APIClient.shared
    private let sessionStore: SessionStore

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let s: Settings = try await client.request(path: "/settings")
            includePendingInBudget = s.include_pending_in_budget
            notifyOnPending = s.notify_on_pending
        } catch let e as APIError {
            sessionStore.handleAPIError(e)
            if case .httpStatus(401, _) = e { } else {
                switch e {
                case .backend(let b): errorMessage = b.error.message
                case .httpStatus(_, let m): errorMessage = m ?? String(describing: e)
                default: errorMessage = String(describing: e)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() async {
        await sessionStore.logout()
    }

    func save() async {
        errorMessage = nil
        saveSuccess = false
        struct PatchBody: Encodable {
            let include_pending_in_budget: Bool
            let notify_on_pending: Bool
        }
        do {
            let _: Settings = try await client.request(
                path: "/settings",
                method: "PATCH",
                body: PatchBody(include_pending_in_budget: includePendingInBudget, notify_on_pending: notifyOnPending)
            )
            saveSuccess = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                saveSuccess = false
            }
        } catch let e as APIError {
            sessionStore.handleAPIError(e)
            if case .httpStatus(401, _) = e { } else {
                switch e {
                case .backend(let b): errorMessage = b.error.message
                case .httpStatus(_, let m): errorMessage = m ?? String(describing: e)
                default: errorMessage = String(describing: e)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
