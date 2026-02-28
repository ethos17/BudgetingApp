import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && !viewModel.saveSuccess {
                    Form {
                        Section {
                            Toggle("Include pending in budget", isOn: $viewModel.includePendingInBudget)
                                .disabled(true)
                            Toggle("Notify on pending", isOn: $viewModel.notifyOnPending)
                                .disabled(true)
                        }
                    }
                    .redacted(reason: .placeholder)
                } else {
                    Form {
                        Section {
                            Toggle("Include pending in budget", isOn: $viewModel.includePendingInBudget)
                                .onChange(of: viewModel.includePendingInBudget) { _, _ in Task { await viewModel.save() } }
                            Toggle("Notify on pending", isOn: $viewModel.notifyOnPending)
                                .onChange(of: viewModel.notifyOnPending) { _, _ in Task { await viewModel.save() } }
                        } footer: {
                            if viewModel.saveSuccess {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Saved")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        if let msg = viewModel.errorMessage {
                            Section {
                                Text(msg)
                                    .foregroundStyle(.red)
                            }
                        }
                        Section {
                            Button(role: .destructive, action: {
                                Task { await viewModel.logout() }
                            }) {
                                Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .task { await viewModel.load() }
        }
    }
}
