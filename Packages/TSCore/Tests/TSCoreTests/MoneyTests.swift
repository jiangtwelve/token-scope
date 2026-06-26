// MoneyTests.swift
//
// Money 单测。覆盖：构造、字符串解析、加减、比较、零值、Codable round-trip。

import Testing
import Foundation
@testable import TSCore

@Suite("Money")
struct MoneyTests {

    // MARK: - 构造与字符串解析

    @Test
    func initFromAmountString_parsesDecimal() {
        let m = Money(amountString: "38.20", currency: "CNY")
        #expect(m != nil)
        #expect(m?.amount == Decimal(string: "38.20"))
        #expect(m?.currency == "CNY")
    }

    @Test
    func initFromAmountString_trimsWhitespaceAndNewlines() {
        let m = Money(amountString: "  100.5\n", currency: "USD")
        #expect(m?.amount == Decimal(string: "100.5"))
    }

    @Test
    func initFromAmountString_returnsNilOnInvalid() {
        #expect(Money(amountString: "abc", currency: "CNY") == nil)
        #expect(Money(amountString: "", currency: "CNY") == nil)
    }

    @Test
    func zeroFactory_returnsZeroWithCurrency() {
        let z = Money.zero(currency: "CNY")
        #expect(z.amount == 0)
        #expect(z.currency == "CNY")
    }

    // MARK: - 同币种算术

    @Test
    func addSameCurrency_sumsAmount() {
        let a = Money(amount: Decimal(string: "10.50")!, currency: "CNY")
        let b = Money(amount: Decimal(string: "5.25")!, currency: "CNY")
        let sum = a + b
        #expect(sum.amount == Decimal(string: "15.75"))
        #expect(sum.currency == "CNY")
    }

    @Test
    func subtractSameCurrency_yieldsDifference() {
        let a = Money(amount: Decimal(string: "10.50")!, currency: "USD")
        let b = Money(amount: Decimal(string: "3.50")!, currency: "USD")
        let diff = a - b
        #expect(diff.amount == Decimal(string: "7.00"))
        #expect(diff.currency == "USD")
    }

    // MARK: - 比较

    @Test
    func comparable_smallerLessThanLarger() {
        let small = Money(amount: 5, currency: "CNY")
        let large = Money(amount: 100, currency: "CNY")
        #expect(small < large)
        #expect(!(large < small))
        #expect(!(small < small))
    }

    @Test
    func equality_sameAmountSameCurrency() {
        let a = Money(amount: 10, currency: "CNY")
        let b = Money(amount: 10, currency: "CNY")
        #expect(a == b)
    }

    @Test
    func equality_differentCurrencyNotEqual() {
        // 不同币种但同金额：不相等（Hashable/Equatable 字段对比，currency 不同即不等）
        let a = Money(amount: 10, currency: "CNY")
        let b = Money(amount: 10, currency: "USD")
        #expect(a != b)
    }

    // MARK: - Codable

    @Test
    func codable_roundTripsPreservesValues() throws {
        let original = Money(amount: Decimal(string: "123.45")!, currency: "CNY")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Money.self, from: data)
        #expect(decoded == original)
    }
}
