// AccountValidation.swift
//
// 账号表单本地校验。只做同步校验，不联网、不触碰 Keychain。

import Foundation

public enum AccountValidation {
    public struct Input: Sendable, Equatable {
        public let label: String
        public let baseURL: String
        public let apiKey: String
        public let threshold: Money

        public init(label: String, baseURL: String, apiKey: String, threshold: Money) {
            self.label = label
            self.baseURL = baseURL
            self.apiKey = apiKey
            self.threshold = threshold
        }
    }

    public enum Error: Sendable, Equatable, CustomStringConvertible {
        case emptyLabel
        case invalidBaseURL
        case emptyAPIKey
        case negativeThreshold

        public var description: String {
            switch self {
            case .emptyLabel:
                return "账号名称不能为空"
            case .invalidBaseURL:
                return "Base URL 必须是合法的 http(s) URL"
            case .emptyAPIKey:
                return "API Key 不能为空"
            case .negativeThreshold:
                return "低余额阈值不能小于 0"
            }
        }
    }

    /// 校验账号编辑器输入。返回所有错误，便于 UI 一次性展示第一条或完整列表。
    public static func validate(_ input: Input) -> [Error] {
        var errors: [Error] = []
        if input.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyLabel)
        }
        if !isValidBaseURL(input.baseURL) {
            errors.append(.invalidBaseURL)
        }
        if input.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyAPIKey)
        }
        if input.threshold.amount < 0 {
            errors.append(.negativeThreshold)
        }
        return errors
    }

    /// 判断 baseURL 是否是有 host 的 http(s) URL。
    public static func isValidBaseURL(_ value: String) -> Bool {
        guard let url = URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host?.isEmpty == false
        else { return false }
        return true
    }
}
