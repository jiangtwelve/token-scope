// UsageProvider.swift
//
// 上游用量数据采集的统一接口。所有实际供应商（DeepSeek v0.1；OpenRouter / SiliconFlow
// v0.2；火山方舟 / Kimi / 智谱 v0.3）都实现这个协议。
//
// 设计要点：
//   - Sendable：跨 actor 安全传递（v0.1 严格并发）。
//   - 静态属性（id / displayName / defaultBaseURL）描述供应商本身；实例方法 fetch
//     处理具体账号的一次拉取。
//   - matches(baseURL:) 用于"用户填入一个 baseURL，自动识别这是哪家供应商"——对齐
//     cc-switch balance.rs::detect_provider 模式。
//   - fetch 返回 UsageResult 三态而非 throws：网络错与账号失效语义不同，throws
//     会让上层多走一遍判定，三态更清晰。

import Foundation

public protocol UsageProvider: Sendable {
    /// 稳定的英文 id，与 Provider.id 对齐。
    static var id: String { get }

    /// 用户可见的展示名。
    static var displayName: String { get }

    /// 默认 baseURL。
    static var defaultBaseURL: String { get }

    /// 给定 baseURL，判断是否属于本供应商。对齐 cc-switch detect_provider 子串匹配。
    static func matches(baseURL: String) -> Bool

    /// 拉取一次用量。
    ///
    /// - Parameters:
    ///   - baseURL: Account.baseURL，调用方传入（可能被用户覆盖）
    ///   - apiKey: 调用方从 SecretStore 取出
    /// - Returns: 三态结果。**不抛错**——所有失败都通过 UsageResult.invalid/.failure 表达。
    func fetch(baseURL: String, apiKey: String) async -> UsageResult
}
