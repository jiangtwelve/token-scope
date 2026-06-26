// AppGroupConstants.swift
//
// 全项目共享标识符的单一来源。主 App 与 Widget Extension 都引用本文件。
//
// 设计原则（详见 .project-governance/decisions/D-001、D-006、ARCHITECTURE.md）：
//   - v0.1 使用 `local.*` 占位前缀，便于 v0.2 切换正式 Developer ID 时一次性 sed 替换。
//   - Keychain v0.1 不使用 Access Group（Widget 不需要 apiKey，见 D-006）；Widget 永不访问 Keychain。
//   - App Group 在 v0.1 已生效（基于 Personal Team 签名，Team ID 在 Apps/Local.xcconfig）。
//
// 关于 Team ID 的踩坑记录（仅作 agent 警示）：
//   Personal Team 的 Team ID 是证书 OU 字段（10 位字母数字），
//   不是 CN 字段括号里那 10 位（那是开发者个人 Membership ID）。
//   两者长得一模一样、都是 10 位、ID 格式相同——但取错会导致 xcodebuild 找不到 profile。

import Foundation

public enum AppGroupConstants {
    /// 主 App Bundle ID。M0~M5 期间稳定使用 local.* 占位；v0.2 替换为正式反域名。
    public static let appBundleID = "local.tokenscope.app"

    /// Widget Extension Bundle ID。
    /// 注意：macOS 强制要求 Widget Bundle ID 必须以 App Bundle ID 为前缀，
    /// 否则 ValidateEmbeddedBinary 会报错。这是 Apple 平台硬约束。
    public static let widgetBundleID = "local.tokenscope.app.widget"

    /// App Group ID。主 App 写入 / Widget 只读共享 SQLite 与设置。
    public static let appGroupID = "group.local.tokenscope.shared"

    /// Keychain service 名（v0.1 不带 Access Group，仅主 App 主进程访问）。
    public static let keychainService = "io.tokenscope.apikey"

    /// 共享 SQLite 文件名（位于 App Group 容器内）。
    public static let snapshotDatabaseFileName = "snapshots.sqlite"
}
