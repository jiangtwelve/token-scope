# D-003: GRDB 7 + Swift 6 strict concurrency=complete

- ID: D-003
- Date: 2026-06-24
- Title: GRDB 7 + Swift 6 strict concurrency=complete
- Area: Concurrency / Persistence
- Status: accepted
- Related SSOT: `ssot/ARCHITECTURE.md §Tech stack`

## Context

GRDB 版本与 Swift 并发模式绑定决策：

- GRDB 7.x 才有原生 async/await 与 observation v2，与 Swift 6 严格并发的 `Sendable` 标注最匹配
- Swift 6 严格并发（strict concurrency = complete）能在编译期捕获 data race，但需要为所有协议/类型显式声明 `Sendable`
- v0.1 时点上承担一次性的严格并发改造成本，v1 上 App Store 时不需要重构

跨进程读写场景（Widget Extension 读、主 App 写）正是严格并发能预防 bug 的高发区。

## Options

- A. **GRDB 7 + Swift 6 strict concurrency=complete** ← chosen
- B. GRDB 7 + Swift 5 minimal（折中）
- C. GRDB 6 + Swift 5（最保守，但要补 async 包装层）

## Chosen

A。

- GRDB.swift 锁版本 ≥ 7.0.0，<8.0.0
- Swift Language Version = 6.0
- Strict Concurrency Checking = Complete（targets 与 SPM Package.swift 双管齐下）

## Impact

- `UsageProvider` / `SnapshotStore` / `SecretStore` 全部声明 `Sendable`
- `UsageSnapshot` / `UsageResult` / `Account` / `Money` 全部声明 `Sendable`（已在 ARCHITECTURE 标记）
- `GRDBSnapshotStore` 设计为 `actor`，跨进程访问通过 GRDB 的 `DatabaseQueue` 隔离
- SwiftUI 主线程访问标注 `@MainActor`，避免 actor 间桥接漏洞
- M0_skeleton_bootstrap 的 typical_pitfalls 已点名"严格并发警告"

## Follow-ups

- M1 期间若出现 GRDB API 与 Swift 6 编译冲突的 case，记录到本决策的 Revisions 中或新开决策
- 若严格并发实际让 M1 拖延超过 1 天，重新评估是否降级 minimal 模式
