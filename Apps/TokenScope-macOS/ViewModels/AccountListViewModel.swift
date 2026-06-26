// AccountListViewModel.swift
//
// 主 App 账号列表状态模型：加载账号/快照、保存账号、删除账号、手动刷新。

import Foundation
import Observation
import TSCore
import TSProviders
import TSStorage

@MainActor
@Observable
final class AccountListViewModel {
    struct AccountRow: Identifiable, Equatable {
        let account: Account
        let latestSnapshot: UsageSnapshot?
        let isRefreshing: Bool

        var id: UUID { account.id }
    }

    var rows: [AccountRow] = []
    var alertMessage: String?
    var databaseWarning: String?
    var isRefreshingAll = false

    private let store: any SnapshotStore
    private let secrets: any SecretStore
    private let refreshUseCase: RefreshAllAccountsUseCase

    init(bootstrap: AppBootstrap) {
        self.store = bootstrap.store
        self.secrets = bootstrap.secrets
        self.refreshUseCase = bootstrap.makeRefreshAllAccountsUseCase()
        self.databaseWarning = bootstrap.databaseWarning
    }

    init(store: any SnapshotStore, secrets: any SecretStore, refreshUseCase: RefreshAllAccountsUseCase) {
        self.store = store
        self.secrets = secrets
        self.refreshUseCase = refreshUseCase
    }

    /// 从持久化层加载账号与每个账号的最新快照。
    func load() async {
        do {
            let accounts = try await store.loadAccounts()
            var loadedRows: [AccountRow] = []
            for account in accounts {
                let latest = try await store.loadLatestSnapshot(forAccount: account.id)
                loadedRows.append(AccountRow(account: account, latestSnapshot: latest, isRefreshing: false))
            }
            rows = loadedRows
        } catch {
            alertMessage = "加载账号失败：\(error)"
        }
    }

    /// 为编辑弹窗创建输入模型，并从 Keychain 读取当前 API Key。
    func makeEditorInput(for account: Account) -> AccountEditorInput? {
        do {
            let apiKey = try secrets.loadAPIKey(forAccount: account.id) ?? ""
            return .editing(account: account, apiKey: apiKey)
        } catch {
            alertMessage = "读取 API Key 失败：\(error)"
            return nil
        }
    }

    /// 保存账号档案和 API Key。新账号在 Keychain 失败时回滚账号；编辑账号保留原账号避免误删。
    func saveAccount(input: AccountEditorInput) async -> Bool {
        let validationInput = AccountValidation.Input(
            label: input.label,
            baseURL: input.baseURL,
            apiKey: input.apiKey,
            threshold: Money(amount: input.thresholdAmount, currency: "CNY")
        )
        let errors = AccountValidation.validate(validationInput)
        guard errors.isEmpty else {
            alertMessage = errors.map(\.description).joined(separator: "\n")
            return false
        }

        let now = Date()
        let trimmedLabel = input.label.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBaseURL = input.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let account = Account(
            id: input.id ?? UUID(),
            providerID: DeepSeekProvider.id,
            label: trimmedLabel,
            baseURL: trimmedBaseURL,
            threshold: Money(amount: input.thresholdAmount, currency: "CNY"),
            createdAt: input.createdAt ?? now,
            updatedAt: now
        )

        do {
            try await store.saveAccount(account)
            do {
                try secrets.saveAPIKey(input.apiKey, forAccount: account.id)
            } catch {
                if input.id == nil {
                    try? await store.deleteAccount(id: account.id)
                }
                throw error
            }
            await load()
            return true
        } catch {
            alertMessage = "保存账号失败：\(error)"
            return false
        }
    }

    /// 删除账号档案与对应 Keychain API Key。
    func deleteAccount(id: UUID) async {
        do {
            try await store.deleteAccount(id: id)
            try secrets.deleteAPIKey(forAccount: id)
            await load()
        } catch {
            alertMessage = "删除账号失败：\(error)"
        }
    }

    /// 刷新所有账号，并重新加载列表。
    func refreshAll() async {
        guard !rows.isEmpty else { return }
        isRefreshingAll = true
        let summary = await refreshUseCase.execute(accounts: rows.map(\.account))
        isRefreshingAll = false
        apply(summary: summary)
        await load()
    }

    /// 刷新单个账号，并重新加载列表。
    func refreshAccount(id: UUID) async {
        guard let account = rows.first(where: { $0.id == id })?.account else { return }
        setRefreshing(id: id, isRefreshing: true)
        let summary = await refreshUseCase.execute(accounts: [account])
        setRefreshing(id: id, isRefreshing: false)
        apply(summary: summary)
        await load()
    }

    /// 清空当前 alert。
    func clearAlert() {
        alertMessage = nil
    }

    private func apply(summary: RefreshSummary) {
        if !summary.internalErrors.isEmpty {
            alertMessage = summary.internalErrors
                .sorted(by: { $0.key < $1.key })
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
        }
    }

    private func setRefreshing(id: UUID, isRefreshing: Bool) {
        rows = rows.map { row in
            row.id == id
                ? AccountRow(account: row.account, latestSnapshot: row.latestSnapshot, isRefreshing: isRefreshing)
                : row
        }
    }
}

struct AccountEditorInput: Equatable {
    var id: UUID?
    var createdAt: Date?
    var label: String
    var baseURL: String
    var apiKey: String
    var thresholdAmount: Decimal

    /// 空表单默认填 DeepSeek baseURL 与 10 CNY 阈值。
    static func empty() -> AccountEditorInput {
        AccountEditorInput(
            id: nil,
            createdAt: nil,
            label: "DeepSeek 主账号",
            baseURL: DeepSeekProvider.defaultBaseURL,
            apiKey: "",
            thresholdAmount: 10
        )
    }

    /// 从已有账号创建编辑输入；apiKey 由调用方从 Keychain 读入。
    static func editing(account: Account, apiKey: String) -> AccountEditorInput {
        AccountEditorInput(
            id: account.id,
            createdAt: account.createdAt,
            label: account.label,
            baseURL: account.baseURL,
            apiKey: apiKey,
            thresholdAmount: account.threshold.amount
        )
    }
}
