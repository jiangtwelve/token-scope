// DeepSeekProvider.swift
//
// 实现 TSCore.UsageProvider 协议，包装 URLSession 调 DeepSeek `/user/balance`。
// 解码委托给 DeepSeekResponseDecoder。
//
// HTTP 状态映射（详见 .project-governance/ssot/API_CONTRACT.md §Error format）：
//   - 2xx：交给 Decoder 处理 body
//   - 401 / 403：→ .invalid（账号失效）
//   - 其他 4xx / 5xx：→ .failure(API error)
//   - 网络错 / 超时：→ .failure(Network error)

import Foundation
import TSCore

public struct DeepSeekProvider: UsageProvider, Sendable {
    public static let id: String = "deepseek"
    public static let displayName: String = "DeepSeek"
    public static let defaultBaseURL: String = "https://api.deepseek.com"

    public static func matches(baseURL: String) -> Bool {
        baseURL.lowercased().contains("api.deepseek.com")
    }

    /// 注入 URLSession（生产用 .shared；测试用 URLProtocol mock 注入）。
    public let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(baseURL: String, apiKey: String) async -> UsageResult {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(message: "API key is empty")
        }

        // 拼 URL（容忍 baseURL 末尾有/无 "/"）
        var trimmedBase = baseURL
        while trimmedBase.hasSuffix("/") { trimmedBase.removeLast() }
        guard let url = URL(string: "\(trimmedBase)/user/balance") else {
            return .failure(message: "Invalid baseURL: \(baseURL)")
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15  // 对齐 cc-switch balance.rs

        do {
            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse else {
                return .failure(message: "Invalid HTTP response")
            }

            // 401 / 403 → invalid（账号失效）
            if http.statusCode == 401 || http.statusCode == 403 {
                return .invalid(message: "Authentication failed (HTTP \(http.statusCode))")
            }

            // 非 2xx → failure。不要把远端响应体写入 failure message：
            // 未来支持自定义中转站后，错误 body 可能包含敏感调试信息，message 会被持久化。
            guard (200..<300).contains(http.statusCode) else {
                return .failure(message: "API error (HTTP \(http.statusCode))")
            }

            // 2xx → 交给 Decoder
            return DeepSeekResponseDecoder.decode(data)

        } catch let error as URLError where error.code == .timedOut {
            return .failure(message: "Network error: request timed out")
        } catch {
            return .failure(message: "Network error: \(error.localizedDescription)")
        }
    }
}
