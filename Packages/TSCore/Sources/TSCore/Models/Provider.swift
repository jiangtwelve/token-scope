// Provider.swift
//
// 一个供应商的元数据描述（不可变、值类型）。
//
// 这是"静态供应商定义"——例如 DeepSeek 的 id="deepseek"、默认 baseURL 等。
// 与 Account（用户在该供应商下的具体账号实例）相区分。
//
// v0.1 只注册 DeepSeek，未来加 OpenRouter / SiliconFlow 等只需新增 Provider 实例
// 并由 ProviderRegistry 暴露。详见 ARCHITECTURE.md §Module boundaries。

import Foundation

public struct Provider: Sendable, Hashable, Codable {
    /// 稳定的英文 id，作为外部存储与 Registry 查找的主键。
    /// 与 cc-switch balance.rs 中的供应商命名对齐（如 "deepseek"）。
    public let id: String

    /// 给用户看的中文/英文展示名。
    public let displayName: String

    /// 默认 baseURL（用户可在 Account 层面覆盖）。
    public let defaultBaseURL: String

    public init(id: String, displayName: String, defaultBaseURL: String) {
        self.id = id
        self.displayName = displayName
        self.defaultBaseURL = defaultBaseURL
    }
}

extension Provider {
    /// v0.1 唯一内置供应商：DeepSeek。
    /// 详见 .project-governance/ssot/API_CONTRACT.md §Endpoints §DeepSeek。
    public static let deepSeek = Provider(
        id: "deepseek",
        displayName: "DeepSeek",
        defaultBaseURL: "https://api.deepseek.com"
    )
}
