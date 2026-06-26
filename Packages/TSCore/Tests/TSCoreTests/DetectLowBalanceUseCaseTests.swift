// DetectLowBalanceUseCaseTests.swift
//
// 覆盖 5 条 Decision 分支 + 边界。

import Testing
import Foundation
@testable import TSCore

@Suite("DetectLowBalanceUseCase")
struct DetectLowBalanceUseCaseTests {

    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeAccount(thresholdAmount: Decimal, currency: String = "CNY") -> Account {
        Account(
            id: UUID(),
            providerID: "deepseek",
            label: "test",
            baseURL: "https://api.deepseek.com",
            threshold: Money(amount: thresholdAmount, currency: currency),
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func makeSuccessSnapshot(
        remaining: Decimal,
        unit: String = "CNY",
        accountID: UUID = UUID()
    ) -> UsageSnapshot {
        UsageSnapshot(
            accountID: accountID,
            providerID: "deepseek",
            fetchedAt: Date(timeIntervalSince1970: 1_700_000_000),
            status: .success,
            planName: unit,
            remaining: remaining,
            unit: unit,
            isValid: true
        )
    }

    // MARK: - alert / 不告警

    @Test
    func belowThreshold_noPriorAlert_yieldsAlert() {
        let acc = makeAccount(thresholdAmount: 10)
        let snap = makeSuccessSnapshot(remaining: 5, accountID: acc.id)
        let useCase = DetectLowBalanceUseCase()

        let decision = useCase.detect(snapshot: snap, account: acc, lastAlertedAt: nil, now: now)

        if case .alert(let remaining, let threshold) = decision {
            #expect(remaining.amount == 5)
            #expect(threshold.amount == 10)
        } else {
            Issue.record("Expected .alert, got \(decision)")
        }
    }

    @Test
    func belowThreshold_recentAlert_yieldsDebounced() {
        let acc = makeAccount(thresholdAmount: 10)
        let snap = makeSuccessSnapshot(remaining: 5, accountID: acc.id)
        let useCase = DetectLowBalanceUseCase()

        // 上次告警 1 小时前
        let oneHourAgo = now.addingTimeInterval(-60 * 60)
        let decision = useCase.detect(
            snapshot: snap, account: acc, lastAlertedAt: oneHourAgo, now: now
        )

        if case .belowThresholdButDebounced(_, let last) = decision {
            #expect(last == oneHourAgo)
        } else {
            Issue.record("Expected .belowThresholdButDebounced, got \(decision)")
        }
    }

    @Test
    func belowThreshold_alertOlderThanDebounce_yieldsAlert() {
        let acc = makeAccount(thresholdAmount: 10)
        let snap = makeSuccessSnapshot(remaining: 5, accountID: acc.id)
        let useCase = DetectLowBalanceUseCase()

        // 上次告警 25 小时前
        let twentyFiveHoursAgo = now.addingTimeInterval(-25 * 60 * 60)
        let decision = useCase.detect(
            snapshot: snap, account: acc, lastAlertedAt: twentyFiveHoursAgo, now: now
        )

        guard case .alert = decision else {
            Issue.record("Expected .alert after debounce window, got \(decision)")
            return
        }
    }

    @Test
    func aboveThreshold_returnsAboveThreshold() {
        let acc = makeAccount(thresholdAmount: 10)
        let snap = makeSuccessSnapshot(remaining: 20, accountID: acc.id)
        let useCase = DetectLowBalanceUseCase()

        let decision = useCase.detect(snapshot: snap, account: acc, lastAlertedAt: nil, now: now)

        if case .aboveThreshold(let remaining) = decision {
            #expect(remaining.amount == 20)
        } else {
            Issue.record("Expected .aboveThreshold, got \(decision)")
        }
    }

    // MARK: - skip 分支

    @Test
    func invalidStatus_skipsWithReason() {
        let acc = makeAccount(thresholdAmount: 10)
        let snap = UsageSnapshot(
            accountID: acc.id,
            providerID: "deepseek",
            fetchedAt: now,
            status: .invalid,
            isValid: false,
            invalidMessage: "401"
        )
        let useCase = DetectLowBalanceUseCase()

        let decision = useCase.detect(snapshot: snap, account: acc, lastAlertedAt: nil, now: now)

        if case .skip(let reason) = decision {
            #expect(reason.contains("status"))
        } else {
            Issue.record("Expected .skip for invalid status, got \(decision)")
        }
    }

    @Test
    func missingRemaining_skipsWithReason() {
        let acc = makeAccount(thresholdAmount: 10)
        let snap = UsageSnapshot(
            accountID: acc.id,
            providerID: "deepseek",
            fetchedAt: now,
            status: .success,
            remaining: nil,  // 缺失
            unit: nil
        )
        let useCase = DetectLowBalanceUseCase()

        let decision = useCase.detect(snapshot: snap, account: acc, lastAlertedAt: nil, now: now)

        if case .skip(let reason) = decision {
            #expect(reason.contains("missing"))
        } else {
            Issue.record("Expected .skip for missing remaining, got \(decision)")
        }
    }

    @Test
    func currencyMismatch_skipsWithReason() {
        let acc = makeAccount(thresholdAmount: 10, currency: "CNY")
        let snap = makeSuccessSnapshot(remaining: 5, unit: "USD", accountID: acc.id)
        let useCase = DetectLowBalanceUseCase()

        let decision = useCase.detect(snapshot: snap, account: acc, lastAlertedAt: nil, now: now)

        if case .skip(let reason) = decision {
            #expect(reason.contains("currency mismatch"))
        } else {
            Issue.record("Expected .skip for currency mismatch, got \(decision)")
        }
    }

    // MARK: - 边界

    @Test
    func remainingEqualsThreshold_isNotBelow() {
        // 边界：余额恰好 == 阈值，不触发告警（< 严格小于）
        let acc = makeAccount(thresholdAmount: 10)
        let snap = makeSuccessSnapshot(remaining: 10, accountID: acc.id)
        let useCase = DetectLowBalanceUseCase()

        let decision = useCase.detect(snapshot: snap, account: acc, lastAlertedAt: nil, now: now)
        guard case .aboveThreshold = decision else {
            Issue.record("Expected .aboveThreshold when remaining == threshold, got \(decision)")
            return
        }
    }
}
