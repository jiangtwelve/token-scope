// SharedDatabaseURLResolver.swift
//
// 主 App 与 Widget 共用的 SQLite 路径解析器。M2 起替代 ContentView 内的临时路径逻辑。

import Foundation

public enum SharedDatabaseURLResolver {
    public enum Mode: Sendable {
        case appAllowingFallback
        case widgetRequireAppGroup
    }

    public struct Resolution: Sendable, Equatable {
        public let databaseURL: URL
        public let warning: String?

        public init(databaseURL: URL, warning: String? = nil) {
            self.databaseURL = databaseURL
            self.warning = warning
        }
    }

    public enum ResolveError: Error, Equatable, CustomStringConvertible {
        case appGroupUnavailable(String)

        public var description: String {
            switch self {
            case .appGroupUnavailable(let groupID):
                return "App Group container is unavailable: \(groupID)"
            }
        }
    }

    /// 解析共享 SQLite 路径。
    ///
    /// 主 App 在 v0.1 本机开发阶段允许 fallback，并返回 warning；Widget 必须使用 App Group，
    /// 失败时直接 throw，避免 Widget 和 App 读写不同数据库。
    public static func resolve(mode: Mode) throws -> Resolution {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroupConstants.appGroupID
        ) {
            return Resolution(databaseURL: databaseURL(in: groupURL))
        }

        switch mode {
        case .appAllowingFallback:
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            )[0]
            let fallbackURL = appSupport
                .appendingPathComponent("TokenScope", isDirectory: true)
                .appendingPathComponent(AppGroupConstants.snapshotDatabaseFileName)
            return Resolution(
                databaseURL: fallbackURL,
                warning: "App Group container unavailable; Widget will not see this fallback database."
            )
        case .widgetRequireAppGroup:
            throw ResolveError.appGroupUnavailable(AppGroupConstants.appGroupID)
        }
    }

    /// 将 App Group 根目录转换为 SQLite 文件路径。
    public static func databaseURL(in groupURL: URL) -> URL {
        groupURL
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(AppGroupConstants.snapshotDatabaseFileName)
    }
}
