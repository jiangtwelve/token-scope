// Schema.swift
//
// GRDB 数据库 schema。两个表：accounts + snapshots。
// 详见 .project-governance/ssot/ARCHITECTURE.md §Data model。
//
// Migration 策略：v0.1 只一次 initial migration；v0.2+ 加表加字段时新增 migration。

import Foundation
import GRDB

enum Schema {

    /// 注册所有 migrations。在 GRDBSnapshotStore 初始化时调用。
    static func migrate(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v0_1_initial") { db in
            // accounts
            try db.create(table: "accounts") { t in
                t.column("id", .text).primaryKey()  // UUID stringified
                t.column("providerID", .text).notNull()
                t.column("label", .text).notNull()
                t.column("baseURL", .text).notNull()
                t.column("thresholdAmount", .text).notNull()   // Decimal as string for precision
                t.column("thresholdCurrency", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            // snapshots
            try db.create(table: "snapshots") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("accountID", .text).notNull().indexed()
                t.column("providerID", .text).notNull()
                t.column("fetchedAt", .datetime).notNull().indexed()
                t.column("status", .text).notNull()            // success / failure / invalid
                t.column("planName", .text)
                t.column("remaining", .text)                   // Decimal as string
                t.column("total", .text)
                t.column("used", .text)
                t.column("unit", .text)
                t.column("isValid", .boolean)
                t.column("invalidMessage", .text)
                t.column("errorMessage", .text)
            }
        }
    }
}
