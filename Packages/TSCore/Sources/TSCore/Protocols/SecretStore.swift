// SecretStore.swift
//
// 敏感凭据存取接口。v0.1 唯一实现是 TSStorage.KeychainSecretStore（macOS Keychain）。
//
// 边界约定：
//   - apiKey 任何情况下不经过 SnapshotStore；它们走 SecretStore。
//   - v0.1 主 App M1 阶段暂不调用 SecretStore（用 env 变量取 apiKey）；
//     M2 加账号 UI 后接入。但接口 + 实现 + 单测必须在 M1 就到位（D-006 一致）。

import Foundation

public protocol SecretStore: Sendable {
    /// 保存 apiKey。若 accountID 已存在则覆盖。
    func saveAPIKey(_ key: String, forAccount accountID: UUID) throws

    /// 读取 apiKey；不存在返回 nil。
    func loadAPIKey(forAccount accountID: UUID) throws -> String?

    /// 删除 apiKey。不存在视为 no-op（不抛错）。
    func deleteAPIKey(forAccount accountID: UUID) throws
}
