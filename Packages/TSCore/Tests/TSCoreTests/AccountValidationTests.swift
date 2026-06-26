// AccountValidationTests.swift
//
// 覆盖账号编辑器输入的本地校验边界。

import Testing
@testable import TSCore

@Suite("AccountValidation")
struct AccountValidationTests {

    @Test
    func validDeepSeekInputReturnsNoErrors() {
        let input = AccountValidation.Input(
            label: "DeepSeek 主账号",
            baseURL: Provider.deepSeek.defaultBaseURL,
            apiKey: "sk-test",
            threshold: Money(amount: 10, currency: "CNY")
        )
        #expect(AccountValidation.validate(input).isEmpty)
    }

    @Test
    func emptyLabelReturnsError() {
        let input = AccountValidation.Input(
            label: "  \n",
            baseURL: Provider.deepSeek.defaultBaseURL,
            apiKey: "sk-test",
            threshold: Money(amount: 10, currency: "CNY")
        )
        #expect(AccountValidation.validate(input).contains(.emptyLabel))
    }

    @Test
    func invalidBaseURLReturnsError() {
        let input = AccountValidation.Input(
            label: "DeepSeek",
            baseURL: "not a url",
            apiKey: "sk-test",
            threshold: Money(amount: 10, currency: "CNY")
        )
        #expect(AccountValidation.validate(input).contains(.invalidBaseURL))
    }

    @Test
    func emptyAPIKeyReturnsError() {
        let input = AccountValidation.Input(
            label: "DeepSeek",
            baseURL: Provider.deepSeek.defaultBaseURL,
            apiKey: " \n ",
            threshold: Money(amount: 10, currency: "CNY")
        )
        #expect(AccountValidation.validate(input).contains(.emptyAPIKey))
    }

    @Test
    func negativeThresholdReturnsError() {
        let input = AccountValidation.Input(
            label: "DeepSeek",
            baseURL: Provider.deepSeek.defaultBaseURL,
            apiKey: "sk-test",
            threshold: Money(amount: -1, currency: "CNY")
        )
        #expect(AccountValidation.validate(input).contains(.negativeThreshold))
    }
}
