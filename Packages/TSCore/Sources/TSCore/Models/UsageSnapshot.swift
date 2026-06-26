// UsageSnapshot.swift
//
// 一次拉取得到的用量快照。**字段一比一对齐 cc-switch UsageData**（balance.rs 第 6 行），
// 便于 v0.2/v0.3 平移其他供应商时不用想字段名。
//
// cc-switch UsageData 原始定义：
//   pub struct UsageData {
//       pub plan_name: Option<String>,
//       pub remaining: Option<f64>,
//       pub total: Option<f64>,
//       pub used: Option<f64>,
//       pub unit: Option<String>,
//       pub is_valid: Option<bool>,
//       pub invalid_message: Option<String>,
//       pub extra: Option<...>,
//   }
//
// Swift 端调整：
//   - f64 → Decimal（金额精度）
//   - 加上 TS 端独有的"挂载关系"字段：accountID、providerID、fetchedAt、status

import Foundation

public struct UsageSnapshot: Sendable, Hashable, Codable {

    public enum Status: String, Sendable, Hashable, Codable {
        case success
        case failure  // 网络 / HTTP / 解析错误
        case invalid  // 401 / 403 → 账号失效
    }

    public let accountID: UUID
    public let providerID: String
    public let fetchedAt: Date
    public let status: Status

    // —— 对齐 cc-switch UsageData ——
    public let planName: String?
    public let remaining: Decimal?
    public let total: Decimal?
    public let used: Decimal?
    public let unit: String?
    public let isValid: Bool?
    public let invalidMessage: String?

    // —— failure 状态附带的错误描述 ——
    public let errorMessage: String?

    public init(
        accountID: UUID,
        providerID: String,
        fetchedAt: Date,
        status: Status,
        planName: String? = nil,
        remaining: Decimal? = nil,
        total: Decimal? = nil,
        used: Decimal? = nil,
        unit: String? = nil,
        isValid: Bool? = nil,
        invalidMessage: String? = nil,
        errorMessage: String? = nil
    ) {
        self.accountID = accountID
        self.providerID = providerID
        self.fetchedAt = fetchedAt
        self.status = status
        self.planName = planName
        self.remaining = remaining
        self.total = total
        self.used = used
        self.unit = unit
        self.isValid = isValid
        self.invalidMessage = invalidMessage
        self.errorMessage = errorMessage
    }
}

// MARK: - 便捷视图

extension UsageSnapshot {
    /// 如果 remaining + unit 都存在，构造 Money 表示。
    /// 主要给 UI 与 DetectLowBalanceUseCase 用。
    public var remainingMoney: Money? {
        guard let remaining, let unit else { return nil }
        return Money(amount: remaining, currency: unit)
    }
}
