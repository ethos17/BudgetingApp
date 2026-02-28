import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var showMonthPicker = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    dashboardSkeleton
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            monthHeader
                            summaryCards
                            recentSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: { showMonthPicker = true }) {
                        HStack(spacing: 4) {
                            Text(monthYearString(viewModel.selectedMonth))
                                .font(.headline)
                            Image(systemName: "chevron.down.circle.fill")
                                .font(.caption)
                        }
                    }
                }
            }
            .sheet(isPresented: $showMonthPicker) {
                monthPickerSheet
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
        }
    }

    private var monthHeader: some View {
        EmptyView()
    }

    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(
                title: "Spent",
                value: MoneyFormatter.format(cents: viewModel.totalSpentCents),
                icon: "arrow.down.circle.fill",
                color: .red
            )
            summaryCard(
                title: "Income",
                value: MoneyFormatter.format(cents: viewModel.totalIncomeCents),
                icon: "arrow.up.circle.fill",
                color: .green
            )
            summaryCard(
                title: "Transactions",
                value: "\(viewModel.transactionsCount)",
                icon: "list.bullet",
                color: .blue
            )
            summaryCard(
                title: "Excluded",
                value: "\(viewModel.excludedCount)",
                icon: "eye.slash",
                color: .secondary
            )
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent transactions")
                .font(.headline)
            if viewModel.transactions.isEmpty {
                emptyRecent
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.transactions) { t in
                        transactionRow(t)
                        if t.id != viewModel.transactions.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
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
        .padding(.vertical, 8)
    }

    private var emptyRecent: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title)
                .foregroundStyle(.tertiary)
            Text("No transactions this month")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dashboardSkeleton: some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(uiColor: .systemFill))
                .frame(height: 36)
                .frame(maxWidth: 120)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .systemFill))
                        .frame(height: 72)
                }
            }
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .systemFill))
                .frame(height: 200)
        }
        .padding()
        .redacted(reason: .placeholder)
    }

    private var monthPickerSheet: some View {
        NavigationStack {
            List {
                ForEach(monthsAroundCurrent(), id: \.self) { date in
                    Button(action: {
                        viewModel.selectedMonth = date
                        showMonthPicker = false
                        Task { await viewModel.load() }
                    }) {
                        Text(monthYearString(date))
                            .fontWeight(Calendar.current.isDate(date, equalTo: viewModel.selectedMonth, toGranularity: .month) ? .semibold : .regular)
                    }
                }
            }
            .navigationTitle("Select month")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func monthsAroundCurrent() -> [Date] {
        let cal = Calendar.current
        var dates: [Date] = []
        for offset in -12...12 {
            if let d = cal.date(byAdding: .month, value: offset, to: Date()) {
                dates.append(cal.startOfMonth(for: d))
            }
        }
        return dates.sorted(by: >)
    }
}
