import SwiftUI

struct MainTabView: View {
    @ObservedObject var sessionStore: SessionStore
    @StateObject private var dashboardVM: DashboardViewModel
    @StateObject private var transactionsVM: TransactionsViewModel
    @StateObject private var accountsVM: AccountsViewModel
    @StateObject private var settingsVM: SettingsViewModel

    init(sessionStore: SessionStore) {
        _dashboardVM = StateObject(wrappedValue: DashboardViewModel(sessionStore: sessionStore))
        _transactionsVM = StateObject(wrappedValue: TransactionsViewModel(sessionStore: sessionStore))
        _accountsVM = StateObject(wrappedValue: AccountsViewModel(sessionStore: sessionStore))
        _settingsVM = StateObject(wrappedValue: SettingsViewModel(sessionStore: sessionStore))
    }

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardVM)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }
            TransactionsView(viewModel: transactionsVM)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet")
                }
            AccountsView(viewModel: accountsVM)
                .tabItem {
                    Label("Accounts", systemImage: "creditcard")
                }
            SettingsView(viewModel: settingsVM)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
