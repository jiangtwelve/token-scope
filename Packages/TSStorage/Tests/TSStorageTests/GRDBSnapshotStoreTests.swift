// GRDBSnapshotStoreTests.swift
//
// Smoke 测试：每个测试在临时目录新建独立 sqlite，避免污染。
// 验证三件关键事：
//   1. save + loadLatest round-trip
//   2. cleanupSnapshots 按 fetchedAt 删旧
//   3. 空库 loadLatest 返回 nil；账号 CRUD 走通

import Testing
import Foundation
import GRDB
@testable import TSStorage
import TSCore

@Suite("GRDBSnapshotStore")
struct GRDBSnapshotStoreTests {

    private func makeTempStore(file: String = #file, line: Int = #line) async throws -> (GRDBSnapshotStore, URL) {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenScope-Tests-\(UUID().uuidString)")
        let dbURL = tempDir.appendingPathComponent("test.sqlite")
        let store = try GRDBSnapshotStore(databaseURL: dbURL)
        return (store, tempDir)
    }

    private func cleanup(_ tempDir: URL) {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func makeAccount() -> Account {
        Account(
            id: UUID(),
            providerID: "deepseek",
            label: "primary",
            baseURL: "https://api.deepseek.com",
            threshold: Money(amount: 10, currency: "CNY"),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
    }

    private func makeSnapshot(accountID: UUID, fetchedAt: Date, remaining: Decimal = 38.20) -> UsageSnapshot {
        UsageSnapshot(
            accountID: accountID,
            providerID: "deepseek",
            fetchedAt: fetchedAt,
            status: .success,
            planName: "CNY",
            remaining: remaining,
            unit: "CNY",
            isValid: true
        )
    }

    // MARK: - 1. write → loadLatest round-trip

    @Test
    func writeLoadRoundTrip() async throws {
        let (store, tmp) = try await makeTempStore()
        defer { cleanup(tmp) }

        let account = makeAccount()
        try await store.saveAccount(account)
        let accounts = try await store.loadAccounts()
        #expect(accounts.count == 1)
        #expect(accounts.first?.id == account.id)
        #expect(accounts.first?.threshold.amount == 10)
        #expect(accounts.first?.threshold.currency == "CNY")

        let now = Date(timeIntervalSince1970: 1_700_000_100)
        let snap = makeSnapshot(accountID: account.id, fetchedAt: now)
        try await store.saveSnapshots([snap])

        let latest = try await store.loadLatestSnapshot(forAccount: account.id)
        #expect(latest != nil)
        #expect(latest?.remaining == Decimal(string: "38.20"))
        #expect(latest?.unit == "CNY")
        #expect(latest?.status == .success)
    }

    // MARK: - 2. cleanup 按 fetchedAt 删旧

    @Test
    func cleanupSnapshotsRemovesOlderThanCutoff() async throws {
        let (store, tmp) = try await makeTempStore()
        defer { cleanup(tmp) }

        let account = makeAccount()
        try await store.saveAccount(account)

        // 一条 10 天前的旧快照，一条 1 天前的新快照
        let oldDate = Date().addingTimeInterval(-10 * 86400)
        let recentDate = Date().addingTimeInterval(-86400)
        try await store.saveSnapshots([
            makeSnapshot(accountID: account.id, fetchedAt: oldDate, remaining: 1),
            makeSnapshot(accountID: account.id, fetchedAt: recentDate, remaining: 2),
        ])

        try await store.cleanupSnapshots(olderThanDays: 7)

        // 留下的应该是 recent 那条
        let latest = try await store.loadLatestSnapshot(forAccount: account.id)
        #expect(latest?.remaining == 2)
    }

    // MARK: - 3. 空库行为

    @Test
    func loadLatestOnEmptyDB_returnsNil() async throws {
        let (store, tmp) = try await makeTempStore()
        defer { cleanup(tmp) }

        let latest = try await store.loadLatestSnapshot(forAccount: UUID())
        #expect(latest == nil)
    }

    @Test
    func loadAccountsOnEmptyDB_returnsEmpty() async throws {
        let (store, tmp) = try await makeTempStore()
        defer { cleanup(tmp) }

        let accounts = try await store.loadAccounts()
        #expect(accounts.isEmpty)
    }

    @Test
    func loadAllLatestSnapshots_returnsOnePerAccount() async throws {
        let (store, tmp) = try await makeTempStore()
        defer { cleanup(tmp) }

        let acc1 = makeAccount()
        var acc2 = makeAccount()
        acc2 = Account(id: UUID(), providerID: "deepseek", label: "backup",
                       baseURL: "https://api.deepseek.com",
                       threshold: Money(amount: 20, currency: "CNY"),
                       createdAt: Date(), updatedAt: Date())
        try await store.saveAccount(acc1)
        try await store.saveAccount(acc2)

        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let t1 = Date(timeIntervalSince1970: 1_700_000_100)
        try await store.saveSnapshots([
            makeSnapshot(accountID: acc1.id, fetchedAt: t0, remaining: 5),
            makeSnapshot(accountID: acc1.id, fetchedAt: t1, remaining: 10),  // 更新的
            makeSnapshot(accountID: acc2.id, fetchedAt: t0, remaining: 99),
        ])

        let latest = try await store.loadAllLatestSnapshots()
        #expect(latest.count == 2)
        let acc1Latest = latest.first { $0.accountID == acc1.id }
        let acc2Latest = latest.first { $0.accountID == acc2.id }
        #expect(acc1Latest?.remaining == 10)
        #expect(acc2Latest?.remaining == 99)
    }

    @Test
    func deleteAccount_removesIt() async throws {
        let (store, tmp) = try await makeTempStore()
        defer { cleanup(tmp) }

        let acc = makeAccount()
        try await store.saveAccount(acc)
        #expect(try await store.loadAccounts().count == 1)

        try await store.deleteAccount(id: acc.id)
        #expect(try await store.loadAccounts().isEmpty)
    }

    @Test
    func loadAccountsThrowsWhenRowCannotDecode() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenScope-Tests-\(UUID().uuidString)")
        defer { cleanup(tempDir) }
        let dbURL = tempDir.appendingPathComponent("test.sqlite")
        _ = try GRDBSnapshotStore(databaseURL: dbURL)

        let dbPool = try DatabasePool(path: dbURL.path)
        try await dbPool.write { db in
            try db.execute(sql: """
                INSERT INTO accounts
                  (id, providerID, label, baseURL, thresholdAmount, thresholdCurrency, createdAt, updatedAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    "not-a-uuid",
                    "deepseek",
                    "corrupt",
                    "https://api.deepseek.com",
                    "10",
                    "CNY",
                    Date(timeIntervalSince1970: 0),
                    Date(timeIntervalSince1970: 0)
                ])
        }

        let store = try GRDBSnapshotStore(databaseURL: dbURL)
        do {
            _ = try await store.loadAccounts()
            Issue.record("Expected loadAccounts to throw when an account row cannot decode")
        } catch let error as GRDBSnapshotStoreError {
            #expect(error == .accountDecodeFailed)
        }
    }
}
