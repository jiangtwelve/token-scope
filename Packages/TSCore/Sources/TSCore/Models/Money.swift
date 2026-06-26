// Money.swift
//
// 金额值类型。Decimal + ISO 4217 currency code 的组合，是 v0.1 余额场景的领域基石。
// 字段语义对齐 cc-switch UsageData 的 (remaining, unit) 字段，详见 imports/SOURCE_INDEX.md。
//
// 设计选择：
//   - 使用 Decimal 而非 Double：金额计算精度敏感，DeepSeek 等接口偶尔返回字符串
//     如 "38.20"，需精确解析（详见 D-004 测试基线 §"Decoder 表驱动 9 用例"）。
//   - 货币码是字符串而非强类型 enum：v0.1 已知 CNY/USD，但供应商可能扩展未知币种；
//     强类型 enum 会逼着每加一家供应商就改 TSCore，与 KISS 冲突。
//   - 跨币种算术触发 preconditionFailure：金额混合是程序错误，不是用户错误。

import Foundation

/// 一个带币种的金额值。
///
/// `currency` 期望为 ISO 4217 三字母大写代码（如 "CNY"、"USD"），但 Money 本身
/// 不校验——校验责任在数据源解码层（DeepSeekResponseDecoder 等）。
public struct Money: Sendable, Hashable, Codable {
    public let amount: Decimal
    public let currency: String

    public init(amount: Decimal, currency: String) {
        self.amount = amount
        self.currency = currency
    }

    /// 用字符串解析金额。常见于 DeepSeek API 返回 "38.20" 字符串的场景。
    /// 解析失败返回 nil。
    public init?(amountString: String, currency: String) {
        // Decimal(string:) 对前后空格不敏感，但有些 API 返回带换行的字符串，先 trim
        let trimmed = amountString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Decimal(string: trimmed) else { return nil }
        self.amount = amount
        self.currency = currency
    }

    /// 同币种零值。
    public static func zero(currency: String) -> Money {
        Money(amount: 0, currency: currency)
    }
}

// MARK: - Arithmetic (require same currency)

extension Money {
    public static func + (lhs: Money, rhs: Money) -> Money {
        precondition(
            lhs.currency == rhs.currency,
            "Cannot add Money in different currencies: \(lhs.currency) vs \(rhs.currency)"
        )
        return Money(amount: lhs.amount + rhs.amount, currency: lhs.currency)
    }

    public static func - (lhs: Money, rhs: Money) -> Money {
        precondition(
            lhs.currency == rhs.currency,
            "Cannot subtract Money in different currencies: \(lhs.currency) vs \(rhs.currency)"
        )
        return Money(amount: lhs.amount - rhs.amount, currency: lhs.currency)
    }
}

// MARK: - Comparable (require same currency)

extension Money: Comparable {
    public static func < (lhs: Money, rhs: Money) -> Bool {
        precondition(
            lhs.currency == rhs.currency,
            "Cannot compare Money in different currencies: \(lhs.currency) vs \(rhs.currency)"
        )
        return lhs.amount < rhs.amount
    }
}
