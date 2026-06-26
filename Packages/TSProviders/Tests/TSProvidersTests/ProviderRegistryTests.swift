// ProviderRegistryTests.swift
//
// 简单的注册表覆盖测试。

import Testing
import Foundation
@testable import TSProviders
import TSCore

@Suite("ProviderRegistry")
struct ProviderRegistryTests {

    @Test
    func defaultRegistryContainsDeepSeek() {
        let registry = ProviderRegistry.v0_1Default
        #expect(registry.registeredIDs == ["deepseek"])
        #expect(registry.provider(for: "deepseek") != nil)
    }

    @Test
    func unknownIDReturnsNil() {
        let registry = ProviderRegistry.v0_1Default
        #expect(registry.provider(for: "unknown") == nil)
        #expect(registry.provider(for: "") == nil)
    }

    @Test
    func providerForDeepSeekIsDeepSeekProvider() {
        let registry = ProviderRegistry.v0_1Default
        let provider = registry.provider(for: "deepseek")
        #expect(provider is DeepSeekProvider)
    }
}
