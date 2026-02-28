import Foundation

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var selectedMonth: Date
    @Published var accountId: String?
    @Published var statusFilter: TransactionStatusFilter = .all
    @Published var searchText = ""
    @Published var includeExcluded = true
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var nextCursor: String?
    @Published var isLoading = false
    @Published var loadingMore = false
    @Published var errorMessage: String?

    private let client = APIClient.shared
    private let sessionStore: SessionStore

    enum TransactionStatusFilter: String, CaseIterable {
        case all, pending, posted
    }

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        self.selectedMonth = Calendar.current.startOfMonth(for: Date())
    }

    func loadAccounts() async {
        do {
            let list: [Account] = try await client.request(path: "/accounts")
            accounts = list
        } catch let e as APIError {
            if case .httpStatus(401, _) = e { sessionStore.handleAPIError(e) }
        } catch { /* ignore for accounts */ }
    }

    func load(append: Bool = false) async {
        if append { loadingMore = true } else { isLoading = true }
        errorMessage = nil
        defer {
            if append { loadingMore = false } else { isLoading = false }
        }
        let monthStr = monthString(for: selectedMonth)
        var path = "/transactions?month=\(monthStr)&limit=20"
        if let aid = accountId, !aid.isEmpty { path += "&accountId=\(aid)" }
        switch statusFilter {
        case .pending: path += "&status=PENDING"
        case .posted: path += "&status=POSTED"
        case .all: break
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            path += "&q=\(searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? searchText)"
        }
        path += "&includeExcluded=\(includeExcluded)"
        if append, let cursor = nextCursor { path += "&cursor=\(cursor)" }
        do {
            let response: TransactionListResponse = try await client.request(path: path)
            if append {
                transactions.append(contentsOf: response.data)
            } else {
                transactions = response.data
            }
            nextCursor = response.nextCursor
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

    func updateTransaction(id: String, categoryId: String?, isExcluded: Bool?) async throws {
        struct PatchBody: Encodable {
            let category_id: String?
            let is_excluded: Bool?
        }
        let _: Transaction = try await client.request(
            path: "/transactions/\(id)",
            method: "PATCH",
            body: PatchBody(category_id: categoryId, is_excluded: isExcluded)
        )
        if let idx = transactions.firstIndex(where: { $0.id == id }) {
            var updated = transactions[idx]
            // We don't have a full updated model from PATCH response shape - reload or patch locally
            await load(append: false)
        }
    }

    private func monthString(for date: Date) -> String {
        let c = Calendar.current
        let y = c.component(.year, from: date)
        let m = c.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }
}
