// KeychainSecretStore.swift
//
// SecretStore 的 macOS Keychain 实现。
//
// 配置选择（详见 D-006）：
//   - **不使用 Access Group**——v0.1 主 App 单进程读写，Widget 不需要 apiKey
//   - service 字符串可定制（生产用 AppGroupConstants.keychainService；测试用隔离的 service）
//   - account = "tokenscope.account.<UUID>.apiKey"
//
// 错误：抛 KeychainError 含 OSStatus，便于诊断。

import Foundation
import Security
import TSCore

public struct KeychainSecretStore: SecretStore, Sendable {

    public let service: String

    public init(service: String) {
        self.service = service
    }

    private func accountKey(for id: UUID) -> String {
        "tokenscope.account.\(id.uuidString).apiKey"
    }

    public func saveAPIKey(_ key: String, forAccount accountID: UUID) throws {
        let acc = accountKey(for: accountID)
        guard let data = key.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // 先尝试 update；如果不存在再 add
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: acc,
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            // 插入新条目
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpected(addStatus)
            }
        default:
            throw KeychainError.unexpected(updateStatus)
        }
    }

    public func loadAPIKey(forAccount accountID: UUID) throws -> String? {
        let acc = accountKey(for: accountID)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: acc,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let str = String(data: data, encoding: .utf8) else {
                throw KeychainError.decodingFailed
            }
            return str
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpected(status)
        }
    }

    public func deleteAPIKey(forAccount accountID: UUID) throws {
        let acc = accountKey(for: accountID)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: acc,
        ]
        let status = SecItemDelete(query as CFDictionary)
        // errSecItemNotFound 视为成功（语义：删后状态 = 不存在）
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpected(status)
        }
    }
}

// MARK: - Errors

public enum KeychainError: Error, Equatable {
    case encodingFailed
    case decodingFailed
    case unexpected(OSStatus)
}

extension KeychainError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .encodingFailed: return "Failed to encode string as UTF-8 data"
        case .decodingFailed: return "Failed to decode Keychain data as UTF-8 string"
        case .unexpected(let status):
            return "Unexpected Keychain status: \(status) (\(SecCopyErrorMessageString(status, nil).map { $0 as String } ?? "unknown"))"
        }
    }
}
