// KeychainSecretStoreTests.swift
//
// Smoke 测试 KeychainSecretStore。
//
// **隔离策略**：每个测试用独立的 service 字符串（含 UUID），跑完 cleanup 删除所有
// 该 service 下的条目；这样不会污染开发者本机 Keychain 的真实 token-scope 凭据。

import Testing
import Foundation
@testable import TSStorage
import TSCore

@Suite("KeychainSecretStore")
struct KeychainSecretStoreTests {

    private func makeIsolatedStore() -> KeychainSecretStore {
        // 用一个绝不会与生产/真实凭据冲突的 service prefix
        KeychainSecretStore(service: "io.tokenscope.test.\(UUID().uuidString)")
    }

    /// 测试后清理某个 service 下所有条目。
    private func deleteAllInService(_ service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - 1. save → load round-trip

    @Test
    func saveAndLoad_returnsSameKey() throws {
        let store = makeIsolatedStore()
        defer { deleteAllInService(store.service) }

        let accountID = UUID()
        try store.saveAPIKey("sk-abc-123", forAccount: accountID)
        let loaded = try store.loadAPIKey(forAccount: accountID)
        #expect(loaded == "sk-abc-123")
    }

    // MARK: - 2. delete → load 返回 nil

    @Test
    func deleteThenLoad_returnsNil() throws {
        let store = makeIsolatedStore()
        defer { deleteAllInService(store.service) }

        let accountID = UUID()
        try store.saveAPIKey("sk-x", forAccount: accountID)
        try store.deleteAPIKey(forAccount: accountID)
        let loaded = try store.loadAPIKey(forAccount: accountID)
        #expect(loaded == nil)
    }

    // MARK: - 3. update 已存在的 key

    @Test
    func saveOverridesExistingKey() throws {
        let store = makeIsolatedStore()
        defer { deleteAllInService(store.service) }

        let accountID = UUID()
        try store.saveAPIKey("sk-old", forAccount: accountID)
        try store.saveAPIKey("sk-new", forAccount: accountID)
        let loaded = try store.loadAPIKey(forAccount: accountID)
        #expect(loaded == "sk-new")
    }

    // MARK: - 边界：删除不存在的 key 不抛错

    @Test
    func deleteNonExistent_isNoOp() {
        let store = makeIsolatedStore()
        defer { deleteAllInService(store.service) }

        #expect(throws: Never.self) {
            try store.deleteAPIKey(forAccount: UUID())
        }
    }

    // MARK: - 边界：未保存时 load 返回 nil

    @Test
    func loadUnsavedKey_returnsNil() throws {
        let store = makeIsolatedStore()
        defer { deleteAllInService(store.service) }

        let loaded = try store.loadAPIKey(forAccount: UUID())
        #expect(loaded == nil)
    }
}
