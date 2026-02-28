import Foundation

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var addSheetError: String?

    // Add account form
    @Published var selectedProvider = "MOCK"
    @Published var accountName = ""
    @Published var selectedType = "CHECKING"
    @Published var isLinking = false

    private let client = APIClient.shared
    private let sessionStore: SessionStore

    static let providers = ["CHASE", "SOFI", "DISCOVER", "MOCK"]
    static let accountTypes = ["CHECKING", "DEBIT", "CREDIT"]

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let list: [Account] = try await client.request(path: "/accounts")
            accounts = list
        } catch APIError.httpStatus(401, _) {
            sessionStore.handleAPIError(error as! APIError)
        } catch {
            errorMessage = (error as? APIError).map { e in
                if case .backend(let b) = e { return b.error.message }
                return String(describing: e)
            } ?? error.localizedDescription
        }
    }

    func linkMockAccount() async {
        addSheetError = nil
        isLinking = true
        defer { isLinking = false }
        struct Body: Encodable {
            let provider: String
            let name: String
            let type: String
        }
        do {
            let _: Account = try await client.request(
                path: "/accounts/mock-link",
                method: "POST",
                body: Body(provider: selectedProvider, name: accountName.isEmpty ? "Account" : accountName, type: selectedType)
            )
            await load()
        } catch APIError.httpStatus(409, _), APIError.backend(let be) where be.error.code == "CONFLICT" || be.error.message.lowercased().contains("already") {
            addSheetError = "Account already linked."
        } catch APIError.backend(let be) {
            addSheetError = be.error.message
        } catch APIError.httpStatus(_, let m) {
            addSheetError = m ?? "Could not link account."
        } catch {
            addSheetError = error.localizedDescription
        }
    }

    func resetAddForm() {
        selectedProvider = "MOCK"
        accountName = ""
        selectedType = "CHECKING"
        addSheetError = nil
    }
}
