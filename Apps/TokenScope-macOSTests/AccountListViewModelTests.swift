// AccountListViewModelTests.swift
//
// M2 App 层 lightweight tests：验证 ViewModel 关键业务路径。

import Testing
import Foundation
import TSCore
import TSProviders
@testable import Token_Scope

final actor AppMockSnapshotStore: SnapshotStore {
    var accounts: [Account] = []
    var snapshots: [UsageSnapshot] = []

    func saveAccount(_ account: Account) async throws {
        accounts.removeAll { $0.id == account.id }
        accounts.append(account)
    }

    func loadAccounts() async throws -> [Account] { accounts }

    func deleteAccount(id: UUID) async throws {
        accounts.removeAll { $0.id == id }
    }

    func saveSnapshots(_ snapshots: [UsageSnapshot]) async throws {
        self.snapshots.append(contentsOf: snapshots)
    }

    func loadLatestSnapshot(forAccount accountID: UUID) async throws -> UsageSnapshot? {
        snapshots
            .filter { $0.accountID == accountID }
            .sorted { $0.fetchedAt > $1.fetchedAt }
            .first
    }

    func loadAllLatestSnapshots() async throws -> [UsageSnapshot] { snapshots }
    func cleanupSnapshots(olderThanDays days: Int) async throws {}
}

final class AppMockSecretStore: SecretStore, @unchecked Sendable {
    var keys: [UUID: String] = [:]

    func saveAPIKey(_ key: String, forAccount accountID: UUID) throws {
        keys[accountID] = key
    }

    func loadAPIKey(forAccount accountID: UUID) throws -> String? {
        keys[accountID]
    }

    func deleteAPIKey(forAccount accountID: UUID) throws {
        keys.removeValue(forKey: accountID)
    }
}

struct AppStubProvider: UsageProvider {
    static let id = DeepSeekProvider.id
    static let displayName = "Stub DeepSeek"
    static let defaultBaseURL = DeepSeekProvider.defaultBaseURL
    static func matches(baseURL: String) -> Bool { true }

    func fetch(baseURL: String, apiKey: String) async -> UsageResult {
        .success([
            UsageSnapshot(
                accountID: UUID(),
                providerID: Self.id,
                fetchedAt: Date(timeIntervalSince1970: 0),
                status: .success,
                remaining: 30.18,
                unit: "CNY",
                isValid: true
            )
        ])
    }
}

@Suite("AccountListViewModel")
@MainActor
struct AccountListViewModelTests {

    @Test
    func saveAccountWritesAccountAndAPIKey() async throws {
        let (viewModel, store, secrets) = makeViewModel()
        let saved = await viewModel.saveAccount(input: .emptyForTests(apiKey: "sk-test"))

        #expect(saved == true)
        #expect(await store.accounts.count == 1)
        let accountID = try #require(await store.accounts.first?.id)
        #expect(secrets.keys[accountID] == "sk-test")
        #expect(viewModel.rows.count == 1)
    }

    @Test
    func deleteAccountRemovesAccountAndAPIKey() async throws {
        let (viewModel, store, secrets) = makeViewModel()
        _ = await viewModel.saveAccount(input: .emptyForTests(apiKey: "sk-test"))
        let accountID = try #require(await store.accounts.first?.id)

        await viewModel.deleteAccount(id: accountID)

        #expect(await store.accounts.isEmpty)
        #expect(secrets.keys[accountID] == nil)
    }

    @Test
    func refreshAccountWritesLatestSnapshot() async throws {
        let (viewModel, store, _) = makeViewModel()
        _ = await viewModel.saveAccount(input: .emptyForTests(apiKey: "sk-test"))
        let accountID = try #require(await store.accounts.first?.id)

        await viewModel.refreshAccount(id: accountID)

        let latest = try await store.loadLatestSnapshot(forAccount: accountID)
        #expect(latest?.remaining == Decimal(string: "30.18"))
        #expect(viewModel.rows.first?.latestSnapshot?.remaining == Decimal(string: "30.18"))
    }

    private func makeViewModel() -> (AccountListViewModel, AppMockSnapshotStore, AppMockSecretStore) {
        let store = AppMockSnapshotStore()
        let secrets = AppMockSecretStore()
        let useCase = RefreshAllAccountsUseCase(
            store: store,
            secrets: secrets,
            providerForID: { _ in AppStubProvider() },
            clock: { Date(timeIntervalSince1970: 1_700_000_000) }
        )
        return (AccountListViewModel(store: store, secrets: secrets, refreshUseCase: useCase), store, secrets)
    }
}

private extension AccountEditorInput {
    static func emptyForTests(apiKey: String) -> AccountEditorInput {
        AccountEditorInput(
            id: nil,
            createdAt: nil,
            label: "DeepSeek 主账号",
            baseURL: DeepSeekProvider.defaultBaseURL,
            apiKey: apiKey,
            thresholdAmount: 10
        )
    }
}
