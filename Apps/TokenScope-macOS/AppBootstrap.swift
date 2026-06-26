// AppBootstrap.swift
//
// App 层组合根：集中创建存储、Keychain、Provider registry 与 UseCase。

import Foundation
import TSCore
import TSProviders
import TSStorage

struct AppBootstrap {
    let store: GRDBSnapshotStore
    let secrets: KeychainSecretStore
    let registry: ProviderRegistry
    let databaseWarning: String?

    /// 创建主 App 运行所需依赖。M2 起所有 UI 通过本组合根访问基础设施。
    static func makeDefault() throws -> AppBootstrap {
        let resolution = try SharedDatabaseURLResolver.resolve(mode: .appAllowingFallback)
        let store = try GRDBSnapshotStore(databaseURL: resolution.databaseURL)
        return AppBootstrap(
            store: store,
            secrets: KeychainSecretStore(service: AppGroupConstants.keychainService),
            registry: .v0_1Default,
            databaseWarning: resolution.warning
        )
    }

    /// 创建刷新所有账号的 UseCase。
    func makeRefreshAllAccountsUseCase() -> RefreshAllAccountsUseCase {
        RefreshAllAccountsUseCase(
            store: store,
            secrets: secrets,
            providerForID: { registry.provider(for: $0) }
        )
    }
}
