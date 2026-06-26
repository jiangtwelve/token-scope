// SnapshotStore.swift
//
// 账号 + 用量快照的持久化接口。具体实现是 TSStorage.GRDBSnapshotStore（actor）。
//
// 之所以放在 TSCore 而非 TSStorage：UseCase 与协议在 TSCore，TSStorage 仅是实现。
// 这样 UseCase 测试可以用 mock store 而不引 GRDB。

import Foundation

public protocol SnapshotStore: Sendable {

    // MARK: - Account CRUD

    func saveAccount(_ account: Account) async throws
    func loadAccounts() async throws -> [Account]
    func deleteAccount(id: UUID) async throws

    // MARK: - Snapshot 写入与查询

    /// 批量写入一组快照（同一次刷新可能含多币种）。
    func saveSnapshots(_ snapshots: [UsageSnapshot]) async throws

    /// 取某账号最新快照；从未拉取过返回 nil。
    func loadLatestSnapshot(forAccount accountID: UUID) async throws -> UsageSnapshot?

    /// 取所有账号的最新快照，给主 App / Widget 一次性渲染。
    func loadAllLatestSnapshots() async throws -> [UsageSnapshot]

    // MARK: - 维护

    /// 清理早于 N 天的快照（按 fetchedAt）。
    /// v0.1 默认 7 天，由调用方决定。
    func cleanupSnapshots(olderThanDays days: Int) async throws
}
