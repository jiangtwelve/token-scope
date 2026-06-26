// DeepSeekResponseDecoderTests.swift
//
// 表驱动测试 6 个 JSON 解析场景。HTTP 状态场景（T-API-4/5/6）在
// DeepSeekProviderTests.swift 用 URLProtocol mock 覆盖。
//
// 用例编号与 .project-governance/ssot/API_CONTRACT.md §Endpoints §Mock data rules 对应。

import Testing
import Foundation
@testable import TSProviders
import TSCore

@Suite("DeepSeekResponseDecoder")
struct DeepSeekResponseDecoderTests {

    // MARK: - 帮助函数

    private func decode(_ json: String) -> UsageResult {
        let data = json.data(using: .utf8)!
        return DeepSeekResponseDecoder.decode(data)
    }

    // MARK: - T-API-1：正常 CNY 单币种返回

    @Test
    func tApi1_normalCNYSingleCurrency() {
        let json = """
        {
          "is_available": true,
          "balance_infos": [
            {
              "currency": "CNY",
              "total_balance": "38.20",
              "granted_balance": "0.00",
              "topped_up_balance": "38.20"
            }
          ]
        }
        """
        let result = decode(json)
        guard let snaps = result.snapshots else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(snaps.count == 1)
        let s = snaps[0]
        #expect(s.planName == "CNY")
        #expect(s.unit == "CNY")
        #expect(s.remaining == Decimal(string: "38.20"))
        #expect(s.isValid == true)
        #expect(s.invalidMessage == nil)
        #expect(s.status == .success)
    }

    // MARK: - T-API-2：多币种返回

    @Test
    func tApi2_multipleCurrencies() {
        let json = """
        {
          "is_available": true,
          "balance_infos": [
            { "currency": "CNY", "total_balance": "100.00" },
            { "currency": "USD", "total_balance": "20.00" }
          ]
        }
        """
        let result = decode(json)
        guard let snaps = result.snapshots else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(snaps.count == 2)
        let currencies = Set(snaps.compactMap { $0.unit })
        #expect(currencies == ["CNY", "USD"])
        // 数值核对
        let cny = snaps.first { $0.unit == "CNY" }
        let usd = snaps.first { $0.unit == "USD" }
        #expect(cny?.remaining == 100)
        #expect(usd?.remaining == 20)
    }

    // MARK: - T-API-3：is_available=false

    @Test
    func tApi3_insufficientBalance() {
        let json = """
        {
          "is_available": false,
          "balance_infos": [
            { "currency": "CNY", "total_balance": "0.00" }
          ]
        }
        """
        let result = decode(json)
        guard let snaps = result.snapshots else {
            Issue.record("Expected .success (with isValid=false inside), got \(result)")
            return
        }
        #expect(snaps.count == 1)
        let s = snaps[0]
        #expect(s.isValid == false)
        #expect(s.invalidMessage == "Insufficient balance")
        #expect(s.remaining == 0)
        // 注意：is_available=false 不等于 .invalid 状态。.invalid 留给 401/403 网络层。
        // 这里 status 仍是 .success（拉到数据了，只是数据说"额度耗尽"）。
        #expect(s.status == .success)
    }

    // MARK: - T-API-7：JSON 解析错误

    @Test
    func tApi7_invalidJSON_returnsFailure() {
        let result = decode("not a json {")
        if case .failure(let msg) = result {
            #expect(msg.contains("Failed to parse"))
        } else {
            Issue.record("Expected .failure for invalid JSON, got \(result)")
        }
    }

    @Test
    func tApi7_emptyBody_returnsFailure() {
        let result = decode("")
        if case .failure = result {
            // expected
        } else {
            Issue.record("Expected .failure for empty body, got \(result)")
        }
    }

    // MARK: - T-API-8：total_balance 为字符串而非数字（两种都要兼容）

    @Test
    func tApi8_totalBalanceAsString() {
        let json = """
        {
          "is_available": true,
          "balance_infos": [
            { "currency": "CNY", "total_balance": "12.34" }
          ]
        }
        """
        let snaps = decode(json).snapshots ?? []
        #expect(snaps.first?.remaining == Decimal(string: "12.34"))
    }

    @Test
    func tApi8_totalBalanceAsNumber() {
        let json = """
        {
          "is_available": true,
          "balance_infos": [
            { "currency": "CNY", "total_balance": 56.78 }
          ]
        }
        """
        let snaps = decode(json).snapshots ?? []
        // Decimal 从 Double 转换可能有精度噪声，用 description 对比
        let r = snaps.first?.remaining
        #expect(r != nil)
        #expect(r?.description.hasPrefix("56.78") == true)
    }

    // MARK: - T-API-9：空 balance_infos

    @Test
    func tApi9_emptyBalanceInfos_returnsSuccessWithNoSnapshots() {
        let json = """
        {
          "is_available": true,
          "balance_infos": []
        }
        """
        let result = decode(json)
        guard let snaps = result.snapshots else {
            Issue.record("Expected .success, got \(result)")
            return
        }
        #expect(snaps.isEmpty)
    }

    @Test
    func tApi9_missingBalanceInfos_returnsSuccessWithNoSnapshots() {
        // is_available 在但 balance_infos 字段完全缺失
        let json = """
        { "is_available": true }
        """
        let result = decode(json)
        #expect(result.snapshots?.isEmpty == true)
    }
}
