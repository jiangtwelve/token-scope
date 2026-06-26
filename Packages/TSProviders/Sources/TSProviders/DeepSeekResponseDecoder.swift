// DeepSeekResponseDecoder.swift
//
// 纯函数：把 DeepSeek `/user/balance` 的响应 JSON Data 解码为 UsageResult。
//
// **不处理 HTTP 状态**——HTTP 401/403/5xx 的判定在 DeepSeekProvider 网络层完成，
// Decoder 只看 Body。这样可以独立单测（输入 Data，输出 UsageResult）。
//
// 字段语义对齐 cc-switch balance.rs 的 query_deepseek 函数（参考源，非依赖）。
// 详见 .project-governance/ssot/API_CONTRACT.md §Endpoints §DeepSeek。
//
// 预期入参 JSON 结构：
//   {
//     "is_available": true,
//     "balance_infos": [
//       {
//         "currency": "CNY",
//         "total_balance": "38.20",     // 可能是字符串或数字（兼容两种）
//         "granted_balance": "0.00",
//         "topped_up_balance": "38.20"
//       }
//     ]
//   }

import Foundation
import TSCore

public enum DeepSeekResponseDecoder {

    /// 解码 DeepSeek `/user/balance` 的响应 JSON。
    ///
    /// - Parameter data: HTTP body
    /// - Returns: `.success([snap..])` / `.failure(json 解析失败)`；
    ///            invalid 状态由 Provider 网络层基于 HTTP 401/403 直接产出，不在这里。
    ///            注意：UseCase 会再把 accountID/providerID/fetchedAt 三个上下文字段补齐，
    ///            所以这里返回的 UsageSnapshot 这三字段是占位值。
    public static func decode(_ data: Data) -> UsageResult {
        guard let body = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return .failure(message: "Failed to parse response: invalid JSON")
        }

        // is_available 默认 true（对齐 cc-switch unwrap_or(true)）
        let isAvailable = (body["is_available"] as? Bool) ?? true
        let invalidMessage: String? = isAvailable ? nil : "Insufficient balance"

        // balance_infos 缺失或非数组：当成空数组（不视为错误）
        let infos = (body["balance_infos"] as? [[String: Any]]) ?? []

        let snapshots = infos.map { info -> UsageSnapshot in
            let currency = (info["currency"] as? String) ?? "CNY"
            let total = parseDecimalField(info, key: "total_balance")
            return UsageSnapshot(
                accountID: UUID(),           // 占位，UseCase 会覆盖
                providerID: "deepseek",      // 占位（也将被 UseCase 覆盖以保持一致）
                fetchedAt: Date(timeIntervalSince1970: 0),  // 占位
                status: .success,
                planName: currency,
                remaining: total,
                total: nil,
                used: nil,
                unit: currency,
                isValid: isAvailable,
                invalidMessage: invalidMessage,
                errorMessage: nil
            )
        }

        return .success(snapshots)
    }

    /// 兼容 JSON 中字段是数字或字符串两种情况，对齐 cc-switch parse_f64_field。
    /// 解析失败返回 nil（保留 UsageSnapshot.remaining 的 Optional 语义）。
    static func parseDecimalField(_ obj: [String: Any], key: String) -> Decimal? {
        guard let value = obj[key] else { return nil }
        if let num = value as? NSNumber {
            return num.decimalValue
        }
        if let str = value as? String {
            return Decimal(string: str.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return nil
    }
}
