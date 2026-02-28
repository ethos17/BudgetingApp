import SwiftUI

struct TransactionsView: View {
    @ObservedObject var viewModel: TransactionsViewModel
    @State private var selectedTransaction: Transaction?
    @State private var detailTransaction: Transaction?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filtersSection
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    transactionsSkeleton
                } else if viewModel.transactions.isEmpty {
                    emptyState
                } else {
                    groupedList
                }
            }
            .navigationTitle("Transactions")
            .task {
                await viewModel.loadAccounts()
                await viewModel.load()
            }
            .refreshable { await viewModel.load(append: false) }
            .sheet(item: $detailTransaction) { t in
                TransactionDetailSheet(
                    transaction: t,
                    viewModel: viewModel,
                    onDismiss: {
                        detailTransaction = nil
                        Task { await viewModel.load(append: false) }
                    }
                )
            }
        }
    }

    private var filtersSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                monthPickerButton
                accountPickerButton
            }
            HStack(spacing: 8) {
                Picker("Status", selection: $viewModel.statusFilter) {
                    ForEach(TransactionsViewModel.TransactionStatusFilter.allCases, id: \.self) { s in
                        Text(s.rawValue.capitalized).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                Toggle("Excluded", isOn: $viewModel.includeExcluded)
                    .labelsHidden()
            }
            TextField("Search merchant", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .onChange(of: viewModel.selectedMonth) { _, _ in Task { await viewModel.load(append: false) } }
        .onChange(of: viewModel.accountId) { _, _ in Task { await viewModel.load(append: false) } }
        .onChange(of: viewModel.statusFilter) { _, _ in Task { await viewModel.load(append: false) } }
        .onChange(of: viewModel.includeExcluded) { _, _ in Task { await viewModel.load(append: false) } }
        .onChange(of: viewModel.searchText) { _, _ in
            // Debounce would be nicer; for v1 reload on change
            Task { await viewModel.load(append: false) }
        }
    }

    private var monthPickerButton: some View {
        Menu {
            ForEach(monthsAroundCurrent(), id: \.self) { date in
                Button(monthYearString(date)) {
                    viewModel.selectedMonth = date
                    Task { await viewModel.load(append: false) }
                }
            }
        } label: {
            HStack {
                Text(monthYearString(viewModel.selectedMonth))
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var accountPickerButton: some View {
        Menu {
            Button("All accounts") {
                viewModel.accountId = nil
                Task { await viewModel.load(append: false) }
            }
            ForEach(viewModel.accounts) { a in
                Button(a.name) {
                    viewModel.accountId = a.id
                    Task { await viewModel.load(append: false) }
                }
            }
        } label: {
            HStack {
                Text(viewModel.accountId == nil ? "All accounts" : viewModel.accounts.first(where: { $0.id == viewModel.accountId })?.name ?? "Account")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var groupedList: some View {
        let grouped = Dictionary(grouping: viewModel.transactions) { t -> String in
            guard let d = t.effectiveDate else { return "Other" }
            if Calendar.current.isDateInToday(d) { return "Today" }
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return f.string(from: d)
        }
        let sortedKeys = grouped.keys.sorted { k1, k2 in
            let d1 = grouped[k1]?.first?.effectiveDate ?? .distantPast
            let d2 = grouped[k2]?.first?.effectiveDate ?? .distantPast
            return d1 > d2
        }

        return List {
            ForEach(sortedKeys, id: \.self) { key in
                Section(header: Text(key).font(.caption).foregroundStyle(.secondary)) {
                    ForEach(grouped[key] ?? []) { t in
                        transactionRow(t)
                            .contentShape(Rectangle())
                            .onTapGesture { detailTransaction = t }
                            .swipeActions(edge: .trailing) {
                                Button(t.is_excluded ? "Include" : "Exclude") {
                                    Task {
                                        try? await viewModel.updateTransaction(id: t.id, categoryId: nil, isExcluded: !t.is_excluded)
                                        await viewModel.load(append: false)
                                    }
                                }
                            }
                    }
                }
            }
            if viewModel.nextCursor != nil {
                Section {
                    HStack {
                        Spacer()
                        if viewModel.loadingMore {
                            ProgressView()
                        } else {
                            Button("Load more") {
                                Task { await viewModel.load(append: true) }
                            }
                        }
                        Spacer()
                    }
                    .onAppear { Task { await viewModel.load(append: true) } }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func transactionRow(_ t: Transaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(t.merchant_name)
                    .font(.subheadline.weight(.medium))
                Text(t.category?.name ?? "Uncategorized")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(MoneyFormatter.format(cents: t.amount_cents))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(t.isExpense ? .red : .green)
            if t.status == "PENDING" {
                Text("Pending")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No transactions")
                .font(.headline)
            Text("Adjust filters or try another month.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var transactionsSkeleton: some View {
        List {
            ForEach(0..<8, id: \.self) { _ in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemFill))
                            .frame(width: 120, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(uiColor: .systemFill))
                            .frame(width: 80, height: 10)
                    }
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemFill))
                        .frame(width: 60, height: 14)
                }
                .padding(.vertical, 8)
            }
        }
        .redacted(reason: .placeholder)
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: date)
    }

    private func monthsAroundCurrent() -> [Date] {
        let cal = Calendar.current
        return (-12...12).compactMap { cal.date(byAdding: .month, value: $0, to: Date()) }.map { cal.startOfMonth(for: $0) }.sorted(by: >)
    }
}
