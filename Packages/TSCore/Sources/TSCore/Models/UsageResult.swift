// UsageResult.swift
//
// Provider.fetch(...) 的返回类型。三态：
//   - success([UsageSnapshot])：拉到数据（可能是多币种多行）
//   - invalid(message):  401/403 等"账号失效"，UI 标红、停止后续刷新
//   - failure(message):  网络 / 5xx / 解析错误等，UI 保留上次成功快照
//
// 与单态 Result<[UsageSnapshot], Error> 的区别：
//   "账号失效" 与 "网络瞬断" 在 UI 表达上完全不同（红色 vs 灰色 + 上次成功值），
//   值类型层显式区分，UI 层就不用做 if let nsError... 类型判别。
//
// 对齐 cc-switch UsageResult（balance.rs 第 6 行）的三态语义。

import Foundation

public enum UsageResult: Sendable, Hashable {
    case success([UsageSnapshot])
    case invalid(message: String)
    case failure(message: String)
}

extension UsageResult {

    /// 取得 success 状态下的快照数组；其他状态返回 nil。
    public var snapshots: [UsageSnapshot]? {
        if case .success(let s) = self { return s }
        return nil
    }

    /// 取得错误描述（不论 invalid 还是 failure）；success 返回 nil。
    public var errorMessage: String? {
        switch self {
        case .success: return nil
        case .invalid(let m), .failure(let m): return m
        }
    }

    /// 是否属于"账号失效"——UI 标红、停止后续刷新。
    public var isInvalid: Bool {
        if case .invalid = self { return true }
        return false
    }
}
