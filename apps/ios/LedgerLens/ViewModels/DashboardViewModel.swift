import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var selectedMonth: Date
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = APIClient.shared
    private let sessionStore: SessionStore

    var totalSpentCents: Int {
        transactions.filter { $0.amount_cents < 0 }.reduce(0) { $0 + $1.amount_cents }
    }
    var totalIncomeCents: Int {
        transactions.filter { $0.amount_cents > 0 }.reduce(0) { $0 + $1.amount_cents }
    }
    var transactionsCount: Int { transactions.count }
    var excludedCount: Int { transactions.filter(\.is_excluded).count }

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        self.selectedMonth = Calendar.current.startOfMonth(for: Date())
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let monthStr = monthString(for: selectedMonth)
        do {
            let response: TransactionListResponse = try await client.request(
                path: "/transactions?month=\(monthStr)&limit=10"
            )
            transactions = response.data
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

    private func monthString(for date: Date) -> String {
        let c = Calendar.current
        let y = c.component(.year, from: date)
        let m = c.component(.month, from: date)
        return String(format: "%04d-%02d", y, m)
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
