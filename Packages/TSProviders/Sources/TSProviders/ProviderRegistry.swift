// ProviderRegistry.swift
//
// 把 providerID（如 "deepseek"）映射到一个 UsageProvider 实例。
//
// v0.1 只注册一家：DeepSeek。v0.2 加 OpenRouter / SiliconFlow 时改这一处。
//
// 这是个简单的工厂表，**没用单例 + 全局可变状态**——主 App 在启动时手动构造一份
// shared 实例，UseCase 通过闭包注入（详见 RefreshAllAccountsUseCase 的
// providerForID 字段），测试时可以构造独立的 Registry 不污染其他测试。

import Foundation
import TSCore

public struct ProviderRegistry: Sendable {

    private let factories: [String: @Sendable () -> any UsageProvider]

    public init(factories: [String: @Sendable () -> any UsageProvider]) {
        self.factories = factories
    }

    /// v0.1 默认注册表：只含 DeepSeek。
    public static let v0_1Default = ProviderRegistry(factories: [
        DeepSeekProvider.id: { DeepSeekProvider() },
    ])

    /// 按 id 查 provider。返回 nil 表示该 id 未注册。
    public func provider(for id: String) -> (any UsageProvider)? {
        factories[id]?()
    }

    /// 已注册的 id 列表。
    public var registeredIDs: [String] {
        Array(factories.keys).sorted()
    }
}
