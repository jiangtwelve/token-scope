// DetectLowBalanceUseCase.swift
//
// 决定一个账号的最新快照是否应该触发"低余额"告警。
//
// 责任：
//   - 输入 (snapshot, account.threshold, lastAlertedAt, now)，输出一个 Decision
//   - 24h 去抖（PRD F-106）：上次告警 24h 内不重复发
//   - 币种不匹配时 .skip 而非 .alert：阈值是 CNY 但快照是 USD 时，无法直接比较
//
// 去抖状态（lastAlertedAt）由调用方持有——M3 阶段写在 UserDefaults 里（详见 active.md
// M3 typical_pitfalls）。本 UseCase 是纯函数，方便单测。

import Foundation

public struct DetectLowBalanceUseCase: Sendable {

    public init() {}

    /// 默认去抖间隔：24 小时。
    public static let defaultDebounceInterval: TimeInterval = 24 * 60 * 60

    public func detect(
        snapshot: UsageSnapshot,
        account: Account,
        lastAlertedAt: Date?,
        now: Date,
        debounceInterval: TimeInterval = DetectLowBalanceUseCase.defaultDebounceInterval
    ) -> Decision {
        // 1. 快照必须 success——invalid / failure 状态走 UI 自己的失效表达，不走低余额告警路径
        guard snapshot.status == .success else {
            return .skip(reason: "snapshot status is \(snapshot.status), expected success")
        }

        // 2. 必须有 remaining + unit，才能构造 Money 与阈值比较
        guard let remaining = snapshot.remainingMoney else {
            return .skip(reason: "snapshot missing remaining or unit")
        }

        // 3. 币种匹配（v0.1 阈值是 CNY；返回 USD 等其他币种不直接告警）
        guard remaining.currency == account.threshold.currency else {
            return .skip(
                reason: "currency mismatch: snapshot=\(remaining.currency) threshold=\(account.threshold.currency)"
            )
        }

        // 4. 不低于阈值——OK，无需告警
        guard remaining < account.threshold else {
            return .aboveThreshold(remaining: remaining)
        }

        // 5. 低于阈值 → 检查去抖
        if let last = lastAlertedAt, now.timeIntervalSince(last) < debounceInterval {
            return .belowThresholdButDebounced(remaining: remaining, lastAlertedAt: last)
        }

        return .alert(remaining: remaining, threshold: account.threshold)
    }

    public enum Decision: Sendable, Equatable {
        /// 应该发系统通知。调用方负责发完后把 `now` 写入 lastAlertedAt 持久化。
        case alert(remaining: Money, threshold: Money)

        /// 余额确实低于阈值，但 24h 去抖未到期。
        case belowThresholdButDebounced(remaining: Money, lastAlertedAt: Date)

        /// 余额未到阈值线，正常。
        case aboveThreshold(remaining: Money)

        /// 数据不齐 / 状态不符 / 币种不匹配——本 UseCase 不处理。
        case skip(reason: String)
    }
}
