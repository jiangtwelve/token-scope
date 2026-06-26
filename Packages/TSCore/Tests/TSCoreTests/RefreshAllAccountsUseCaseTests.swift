// RefreshAllAccountsUseCaseTests.swift
//
// 用 mock SnapshotStore / SecretStore / Provider 验证 UseCase 的核心行为。

import Testing
import Foundation
@testable import TSCore

// MARK: - Mock 类型

final actor MockSnapshotStore: SnapshotStore {
    var accounts: [Account]
    var loadAccountsShouldThrow: Error?
    var savedSnapshots: [UsageSnapshot] = []
    var saveShouldThrow: Error?

    init(accounts: [Account] = [], loadAccountsShouldThrow: Error? = nil, saveShouldThrow: Error? = nil) {
        self.accounts = accounts
        self.loadAccountsShouldThrow = loadAccountsShouldThrow
        self.saveShouldThrow = saveShouldThrow
    }

    func saveAccount(_ account: Account) async throws {}
    func loadAccounts() async throws -> [Account] {
        if let e = loadAccountsShouldThrow { throw e }
        return accounts
    }
    func deleteAccount(id: UUID) async throws {}
    func saveSnapshots(_ snapshots: [UsageSnapshot]) async throws {
        if let e = saveShouldThrow { throw e }
        savedSnapshots.append(contentsOf: snapshots)
    }
    func loadLatestSnapshot(forAccount accountID: UUID) async throws -> UsageSnapshot? { nil }
    func loadAllLatestSnapshots() async throws -> [UsageSnapshot] { [] }
    func cleanupSnapshots(olderThanDays days: Int) async throws {}
}

final class MockSecretStore: SecretStore, @unchecked Sendable {
    var keys: [UUID: String] = [:]
    var loadShouldThrow: Error?

    init(keys: [UUID: String] = [:], loadShouldThrow: Error? = nil) {
        self.keys = keys
        self.loadShouldThrow = loadShouldThrow
    }

    func saveAPIKey(_ key: String, forAccount accountID: UUID) throws {
        keys[accountID] = key
    }
    func loadAPIKey(forAccount accountID: UUID) throws -> String? {
        if let e = loadShouldThrow { throw e }
        return keys[accountID]
    }
    func deleteAPIKey(forAccount accountID: UUID) throws {
        keys.removeValue(forKey: accountID)
    }
}

/// 按 apiKey 路由不同结果的 Provider，用于验证同一 providerID 下多账号混合结果。
actor ApiKeyRoutingProvider: UsageProvider {
    static let id: String = "stub"
    static let displayName: String = "Stub"
    static let defaultBaseURL: String = "https://stub.example.com"
    static func matches(baseURL: String) -> Bool { baseURL.contains("stub") }

    let results: [String: UsageResult]
    private var fetchCountValue = 0

    var fetchCount: Int { fetchCountValue }

    init(results: [String: UsageResult]) {
        self.results = results
    }

    func fetch(baseURL: String, apiKey: String) async -> UsageResult {
        fetchCountValue += 1
        return results[apiKey] ?? .failure(message: "No result configured for apiKey")
    }
}

// MARK: - 测试用例

@Suite("RefreshAllAccountsUseCase")
struct RefreshAllAccountsUseCaseTests {

    private func makeAccount(label: String = "test") -> Account {
        Account(
            id: UUID(),
            providerID: "stub",
            label: label,
            baseURL: "https://stub.example.com",
            threshold: Money(amount: 10, currency: "CNY"),
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func makeSuccessResult(currency: String = "CNY", remaining: Decimal = 38.20) -> UsageResult {
        let snap = UsageSnapshot(
            accountID: UUID(),  // 会被 UseCase 覆盖
            providerID: "stub",
            fetchedAt: Date(timeIntervalSince1970: 0),
            status: .success,
            planName: currency,
            remaining: remaining,
            unit: currency,
            isValid: true
        )
        return .success([snap])
    }

    @Test
    func happyPath_twoAccountsBothSucceed() async throws {
        let acc1 = makeAccount(label: "main")
        let acc2 = makeAccount(label: "backup")
        let store = MockSnapshotStore(accounts: [acc1, acc2])
        let secrets = MockSecretStore(keys: [acc1.id: "sk-a", acc2.id: "sk-b"])
        let provider = ApiKeyRoutingProvider(results: [
            "sk-a": makeSuccessResult(),
            "sk-b": makeSuccessResult()
        ])

        let useCase = RefreshAllAccountsUseCase(
            store: store,
            secrets: secrets,
            providerForID: { _ in provider },
            clock: { Date(timeIntervalSince1970: 1_700_000_000) }
        )

        let summary = await useCase.execute()
        #expect(summary.perAccount.count == 2)
        #expect(summary.internalErrors.isEmpty)
        #expect(summary.savedSnapshotCount == 2)
        await #expect(store.savedSnapshots.count == 2)
        // 两次 fetch 都被调用
        #expect(await provider.fetchCount == 2)
        // accountID/providerID/fetchedAt 被补齐到 1_700_000_000
        await #expect(
            store.savedSnapshots.allSatisfy {
                $0.fetchedAt == Date(timeIntervalSince1970: 1_700_000_000)
                    && $0.status == .success
            }
        )
    }

    @Test
    func partialFailure_oneSucceedsOneInvalid() async throws {
        let okAccount = makeAccount(label: "ok")
        let invalidAccount = makeAccount(label: "bad")
        let store = MockSnapshotStore(accounts: [okAccount, invalidAccount])
        let secrets = MockSecretStore(keys: [
            okAccount.id: "sk-ok",
            invalidAccount.id: "sk-invalid"
        ])
        let provider = ApiKeyRoutingProvider(results: [
            "sk-ok": makeSuccessResult(remaining: 38.20),
            "sk-invalid": .invalid(message: "401 unauthorized")
        ])

        let useCase = RefreshAllAccountsUseCase(
            store: store,
            secrets: secrets,
            providerForID: { _ in provider },
            clock: { Date(timeIntervalSince1970: 0) }
        )
        let summary = await useCase.execute()

        #expect(summary.perAccount[okAccount.id]?.snapshots?.first?.remaining == Decimal(string: "38.20"))
        #expect(summary.perAccount[invalidAccount.id]?.isInvalid == true)
        #expect(summary.savedSnapshotCount == 2)
        #expect(summary.internalErrors.isEmpty)

        let savedSnapshots = await store.savedSnapshots
        #expect(savedSnapshots.count == 2)
        #expect(savedSnapshots.contains { $0.accountID == okAccount.id && $0.status == .success })
        #expect(savedSnapshots.contains {
            $0.accountID == invalidAccount.id
                && $0.status == .invalid
                && $0.invalidMessage == "401 unauthorized"
        })
    }

    @Test
    func networkFailure_writesFailureRowKeepsPerAccount() async throws {
        let acc = makeAccount()
        let store = MockSnapshotStore(accounts: [acc])
        let secrets = MockSecretStore(keys: [acc.id: "sk"])
        let provider = ApiKeyRoutingProvider(results: ["sk": .failure(message: "Network error: timeout")])

        let useCase = RefreshAllAccountsUseCase(
            store: store,
            secrets: secrets,
            providerForID: { _ in provider }
        )
        let summary = await useCase.execute()
        #expect(summary.perAccount[acc.id]?.errorMessage?.contains("timeout") == true)
        await #expect(store.savedSnapshots.first?.status == .failure)
    }

    @Test
    func emptyAccounts_returnsEmptySummary() async {
        let store = MockSnapshotStore(accounts: [])
        let secrets = MockSecretStore()
        let provider = ApiKeyRoutingProvider(results: ["sk": makeSuccessResult()])

        let useCase = RefreshAllAccountsUseCase(
            store: store,
            secrets: secrets,
            providerForID: { _ in provider }
        )
        let summary = await useCase.execute()
        #expect(summary.perAccount.isEmpty)
        #expect(summary.savedSnapshotCount == 0)
        #expect(summary.internalErrors.isEmpty)
        #expect(await provider.fetchCount == 0)
    }

    @Test
    func missingApiKey_recordedAsInternalError() async {
        let acc = makeAccount()
        let store = MockSnapshotStore(accounts: [acc])
        let secrets = MockSecretStore()  // 空 keys
        let provider = ApiKeyRoutingProvider(results: ["sk": makeSuccessResult()])

        let useCase = RefreshAllAccountsUseCase(
            store: store,
            secrets: secrets,
            providerForID: { _ in provider }
        )
        let summary = await useCase.execute()
        #expect(summary.perAccount.isEmpty)  // 没 fetch 过
        #expect(summary.internalErrors[acc.id.uuidString]?.contains("Missing apiKey") == true)
        #expect(await provider.fetchCount == 0)
    }

    @Test
    func unknownProvider_recordedAsInternalError() async {
        let acc = makeAccount()
        let store = MockSnapshotStore(accounts: [acc])
        let secrets = MockSecretStore(keys: [acc.id: "sk"])
        let useCase = RefreshAllAccountsUseCase(
            store: store,
            secrets: secrets,
            providerForID: { _ in nil }  // Registry 没有
        )
        let summary = await useCase.execute()
        #expect(summary.perAccount.isEmpty)
        #expect(summary.internalErrors[acc.id.uuidString]?.contains("Unknown provider") == true)
    }
}
