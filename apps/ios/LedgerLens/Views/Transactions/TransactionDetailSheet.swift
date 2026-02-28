import SwiftUI

struct TransactionDetailSheet: View {
    let transaction: Transaction
    @ObservedObject var viewModel: TransactionsViewModel
    var onDismiss: () -> Void

    @State private var categories: [Category] = []
    @State private var selectedCategoryId: String?
    @State private var isExcluded: Bool
    @State private var isLoading = true
    @State private var isSaving = false
    @Environment(\.dismiss) private var dismiss

    init(transaction: Transaction, viewModel: TransactionsViewModel, onDismiss: @escaping () -> Void) {
        self.transaction = transaction
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        _selectedCategoryId = State(initialValue: transaction.category?.id)
        _isExcluded = State(initialValue: transaction.is_excluded)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text(transaction.merchant_name)
                            .font(.headline)
                        Spacer()
                        Text(MoneyFormatter.format(cents: transaction.amount_cents))
                            .foregroundStyle(transaction.isExpense ? .red : .green)
                    }
                    Text(transaction.account.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Section("Category") {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Picker("Category", selection: $selectedCategoryId) {
                            Text("Uncategorized").tag(nil as String?)
                            ForEach(categories) { c in
                                Text(c.name).tag(c.id as String?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                Section {
                    Toggle("Excluded from budget", isOn: $isExcluded)
                }
            }
            .navigationTitle("Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
            .task { await loadCategories() }
        }
    }

    private func loadCategories() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let list: [Category] = try await APIClient.shared.request(path: "/categories")
            categories = list
        } catch { }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await viewModel.updateTransaction(
                id: transaction.id,
                categoryId: selectedCategoryId,
                isExcluded: isExcluded
            )
            dismiss()
            onDismiss()
        } catch { }
    }
}
