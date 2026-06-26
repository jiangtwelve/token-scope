// Account.swift
//
// 用户在某个 Provider 下的一组凭据：baseURL + apiKey + label + 阈值。
//
// 重要：apiKey **不在本结构里**。Account 是可序列化的"账号档案"，存 GRDB；
// apiKey 存 macOS Keychain，通过 `id` 关联两边。详见 D-006 与 ARCHITECTURE.md §Data model。

import Foundation

public struct Account: Sendable, Hashable, Codable, Identifiable {
    /// UUID 主键。Keychain 中的 apiKey 也用这个 id 关联。
    public let id: UUID

    /// 关联到 Provider 的稳定 id（如 "deepseek"）。
    public let providerID: String

    /// 用户起的名字，如"主账号" / "公司号"。允许重名。
    public var label: String

    /// 用户填的 baseURL；默认值来自 Provider.defaultBaseURL，但可被用户覆盖
    /// （用于自部署网关 / 反向代理场景）。
    public var baseURL: String

    /// 低余额告警阈值。用 Money 而非裸 Decimal 是为了带币种语义——
    /// 不同币种账号的阈值不能直接比较。
    public var threshold: Money

    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        providerID: String,
        label: String,
        baseURL: String,
        threshold: Money,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.providerID = providerID
        self.label = label
        self.baseURL = baseURL
        self.threshold = threshold
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
