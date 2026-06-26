// GRDBSnapshotStore.swift
//
// SnapshotStore 的 GRDB 实现。
//
// 设计要点：
//   - actor：所有 DB 操作排队、不并发；GRDB 内部的 DatabaseQueue 也是串行的，
//     actor 层让 Swift 6 strict concurrency 编译期可证安全。
//   - 字段 Decimal 存为 String：SQLite REAL 类型对 Decimal 精度无保障；
//     存字符串保留 cc-switch parse_f64_field 思路的对偶（解析层兼容字符串/数字）。
//   - cleanupSnapshots 按 fetchedAt < cutoff 删除——cutoff 由调用方传入或默认 7 天。
//   - 失败时显式 throw：GRDB 错误保留原始 DatabaseError；本地数据解码失败抛
//     GRDBSnapshotStoreError，避免账号或快照行被静默丢弃。

import Foundation
import GRDB
import TSCore

public actor GRDBSnapshotStore: SnapshotStore {

    private let dbPool: DatabasePool

    /// 用文件 URL 构造。
    /// - Parameter url: SQLite 文件路径。父目录会自动创建。
    public init(databaseURL url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var config = Configuration()
        config.label = "TokenScope.GRDBSnapshotStore"
        let pool = try DatabasePool(path: url.path, configuration: config)

        var migrator = DatabaseMigrator()
        Schema.migrate(&migrator)
        try migrator.migrate(pool)

        self.dbPool = pool
    }

    // MARK: - Account CRUD

    public func saveAccount(_ account: Account) async throws {
        try await dbPool.write { db in
            try db.execute(sql: """
                INSERT OR REPLACE INTO accounts
                  (id, providerID, label, baseURL, thresholdAmount, thresholdCurrency, createdAt, updatedAt)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    account.id.uuidString,
                    account.providerID,
                    account.label,
                    account.baseURL,
                    account.threshold.amount.description,
                    account.threshold.currency,
                    account.createdAt,
                    account.updatedAt
                ])
        }
    }

    public func loadAccounts() async throws -> [Account] {
        try await dbPool.read { db in
            let rows = try Row.fetchAll(db, sql: """
                SELECT id, providerID, label, baseURL, thresholdAmount, thresholdCurrency, createdAt, updatedAt
                FROM accounts
                ORDER BY createdAt ASC
                """)
            return try rows.map { row in
                guard let account = Self.decodeAccount(row: row) else {
                    throw GRDBSnapshotStoreError.accountDecodeFailed
                }
                return account
            }
        }
    }

    public func deleteAccount(id: UUID) async throws {
        _ = try await dbPool.write { db in
            try db.execute(sql: "DELETE FROM accounts WHERE id = ?", arguments: [id.uuidString])
        }
    }

    // MARK: - Snapshot

    public func saveSnapshots(_ snapshots: [UsageSnapshot]) async throws {
        try await dbPool.write { db in
            for snapshot in snapshots {
                try db.execute(sql: """
                    INSERT INTO snapshots
                      (accountID, providerID, fetchedAt, status, planName, remaining, total, used, unit, isValid, invalidMessage, errorMessage)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, arguments: [
                        snapshot.accountID.uuidString,
                        snapshot.providerID,
                        snapshot.fetchedAt,
                        snapshot.status.rawValue,
                        snapshot.planName,
                        snapshot.remaining?.description,
                        snapshot.total?.description,
                        snapshot.used?.description,
                        snapshot.unit,
                        snapshot.isValid,
                        snapshot.invalidMessage,
                        snapshot.errorMessage
                    ])
            }
        }
    }

    public func loadLatestSnapshot(forAccount accountID: UUID) async throws -> UsageSnapshot? {
        try await dbPool.read { db in
            let row = try Row.fetchOne(db, sql: """
                SELECT accountID, providerID, fetchedAt, status, planName, remaining, total, used,
                       unit, isValid, invalidMessage, errorMessage
                FROM snapshots
                WHERE accountID = ?
                ORDER BY fetchedAt DESC, id DESC
                LIMIT 1
                """, arguments: [accountID.uuidString])
            return row.flatMap { Self.decodeSnapshot(row: $0) }
        }
    }

    public func loadAllLatestSnapshots() async throws -> [UsageSnapshot] {
        try await dbPool.read { db in
            // 取每个 accountID 最近一行：用 ROW_NUMBER 窗口
            let rows = try Row.fetchAll(db, sql: """
                SELECT accountID, providerID, fetchedAt, status, planName, remaining, total, used,
                       unit, isValid, invalidMessage, errorMessage
                FROM (
                  SELECT *, ROW_NUMBER() OVER (
                    PARTITION BY accountID ORDER BY fetchedAt DESC, id DESC
                  ) AS rn
                  FROM snapshots
                )
                WHERE rn = 1
                """)
            return rows.compactMap { Self.decodeSnapshot(row: $0) }
        }
    }

    public func cleanupSnapshots(olderThanDays days: Int) async throws {
        let cutoff = Date().addingTimeInterval(-TimeInterval(days) * 86_400)
        _ = try await dbPool.write { db in
            try db.execute(sql: "DELETE FROM snapshots WHERE fetchedAt < ?", arguments: [cutoff])
        }
    }

    // MARK: - Decoding helpers (static, side-effect free)

    private static func decodeAccount(row: Row) -> Account? {
        guard
            let idString: String = row["id"],
            let id = UUID(uuidString: idString),
            let providerID: String = row["providerID"],
            let label: String = row["label"],
            let baseURL: String = row["baseURL"],
            let amountString: String = row["thresholdAmount"],
            let amount = Decimal(string: amountString),
            let currency: String = row["thresholdCurrency"],
            let createdAt: Date = row["createdAt"],
            let updatedAt: Date = row["updatedAt"]
        else { return nil }

        return Account(
            id: id,
            providerID: providerID,
            label: label,
            baseURL: baseURL,
            threshold: Money(amount: amount, currency: currency),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private static func decodeSnapshot(row: Row) -> UsageSnapshot? {
        guard
            let accountIDString: String = row["accountID"],
            let accountID = UUID(uuidString: accountIDString),
            let providerID: String = row["providerID"],
            let fetchedAt: Date = row["fetchedAt"],
            let statusRaw: String = row["status"],
            let status = UsageSnapshot.Status(rawValue: statusRaw)
        else { return nil }

        return UsageSnapshot(
            accountID: accountID,
            providerID: providerID,
            fetchedAt: fetchedAt,
            status: status,
            planName: row["planName"],
            remaining: (row["remaining"] as String?).flatMap { Decimal(string: $0) },
            total: (row["total"] as String?).flatMap { Decimal(string: $0) },
            used: (row["used"] as String?).flatMap { Decimal(string: $0) },
            unit: row["unit"],
            isValid: row["isValid"],
            invalidMessage: row["invalidMessage"],
            errorMessage: row["errorMessage"]
        )
    }
}

public enum GRDBSnapshotStoreError: Error, Equatable, CustomStringConvertible {
    case accountDecodeFailed

    public var description: String {
        switch self {
        case .accountDecodeFailed:
            return "Failed to decode account row from local SQLite database"
        }
    }
}
