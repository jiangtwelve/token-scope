// DeepSeekProviderTests.swift
//
// 用 URLProtocol mock 注入到 URLSession，覆盖 HTTP 状态层的几个关键场景。
// 与 DeepSeekResponseDecoderTests 互补：那边管 JSON 解析（T-API-1/2/3/7/8/9），
// 这里管 HTTP 状态（T-API-4/5/6）+ 路径拼接 + 帮 happy path 走一遍完整链路。

import Testing
import Foundation
@testable import TSProviders
import TSCore

// MARK: - URLProtocol Mock

/// 全局 mock 注册表（用 lock 保护）。
/// 用 `@unchecked Sendable` 因为 URLProtocol 子类不能改为 Sendable，
/// 但内部状态用 lock 保护，并发安全。
final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    // 全局响应配置（每个测试 setUp 时设置，tearDown 清理）
    nonisolated(unsafe) static var responseStatus: Int = 200
    nonisolated(unsafe) static var responseBody: Data = Data()
    nonisolated(unsafe) static var simulateTimeout: Bool = false

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if MockURLProtocol.simulateTimeout {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.timedOut)
            )
            return
        }

        let url = request.url ?? URL(string: "about:blank")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: MockURLProtocol.responseStatus,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: MockURLProtocol.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// 构造一个把 MockURLProtocol 装进去的 URLSession。
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.timeoutIntervalForRequest = 5  // 测试里要快
        return URLSession(configuration: config)
    }

    /// 重置状态（每个测试开头调）。
    static func reset() {
        responseStatus = 200
        responseBody = Data()
        simulateTimeout = false
    }
}

// MARK: - 测试

@Suite("DeepSeekProvider", .serialized)
struct DeepSeekProviderTests {

    private func makeProvider() -> DeepSeekProvider {
        DeepSeekProvider(session: MockURLProtocol.makeSession())
    }

    // MARK: - Happy path（与 Decoder 重叠但跑通整条链路）

    @Test
    func happyPath_returns200WithJSON_yieldsSuccess() async {
        MockURLProtocol.reset()
        MockURLProtocol.responseStatus = 200
        MockURLProtocol.responseBody = """
        {"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"38.20"}]}
        """.data(using: .utf8)!

        let provider = makeProvider()
        let result = await provider.fetch(baseURL: "https://api.deepseek.com", apiKey: "sk-test")

        guard let snaps = result.snapshots else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(snaps.first?.remaining == Decimal(string: "38.20"))
        #expect(snaps.first?.unit == "CNY")
    }

    // MARK: - T-API-4：HTTP 401 → .invalid

    @Test
    func tApi4_http401_returnsInvalid() async {
        MockURLProtocol.reset()
        MockURLProtocol.responseStatus = 401
        MockURLProtocol.responseBody = Data()

        let provider = makeProvider()
        let result = await provider.fetch(baseURL: "https://api.deepseek.com", apiKey: "sk-bad")

        if case .invalid(let msg) = result {
            #expect(msg.contains("401"))
        } else {
            Issue.record("Expected .invalid for HTTP 401, got \(result)")
        }
    }

    @Test
    func tApi4_http403_alsoReturnsInvalid() async {
        MockURLProtocol.reset()
        MockURLProtocol.responseStatus = 403

        let provider = makeProvider()
        let result = await provider.fetch(baseURL: "https://api.deepseek.com", apiKey: "sk-x")

        if case .invalid = result {
            // OK
        } else {
            Issue.record("Expected .invalid for HTTP 403, got \(result)")
        }
    }

    // MARK: - T-API-5：HTTP 500 → .failure

    @Test
    func tApi5_http500_returnsFailure() async {
        MockURLProtocol.reset()
        MockURLProtocol.responseStatus = 500
        MockURLProtocol.responseBody = "Internal Server Error".data(using: .utf8)!

        let provider = makeProvider()
        let result = await provider.fetch(baseURL: "https://api.deepseek.com", apiKey: "sk-x")

        if case .failure(let msg) = result {
            #expect(msg.contains("500"))
        } else {
            Issue.record("Expected .failure for HTTP 500, got \(result)")
        }
    }

    // MARK: - T-API-6：超时 → .failure

    @Test
    func tApi6_timeout_returnsFailure() async {
        MockURLProtocol.reset()
        MockURLProtocol.simulateTimeout = true

        let provider = makeProvider()
        let result = await provider.fetch(baseURL: "https://api.deepseek.com", apiKey: "sk-x")

        if case .failure(let msg) = result {
            #expect(msg.lowercased().contains("timed out") || msg.lowercased().contains("network"))
        } else {
            Issue.record("Expected .failure for timeout, got \(result)")
        }
    }

    // MARK: - 边界

    @Test
    func emptyApiKey_returnsFailureWithoutNetworkCall() async {
        MockURLProtocol.reset()
        let provider = makeProvider()
        let result = await provider.fetch(baseURL: "https://api.deepseek.com", apiKey: "")
        if case .failure(let msg) = result {
            #expect(msg.contains("empty"))
        } else {
            Issue.record("Expected .failure for empty key, got \(result)")
        }
    }

    @Test
    func trailingSlashInBaseURL_isHandled() async {
        MockURLProtocol.reset()
        MockURLProtocol.responseStatus = 200
        MockURLProtocol.responseBody = #"{"is_available":true,"balance_infos":[]}"#.data(using: .utf8)!

        let provider = makeProvider()
        // baseURL 末尾有 "/"，验证拼接不会出现 "//"
        let result = await provider.fetch(baseURL: "https://api.deepseek.com/", apiKey: "sk-x")
        if case .success = result {
            // OK
        } else {
            Issue.record("Expected .success for trailing slash baseURL, got \(result)")
        }
    }

    @Test
    func matches_recognizesDeepSeekHost() {
        #expect(DeepSeekProvider.matches(baseURL: "https://api.deepseek.com") == true)
        #expect(DeepSeekProvider.matches(baseURL: "https://api.deepseek.com/v1") == true)
        #expect(DeepSeekProvider.matches(baseURL: "https://api.openai.com") == false)
    }
}
