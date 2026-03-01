import SwiftUI

struct AccountsView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @State private var showAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.accounts.isEmpty {
                    accountsSkeleton
                } else if viewModel.accounts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.accounts) { account in
                                accountCard(account)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Connect Bank (Plaid)") {
                        Task { await viewModel.startPlaidLink() }
                    }
                }
            }
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showAddSheet) {
                addAccountSheet
            }
            .sheet(isPresented: Binding(
                get: { viewModel.plaidLinkToken != nil },
                set: { if !$0 { viewModel.plaidLinkToken = nil } }
            )) {
                if let token = viewModel.plaidLinkToken {
                    PlaidLinkPresenter(
                        linkToken: token,
                        onSuccess: { viewModel.onPlaidSuccess(publicToken: $0) },
                        onExit: { viewModel.onPlaidExit(message: $0) }
                    )
                }
            }
            .overlay(alignment: .top) {
                if let msg = viewModel.plaidError, !msg.isEmpty {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 8)
                        .onTapGesture { viewModel.plaidError = nil }
                }
            }
        }
    }

    private func accountCard(_ account: Account) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(account.provider)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .clipShape(Capsule())
                Spacer()
            }
            Text(account.name)
                .font(.headline)
            Text(account.type)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard.and.123")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No accounts")
                .font(.headline)
            Text("Link your first account to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { showAddSheet = true }) {
                Label("Add account", systemImage: "plus.circle")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var accountsSkeleton: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .systemFill))
                    .frame(height: 88)
            }
        }
        .padding()
        .redacted(reason: .placeholder)
    }

    private var addAccountSheet: some View {
        NavigationStack {
            Form {
                Section("Provider") {
                    Picker("Provider", selection: $viewModel.selectedProvider) {
                        ForEach(AccountsViewModel.providers, id: \.self) { p in
                            Text(p).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Account") {
                    TextField("Name", text: $viewModel.accountName)
                        .textContentType(.username)
                    Picker("Type", selection: $viewModel.selectedType) {
                        ForEach(AccountsViewModel.accountTypes, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                }
                if let msg = viewModel.addSheetError {
                    Section {
                        Text(msg)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Add account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetAddForm()
                        showAddSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Link") {
                        Task {
                            await viewModel.linkMockAccount()
                            if viewModel.addSheetError == nil {
                                viewModel.resetAddForm()
                                showAddSheet = false
                            }
                        }
                    }
                    .disabled(viewModel.isLinking)
                }
            }
            .onDisappear { viewModel.resetAddForm() }
        }
    }
}
