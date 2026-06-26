# D-006: v0.1 unsigned build 下使用 non-shared Keychain

- ID: D-006
- Date: 2026-06-24
- Title: v0.1 unsigned build 下使用 non-shared Keychain；v0.2 上 Developer ID 后切回 Access Group 共享给 Widget
- Area: Security
- Status: accepted
- Related SSOT: `ssot/ARCHITECTURE.md §Security and privacy`、`processes/active.md M1_data_layer_with_deepseek`

## Context

v0.1 选择不申请 Apple Developer 账号（D-001）。意味着 build 是 unsigned。在 unsigned + non-sandbox 模式下：

- `kSecAttrAccessGroup` 共享 Keychain 行为不稳定（Apple 文档要求 Access Group 必须匹配 Team ID 前缀）
- Widget Extension 跨进程读 Keychain 通过 Access Group 可能失败

但 v0.1 的核心安全底线（apiKey 不出现在 SQLite、不出现在日志、不进崩溃报告）仍必须满足。

## Options

- A. 不管 Widget，仍硬要 Access Group（实际可能挂）
- B. **v0.1 用 non-shared Keychain：主 App 在主进程内访问 Keychain 取出 apiKey 后调网络，写好结果到 GRDB；Widget 完全不接触 Keychain（它只读余额快照，不需要 apiKey）** ← chosen
- C. v0.1 把 apiKey 也写进 App Group SQLite（绝不可接受，违反安全底线）

## Chosen

B。关键洞察：**Widget 不需要 apiKey**——Widget 只读余额快照展示，所有网络拉取在主 App 完成。Access Group 跨进程共享 apiKey 的需求其实**在 v0.1 不存在**。

具体落地：

- `KeychainSecretStore` 实现：`kSecAttrService = "io.tokenscope.apikey"`、不设 Access Group
- 主 App 写入 / 读取 / 删除 apiKey 走单进程 Keychain，行为可靠
- Widget Extension 严格只读 GRDB 共享 SQLite，**永不调用 SecretStore**（用 entitlements + 模块依赖双重隔离）

## Impact

- M1_data_layer_with_deepseek 阶段 typical_pitfalls 已注明
- ARCHITECTURE §Security and privacy 标注 v0.1 不开 App Sandbox
- ARCHITECTURE §System overview Keychain Access Group 仍写 `$(AppIdentifierPrefix)local.tokenscope.shared` 但仅作 v0.2 占位说明，v0.1 实际配置不启用 Access Group entitlement
- Backlog B-014 登记 v0.1 → v0.2 切回 Access Group 的迁移点

## Follow-ups

- v0.2 上 Developer ID 后：
  1. 在 Apple Developer Portal 注册 App Group 与 Keychain Access Group
  2. App + Widget 双 target 加上 entitlements
  3. `KeychainSecretStore` 改为带 Access Group 的版本
  4. 验证 Widget 是否真的需要 apiKey（如果 v0.2 仍是主 App 全权拉取，Widget 仍不需要 apiKey，本切换可推迟）

## Revisions

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
| 2026-06-25 | v0.1 切到 Personal Team 签名（D-001 Revision）后，理论上 Keychain Access Group 也变得可用了。但本决策结论不变：v0.1 仍用 non-shared Keychain，因为 Widget 不需要 apiKey（只读余额快照）。Access Group 引入只增加表面积、无功能收益。v0.2 上正式 Developer ID 后视需要再切 | 决策依据是"Widget 不需要 apiKey"的功能事实，而不是"unsigned 不能用 Access Group"的实现限制。前者不随签名状态改变 | 2026-06-25 |
