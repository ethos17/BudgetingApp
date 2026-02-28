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
        } catch APIError.httpStatus(401, _) {
            sessionStore.handleAPIError(error as! APIError)
        } catch {
            errorMessage = (error as? APIError).map { e in
                if case .backend(let b) = e { return b.error.message }
                return String(describing: e)
            } ?? error.localizedDescription
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
        } catch APIError.httpStatus(401, _) {
            sessionStore.handleAPIError(error as! APIError)
        } catch {
            errorMessage = (error as? APIError).map { e in
                if case .backend(let b) = e { return b.error.message }
                return String(describing: e)
            } ?? error.localizedDescription
        }
    }
}
