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
    @Published var plaidLinkToken: String?
    @Published var plaidError: String?

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
        } catch APIError.httpStatus(409, _) {
            addSheetError = "Account already linked."
        } catch APIError.backend(let be) where be.error.code == "CONFLICT" || be.error.message.lowercased().contains("already") {
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

    func startPlaidLink() async {
        plaidError = nil
        plaidLinkToken = nil
        do {
            let token = try await PlaidService.getLinkToken()
            plaidLinkToken = token
        } catch let e as APIError {
            sessionStore.handleAPIError(e)
            if case .httpStatus(401, _) = e { } else {
                switch e {
                case .backend(let b): plaidError = b.error.message
                case .httpStatus(_, let m): plaidError = m ?? "Could not get link token."
                default: plaidError = "Could not get link token."
                }
            }
        } catch {
            plaidError = error.localizedDescription
        }
    }

    func onPlaidSuccess(publicToken: String) {
        plaidLinkToken = nil
        Task {
            isLinking = true
            defer { isLinking = false }
            plaidError = nil
            do {
                _ = try await PlaidService.exchange(publicToken: publicToken)
                await load()
            } catch let e as APIError {
                sessionStore.handleAPIError(e)
                switch e {
                case .backend(let b): plaidError = b.error.message
                case .httpStatus(_, let m): plaidError = m ?? "Could not link account."
                default: plaidError = "Could not link account."
                }
            } catch {
                plaidError = error.localizedDescription
            }
        }
    }

    func onPlaidExit(message: String?) {
        plaidLinkToken = nil
        if let msg = message, !msg.isEmpty {
            plaidError = msg
        }
    }
}
