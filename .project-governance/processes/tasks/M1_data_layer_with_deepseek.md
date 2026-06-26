# Task Plan: M1_data_layer_with_deepseek · 数据层 + DeepSeek Provider

## Meta

- Version: v0.1
- Stage ID: M1_data_layer_with_deepseek
- Drafted At: 2026-06-25
- Approved At: 2026-06-25

## Tasks

> 颗粒度说明：本阶段共 18 条 task，其中 M1.3 / M1.4 各对应 4 个 / 3 个简单数据结构文件（同一概念组），M1.5 / M1.6 / M1.8 / M1.10 / M1.12 / M1.14 各包含"实现 + 测试"两个文件——这些是同一认知单元、失败可联动定位，刻意没拆为独立 task。其余每条 task ≤ 1 个文件。全 18 条 < 20 条阈值，无需触发反问。

| id | title | 产出 / 验证 | 预估 | 依赖 |
|---|---|---|---|---|
| M1.1 | 写 `TSCore/Sources/TSCore/Models/Money.swift`：`Money` 结构（Decimal amount + ISO 4217 currency 字符串），Sendable，含 `+/-/==/<` 运算符；同币种限制 | 文件存在；编译过 | 20 min | — |
| M1.2 | 写 `TSCore/Tests/TSCoreTests/MoneyTests.swift`：覆盖加减、币种不匹配 panic、零值边界、字符串解析 | `swift test --package-path Packages/TSCore` 绿，≥ 5 个用例 | 20 min | M1.1 |
| M1.3 | 写 TSCore 数据模型 4 件套（同 task 内 4 个文件，均简单 Sendable struct/enum）：`Models/Provider.swift`（id, displayName, defaultBaseURL）+ `Models/Account.swift`（id, providerID, label, baseURL, thresholdCNY: Decimal）+ `Models/UsageSnapshot.swift`（一比一对齐 cc-switch `UsageData` 字段）+ `Models/UsageResult.swift`（三态枚举 success/failure/invalid 含关联值） | 4 文件存在；编译过 | 30 min | M1.1 |
| M1.4 | 写 TSCore 三个协议（同 task 内 3 个文件，均 Sendable）：`Protocols/UsageProvider.swift`（async fetch 入口）+ `Protocols/SnapshotStore.swift`（save / loadLatest / cleanupOlderThan）+ `Protocols/SecretStore.swift`（save / load / delete by accountID） | 3 文件存在；编译过 | 20 min | M1.3 |
| M1.5 | 写 `TSCore/Sources/TSCore/UseCases/RefreshAllAccountsUseCase.swift` + 配套 `RefreshAllAccountsUseCaseTests.swift`：枚举所有账号、并行调用 Provider.fetch、写入 SnapshotStore、返回汇总结果。测试用 mock Provider + mock Store | swift test 绿，≥ 4 个用例（happy / 单账号失败 / 全部失败 / 空账号列表） | 40 min | M1.4 |
| M1.6 | 写 `TSCore/Sources/TSCore/UseCases/DetectLowBalanceUseCase.swift` + tests：输入 UsageSnapshot + threshold，输出"是否跨越阈值"+"是否需告警"（含 24h 去抖判断逻辑，去抖状态由调用方持有） | swift test 绿，≥ 4 个用例 | 30 min | M1.4 |
| M1.7 | 写 `TSProviders/Sources/TSProviders/DeepSeekResponseDecoder.swift`：纯函数 `decode(_ data: Data) -> UsageResult`，对齐 API_CONTRACT §DeepSeek 字段映射，兼容 `total_balance` 字符串/数字两种、`balance_infos` 空数组 | 文件存在；TSProviders 编译过 | 30 min | M1.4 |
| M1.8 | 写 `TSProviders/Tests/TSProvidersTests/DeepSeekResponseDecoderTests.swift`：按 API_CONTRACT §Mock data rules 的 T-API-1 ~ T-API-9 共 9 个表驱动用例。**这是 M1 测试基线的核心** | swift test 绿，9 个用例全过 | 60 min | M1.7 |
| M1.9 | 写 `TSProviders/Sources/TSProviders/DeepSeekProvider.swift`：实现 `UsageProvider`，URLSession 调 `GET {baseURL}/user/balance` Bearer，15s timeout，401/403 → invalid，其他 4xx/5xx/网络 → failure；解码委托给 DeepSeekResponseDecoder。**用 URLProtocol mock 写 ≥ 3 个集成测试**（正常 / 401 / 超时） | swift test 绿，3 个用例 | 50 min | M1.8 |
| M1.10 | 写 `TSProviders/Sources/TSProviders/ProviderRegistry.swift`：id → factory 映射，v0.1 只注册 `"deepseek"`。提供 `Registry.shared.provider(for:)` 入口 + 1 个小测试 | swift test 绿；编译过 | 15 min | M1.9 |
| M1.11 | 写 `TSStorage/Sources/TSStorage/Schema.swift` + `Sources/TSStorage/GRDBSnapshotStore.swift`：GRDBSnapshotStore 是 `actor`；初始化时建 `accounts` / `snapshots` 表（按 ARCHITECTURE §Data model 定义）；实现 SnapshotStore 协议的 save / loadLatest / cleanupOlderThan(days: 7) | 文件存在；编译过 | 60 min | M1.4 |
| M1.12 | 写 `TSStorage/Tests/TSStorageTests/GRDBSnapshotStoreTests.swift`：smoke 测试 3 用例（write→loadLatest、cleanup 7 天前快照、空库 loadLatest 返回 nil）。用临时目录的 sqlite，每次 setUp 重建 | swift test 绿，3 个用例 | 30 min | M1.11 |
| M1.13 | 写 `TSStorage/Sources/TSStorage/KeychainSecretStore.swift`：实现 SecretStore 协议，包装 `Security.framework` 的 `SecItemAdd/Copy/Delete`，service = `AppGroupConstants.keychainService`，account = `tokenscope.account.<UUID>.apiKey`；**不使用 Access Group**（v0.1，详见 D-006） | 文件存在；编译过 | 30 min | M1.4 |
| M1.14 | 写 `TSStorage/Tests/TSStorageTests/KeychainSecretStoreTests.swift`：smoke 测试 3 用例（save→load、delete→load 返回 nil、update 已存在 key）。**测试用一个隔离的临时 service 字符串**，避免污染开发者本机 Keychain | swift test 绿，3 个用例 | 30 min | M1.13 |
| M1.15 | `Apps/TokenScope-macOS/ContentView.swift` 替换 linkCheck 区域为 "Refresh test" 按钮：读 `ProcessInfo.processInfo.environment["TS_DEEPSEEK_KEY"]` → 构造硬编码 test Account → 调 `RefreshAllAccountsUseCase` → 写入 GRDBSnapshotStore（App Group 容器路径） → 主 App 控制台打印 UsageResult。**Keychain 在 M1 主 App 路径暂不接入**（仅 KeychainSecretStore 单测保证可用，M2 加账号 UI 时接入） | 编译过；按钮可点 | 30 min | M1.5, M1.10, M1.11 |
| M1.16 | 用户实操端到端验证：在 Xcode scheme TokenScope-macOS Run → Arguments → Environment Variables 加 `TS_DEEPSEEK_KEY=<your-deepseek-key>` → ⌘R → 点 Refresh test → 控制台看到 UsageResult.success + 余额数字 + 币种 + 写入数据库的提示；查 App Group 容器目录确认 sqlite 文件已生成 | 用户口头确认"看到了余额数字" | 5 min | M1.15 |
| M1.17 | 清理 M0 占位：删除 `TSCorePackage` / `TSProvidersPackage` / `TSStoragePackage` / `TSDesignSystemPackage` 4 个 placeholder 类型 + 它们的 skeleton test 文件 | 文件已删；`swift test` 各包仍绿（依赖 M1 新测试已存在） | 15 min | M1.16 |
| M1.18 | 跑 `.project-governance/scripts/check-governance.sh` + 自查 active.md M1 done_when 4 条 + 自查本 task plan Definition of Done | 校验通过 + 全部勾选 | 10 min | M1.17 |

**预估总和**：约 495 min（≈ 8.25 小时纯编码） — M1 比 M0 重得多，因为是实际业务代码 + 真正的单测覆盖。考虑试错与摸索，预留 1.5~2 个工作日。

## Risks

本次实例预估外风险。不重复 active.md M1 段的 `typical_pitfalls`。

- **Risk A：DeepSeek 真实账号 `/user/balance` 接口字段可能与 cc-switch 实测样例略有偏差**
  - 触发条件：M1.16 用户实操时拉到了数据但 UsageResult 字段解析错乱
  - 兜底动作：M1.16 失败时用 `print(String(data: data, encoding: .utf8))` 抓真实响应，对比 API_CONTRACT §Endpoints 字段映射，在 DeepSeekResponseDecoder 补防御逻辑 + 在 API_CONTRACT 加修订记录
- **Risk B：Swift 6 strict concurrency 在 actor + GRDB DatabaseQueue 桥接处报警**
  - 触发条件：M1.11 / M1.12 build 出现 "non-Sendable type ... in ... actor" 警告
  - 兜底动作：把 GRDB API 调用包到 `await pool.read { db in ... }` 闭包里、闭包返回 Sendable 拷贝；避免在 actor 状态里持有 `Database`/`Row` 之类非 Sendable 句柄
- **Risk C：URLProtocol mock 在 Swift 6 严格并发下需要 `@unchecked Sendable` 或额外标注**
  - 触发条件：M1.9 测试 build 报 URLProtocol 子类的并发警告
  - 兜底动作：把 mock 状态放进 `static var` + lock，或用 `URLSession.shared.dataTask` 的 protocolClasses 注入并接受 `@unchecked Sendable`
- **Risk D：Personal Team 签名的 App 在沙盒外访问 GRDB 共享容器路径，路径解析可能与生产 sandbox 时不同**
  - 触发条件：M1.15 写入数据库后查不到文件
  - 兜底动作：用 `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)` 拿路径并 print；若返回 nil（v0.1 App 未开 sandbox 时可能发生），fallback 到 `~/Library/Application Support/TokenScope/`，并在 M2 设计账号 UI 时显式处理路径分支
- **Risk E：DeepSeek 接口当前真实币种与 PRD 假设的 CNY 不一致**
  - 触发条件：M1.16 实操返回 `currency: "USD"` 或其他
  - 兜底动作：UsageSnapshot 不预设币种，按 API 实际返回存；UI/告警阈值在 M3 阶段处理多币种显示。M1.16 只校验"能拉到数字"，不要求 CNY

## Explicitly Not Doing

明确划走的事，避免边界蔓延：

- 不写真正的账号 CRUD UI（M2 的事；M1 用硬编码 test Account）
- 不接入主 App 的 Keychain 写入路径（M2 加 ProviderEditor 时再接；M1 只让单测覆盖 KeychainSecretStore）
- 不做菜单栏 / 后台刷新 / 通知（M3 的事）
- 不做 Widget 真实数据读取（M4 的事；M0 已留 placeholder）
- 不做错误的 UI 表达——M1 控制台 print 即可
- 不优化 GRDB 性能（无索引、无 WAL 调优）
- 不做 i18n（M2/M3 再考虑）
- 不引入新的第三方依赖（仅 GRDB，已在 M0 引入）
- 不处理 baseURL 自定义（用户可改 baseURL 是 PRD 功能，但 M1 用 DeepSeek 默认 `https://api.deepseek.com`）
- 不写 Provider 选择 UI（M2/M3 视情况引入）

## Definition of Done

与 `processes/active.md` M1_data_layer_with_deepseek 的 `done_when` 一一映射：

- [x] **done_when 1**（TSCore 模型 + 协议 + UseCase 完成）↔ M1.1, M1.2, M1.3, M1.4, M1.5, M1.6
- [x] **done_when 2**（TSProviders DeepSeek + Decoder 9 用例全绿）↔ M1.7, M1.8, M1.9, M1.10
- [x] **done_when 3**（TSStorage GRDB + Keychain smoke 通过）↔ M1.11, M1.12, M1.13, M1.14
- [x] **done_when 4**（App 临时按钮拉一次 + 控制台打印结果）↔ M1.15, M1.16
- [x] 全部 18 条 task 逐条勾选完成
- [x] M0 占位类型清理（M1.17）
- [x] `check-governance.sh` 通过（M1.18）
- [x] 用户明确针对本 task plan 与执行结果说"过 / 确认 / approve"

## Review Log

代码改动后的 review 留痕。规则见 `rules/DEVELOPMENT_PROCESS.md` "Code Review 后置" 段。`Review Method` 示例：`claude-code:/code-review`、`claude-code:/security-review`、`opencode:<review-agent-or-command>`、`codex:<review-agent-or-command>`、`project-script:<command>`、`agent-self-review`。

| Date | Scope | Result | Findings | Fix Status | Review Method |
|---|---|---|---|---|---|
| 2026-06-26 | 全阶段 | deferred-with-user-approval | Code Review 后置规则在阶段执行时（governance 1.1.0）尚未生效 | not-applicable | governance-1.1.0-predates-rule |

## Mutation Log

执行中改动留痕。规则见 `rules/DEVELOPMENT_PROCESS.md` "Task Plan 前置 · 执行中改动" 段。

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
| 2026-06-25 | Initial approval — plan locked at 18 tasks | 用户 review 后明确确认 "m1 过" | 2026-06-25 |
| 2026-06-26 | Widget 占位文本从 `TSCorePackage.version` 改为 `Provider.deepSeek.id` | M1.17 删除 M0 占位类型后，Widget 仍引用 `TSCorePackage` 导致 App build 失败。改为 TSCore 真实类型，保持 link 验证语义 | 自动应用（属清理遗漏修复） |
| 2026-06-26 | `Apps/project.yml` 增加显式 shared scheme `TokenScope-macOS` | M1.18 校验时发现 XcodeGen 重新生成后 workspace 只暴露 SPM 包 schemes，`xcodebuild -workspace ... -scheme TokenScope-macOS` 找不到 App scheme。加显式 scheme 是工程生成配置修正，不改变产品/架构范围 | 自动应用（属事实修正） |
| 2026-06-25 | T-API 9 用例分拆：DecoderTests 承担 T-API-1/2/3/7/8/9（6 个 JSON 解析场景），ProviderTests 承担 T-API-4/5/6（3 个 HTTP 场景）。M1.8 done 标准从"9 用例"调整为"6 用例" | Decoder 是纯函数，看不到 HTTP 状态；T-API-4/5/6 只能在 URLProtocol mock 集成测试里验证。总覆盖度不变（仍 9 用例），仅文件归属调整 | 自动应用（属合理化拆分） |
| 2026-06-26 | User gave final approval after M1 review fixes | 用户明确说 "M1 过"；M1_data_layer_with_deepseek + M1_review_fixes 均已完成并验证通过，可进入 M2 task plan 起草 | 2026-06-26 |
