// RefreshAllAccountsUseCase.swift
//
// 把"刷新所有账号"这件事独立为一个可测试的领域 UseCase。
//
// 责任：
//   1. 从 SnapshotStore 拿出所有 Account
//   2. 对每个 Account：查 Provider、查 apiKey、并行 fetch
//   3. 把 success 状态的快照批量写回 SnapshotStore
//   4. 返回一份汇总，供 UI / 日志使用
//
// 设计要点：
//   - 不是 actor。结构体 + 注入依赖，每次 execute 是无状态调用——便于在主 App、
//     菜单栏定时任务、未来的 CLI 工具里复用同一个 UseCase。
//   - Provider 查找通过闭包注入而非 ProviderRegistry 单例：测试时不依赖运行时单例
//     的初始化顺序。生产代码在 App 启动时 wrap registry 的 `provider(for:)`。
//   - clock 注入：测试时可控时间；生产用 `{ Date() }`。
//   - Error 不抛出。store/secrets 的 throw 被吃成内部错误字符串，UseCase 永远完成；
//     这与 UsageResult 三态思路一致——上游错误不该让"刷新"这个动作崩。

import Foundation

public struct RefreshAllAccountsUseCase: Sendable {
    public let store: any SnapshotStore
    public let secrets: any SecretStore
    public let providerForID: @Sendable (String) -> (any UsageProvider)?
    public let clock: @Sendable () -> Date

    public init(
        store: any SnapshotStore,
        secrets: any SecretStore,
        providerForID: @escaping @Sendable (String) -> (any UsageProvider)?,
        clock: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.store = store
        self.secrets = secrets
        self.providerForID = providerForID
        self.clock = clock
    }

    public func execute() async -> RefreshSummary {
        // —— Step 1: 拿所有账号 ——
        let accounts: [Account]
        do {
            accounts = try await store.loadAccounts()
        } catch {
            return RefreshSummary(
                perAccount: [:],
                savedSnapshotCount: 0,
                internalErrors: ["_loadAccounts": "Failed to load accounts: \(error)"]
            )
        }
        return await execute(accounts: accounts)
    }

    public func execute(accounts: [Account]) async -> RefreshSummary {
        guard !accounts.isEmpty else {
            return RefreshSummary(perAccount: [:], savedSnapshotCount: 0, internalErrors: [:])
        }

        // —— Step 2: 并行 fetch 每个账号 ——
        // 用 TaskGroup 避免账号慢拖累整体；returnType 是 (UUID, ResultOrError)
        let perAccountResults = await withTaskGroup(
            of: AccountFetchOutcome.self,
            returning: [AccountFetchOutcome].self
        ) { group in
            for account in accounts {
                group.addTask { await fetchOne(account: account) }
            }
            var collected: [AccountFetchOutcome] = []
            collected.reserveCapacity(accounts.count)
            for await outcome in group {
                collected.append(outcome)
            }
            return collected
        }

        // —— Step 3: 收集结果 ——
        var perAccount: [UUID: UsageResult] = [:]
        var internalErrors: [String: String] = [:]
        var snapshotsToSave: [UsageSnapshot] = []
        let now = clock()

        for outcome in perAccountResults {
            switch outcome.kind {
            case .fetched(let result):
                perAccount[outcome.accountID] = result
                snapshotsToSave.append(
                    contentsOf: snapshots(
                        from: result,
                        accountID: outcome.accountID,
                        providerID: outcome.providerID,
                        fetchedAt: now
                    )
                )
            case .internalError(let message):
                internalErrors[outcome.accountID.uuidString] = message
            }
        }

        // —— Step 4: 批量写入 ——
        var savedCount = 0
        if !snapshotsToSave.isEmpty {
            do {
                try await store.saveSnapshots(snapshotsToSave)
                savedCount = snapshotsToSave.count
            } catch {
                internalErrors["_saveSnapshots"] = "Failed to save snapshots: \(error)"
            }
        }

        return RefreshSummary(
            perAccount: perAccount,
            savedSnapshotCount: savedCount,
            internalErrors: internalErrors
        )
    }

    // MARK: - 私有

    private func fetchOne(account: Account) async -> AccountFetchOutcome {
        // Provider 查找
        guard let provider = providerForID(account.providerID) else {
            return AccountFetchOutcome(
                accountID: account.id,
                providerID: account.providerID,
                kind: .internalError("Unknown provider id: \(account.providerID)")
            )
        }

        // apiKey 查找
        let apiKey: String
        do {
            guard let key = try secrets.loadAPIKey(forAccount: account.id) else {
                return AccountFetchOutcome(
                    accountID: account.id,
                    providerID: account.providerID,
                    kind: .internalError("Missing apiKey for account \(account.id)")
                )
            }
            apiKey = key
        } catch {
            return AccountFetchOutcome(
                accountID: account.id,
                providerID: account.providerID,
                kind: .internalError("Failed to load apiKey: \(error)")
            )
        }

        // 实际拉取
        let result = await provider.fetch(baseURL: account.baseURL, apiKey: apiKey)
        return AccountFetchOutcome(
            accountID: account.id,
            providerID: account.providerID,
            kind: .fetched(result)
        )
    }

    /// 把 Provider 返回的 UsageResult 转成可入库的 UsageSnapshot 行列表。
    /// success 状态可能含多行（多币种）；invalid / failure 各生成一行状态记录。
    private func snapshots(
        from result: UsageResult,
        accountID: UUID,
        providerID: String,
        fetchedAt: Date
    ) -> [UsageSnapshot] {
        switch result {
        case .success(let snaps):
            // Provider 返回的 snapshots 可能未填 accountID/providerID/fetchedAt
            // （Decoder 不知道这些），UseCase 在此补齐。
            return snaps.map { s in
                UsageSnapshot(
                    accountID: accountID,
                    providerID: providerID,
                    fetchedAt: fetchedAt,
                    status: .success,
                    planName: s.planName,
                    remaining: s.remaining,
                    total: s.total,
                    used: s.used,
                    unit: s.unit,
                    isValid: s.isValid,
                    invalidMessage: s.invalidMessage,
                    errorMessage: nil
                )
            }
        case .invalid(let message):
            return [
                UsageSnapshot(
                    accountID: accountID,
                    providerID: providerID,
                    fetchedAt: fetchedAt,
                    status: .invalid,
                    isValid: false,
                    invalidMessage: message
                )
            ]
        case .failure(let message):
            return [
                UsageSnapshot(
                    accountID: accountID,
                    providerID: providerID,
                    fetchedAt: fetchedAt,
                    status: .failure,
                    errorMessage: message
                )
            ]
        }
    }
}

// MARK: - 结果类型

public struct RefreshSummary: Sendable, Equatable {
    /// 每个账号的 fetch 结果。账号 fetch 失败（invalid/failure）也在这里。
    public let perAccount: [UUID: UsageResult]

    /// 实际写入数据库的快照行数（包含 success 多币种行 + invalid/failure 行）。
    public let savedSnapshotCount: Int

    /// UseCase 内部错误：拿不到 Provider、拿不到 apiKey、写库失败等。
    /// key 是 accountID.uuidString，或预定义的 "_loadAccounts" / "_saveSnapshots" 哨兵。
    public let internalErrors: [String: String]

    public init(
        perAccount: [UUID: UsageResult],
        savedSnapshotCount: Int,
        internalErrors: [String: String]
    ) {
        self.perAccount = perAccount
        self.savedSnapshotCount = savedSnapshotCount
        self.internalErrors = internalErrors
    }
}

// MARK: - 内部传值

private struct AccountFetchOutcome: Sendable {
    let accountID: UUID
    let providerID: String
    let kind: Kind

    enum Kind: Sendable {
        case fetched(UsageResult)
        case internalError(String)
    }
}
