// ProviderListView.swift
//
// M2 主界面：账号列表、空状态、新增账号、刷新全部。

import SwiftUI
import TSCore

struct ProviderListView: View {
    @State var viewModel: AccountListViewModel
    @State private var editorInput: AccountEditorInput?
    @State private var accountPendingDeletion: AccountListViewModel.AccountRow?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            if let warning = viewModel.databaseWarning {
                warningBanner(warning)
            }

            if viewModel.rows.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.rows) { row in
                            ProviderAccountCard(
                                row: row,
                                onRefresh: { Task { await viewModel.refreshAccount(id: row.id) } },
                                onEdit: {
                                    if let input = viewModel.makeEditorInput(for: row.account) {
                                        editorInput = input
                                    }
                                },
                                onDelete: { accountPendingDeletion = row }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 720, minHeight: 520)
        .task { await viewModel.load() }
        .sheet(item: $editorInput) { input in
            ProviderEditorView(input: input) { updated in
                await viewModel.saveAccount(input: updated)
            }
        }
        .alert("Token Scope", isPresented: alertBinding) {
            Button("好") { viewModel.clearAlert() }
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
        .confirmationDialog(
            "删除账号？",
            isPresented: Binding(
                get: { accountPendingDeletion != nil },
                set: { if !$0 { accountPendingDeletion = nil } }
            )
        ) {
            Button("删除", role: .destructive) {
                guard let row = accountPendingDeletion else { return }
                Task { await viewModel.deleteAccount(id: row.id) }
                accountPendingDeletion = nil
            }
            Button("取消", role: .cancel) { accountPendingDeletion = nil }
        } message: {
            Text(accountPendingDeletion?.account.label ?? "")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Token Scope")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("DeepSeek 余额监控 · v0.1")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task { await viewModel.refreshAll() }
            } label: {
                Label(viewModel.isRefreshingAll ? "刷新中" : "全部刷新", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.rows.isEmpty || viewModel.isRefreshingAll)

            Button {
                editorInput = .empty()
            } label: {
                Label("新增账号", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "key.horizontal")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text("还没有账号")
                .font(.title3.bold())
            Text("添加 DeepSeek API Key 后，点击刷新即可看到余额。")
                .foregroundStyle(.secondary)
            Button {
                editorInput = .empty()
            } label: {
                Label("添加 DeepSeek 账号", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.alertMessage != nil },
            set: { if !$0 { viewModel.clearAlert() } }
        )
    }

    private func warningBanner(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(text)
                .font(.caption)
            Spacer()
        }
        .foregroundStyle(.orange)
        .padding(12)
        .background(.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension AccountEditorInput: Identifiable {}
