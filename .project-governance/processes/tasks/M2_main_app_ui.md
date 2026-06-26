# Task Plan: M2_main_app_ui · 主 App UI（MMF-2：肉眼可用）

## Meta

- Version: v0.1
- Stage ID: M2_main_app_ui
- Drafted At: 2026-06-26
- Approved At: 2026-06-26

## Tasks

> 颗粒度说明：本阶段目标是把 M1 临时 Refresh test 变成真实可用的主 App UI。每条 task 控制在 1 个主要文件或 1 个同一认知单元内，优先先补领域/存储测试，再写 UI。B-017 / B-018 中属于 M2 的暂缓项已纳入本 task plan；Widget 真实读取仍留 M4。

| id | title | 产出 / 验证 | 预估 | 依赖 |
|---|---|---|---|---|
| M2.1 | 写 `Shared/SharedDatabaseURLResolver.swift`：统一解析共享 SQLite 路径，主 App 可带 fallback warning，Widget 模式禁止 fallback | 文件存在；方法有 doc comment；单一来源替代 M1 `ContentView.resolveDatabaseURL()` | 35 min | — |
| M2.2 | 写 `TSCore/UseCases/AccountValidation.swift`：校验 label/baseURL/apiKey/threshold，返回用户可读错误 | 文件存在；不联网；边界输入可测 | 35 min | — |
| M2.3 | 写 `TSCoreTests/AccountValidationTests.swift`：覆盖空 label、非法 URL、空 key、非正阈值、合法 DeepSeek 默认值 | `swift test --package-path Packages/TSCore` 绿 | 30 min | M2.2 |
| M2.4 | 写 `Apps/TokenScope-macOS/AppBootstrap.swift`：创建 store、KeychainSecretStore、ProviderRegistry、RefreshAllAccountsUseCase，承接 M1TestRunner 里的组合根 | App 编译过；ContentView 不再承担依赖装配 | 35 min | M2.1 |
| M2.5 | 写 `Apps/TokenScope-macOS/ViewModels/AccountListViewModel.swift`：加载账号 + 最新快照、保存账号、删除账号、刷新单账号/全部账号的 UI 状态模型 | 文件存在；`@MainActor`；错误显式暴露为 alert 文案 | 60 min | M2.2, M2.4 |
| M2.6 | 写 `Apps/TokenScope-macOS/Views/ProviderListView.swift`：账号列表、余额、状态 badge、上次刷新时间、空状态 | 替代 M1 主界面主体；无 inline 样式大段堆叠；组件化 | 50 min | M2.5 |
| M2.7 | 写 `Apps/TokenScope-macOS/Views/ProviderAccountCard.swift`：单账号卡片，展示 label、baseURL、remaining、currency、success/failure/invalid 三态 | 文件存在；可被 ProviderList 复用 | 35 min | M2.6 |
| M2.8 | 写 `Apps/TokenScope-macOS/Views/ProviderEditorView.swift`：新增/编辑账号弹窗，baseURL、apiKey SecureField + 显隐、阈值输入、保存/取消 | 文件存在；保存前本地校验；apiKey 不显示明文默认态 | 60 min | M2.2, M2.5 |
| M2.9 | 写 `Apps/TokenScope-macOS/Views/DecimalField.swift`：Decimal 文本输入小组件，避免 Double 精度 | 文件存在；ProviderEditor 使用 | 30 min | M2.8 |
| M2.10 | 改 `ContentView.swift`：删除 M1TestRunner / EnvSecretStore / Refresh test UI，改为承载 `ProviderListView` | M1 临时代码不再存在；App 启动进入真实 UI | 35 min | M2.4-M2.9 |
| M2.11 | 给 `AccountListViewModel` 增加 lightweight 单元测试：用 mock store/secret/provider 验证新增账号写 GRDB+Keychain、删除账号删除两边、刷新更新快照状态 | 新测试文件；关键业务路径覆盖 | 60 min | M2.5 |
| M2.12 | 跑本机手动 smoke：新增 DeepSeek 账号（使用真实 key）、保存、手动刷新、看到 `30.18 CNY` 或当前真实余额、退出重启后账号仍在 | 用户或 agent 记录 smoke 结果；不把 key 写入 git | 30 min | M2.10 |
| M2.13 | 更新 `.project-governance/ssot/PROJECT_STATE.md`：记录 M2 执行状态；把 B-017 标为已覆盖，B-018 标注 M2 部分完成/M4 继续 | PROJECT_STATE 同步 | 15 min | M2.12 |
| M2.14 | 跑最终校验：TSCore/TSStorage/TSProviders/TSDesignSystem tests、xcodebuild、governance check | 全部通过 | 45 min | M2.1-M2.13 |

**预估总和**：约 565 min（≈ 9.4 小时纯开发）——M2 是第一轮真实 UI + Keychain 写入路径，复杂度高于 M1 review fixes。

## Risks

本次实例预估外风险。每条附触发条件 + 兜底动作。不重复 active.md M2 段的 `typical_pitfalls`。

- Risk A：SwiftUI + async ViewModel 状态更新触发 MainActor / Sendable 编译错误
  - 触发条件：`AccountListViewModel` 捕获 store/provider 时出现 Swift 6 strict concurrency 报错
  - 兜底动作：ViewModel 标 `@MainActor`，耗时操作通过 UseCase/actor store 执行；闭包和 model 保持 Sendable
- Risk B：Keychain 保存成功但 GRDB 保存失败导致半写入
  - 触发条件：ProviderEditor 保存时先写 Keychain 后写账号，后者失败
  - 兜底动作：保存账号流程先校验、再保存 account、再保存 key；任一步失败时显示错误，并在必要时回滚 key
- Risk C：真实 DeepSeek key 在 UI alert / debug print 中泄露
  - 触发条件：保存/刷新失败时把 apiKey 拼入错误描述
  - 兜底动作：错误文案只包含账号 label / HTTP 状态 / provider id，不包含 apiKey；不 print key
- Risk D：M2 引入较多 SwiftUI 文件导致组件边界混乱
  - 触发条件：单个 View 文件超过 400 行或 ProviderEditor 里混入刷新逻辑
  - 兜底动作：按 Views/ViewModels/Support 拆分；业务逻辑放 ViewModel / UseCase

## Explicitly Not Doing

明确划走的事，避免边界蔓延：

- 不做菜单栏、后台刷新、系统通知（M3）
- 不做 Widget 真实数据读取 / WidgetCenter reload（M4）
- 不做多 Provider 选择 UI；M2 只内置 DeepSeek（v0.1 范围）
- 不做 i18n
- 不做趋势图、历史列表、图表
- 不做自定义中转站 JSON path 模板
- 不改 Keychain Access Group 策略（v0.2 Developer ID 后再处理）
- 不处理 B-019 / B-020 / B-021，除非实施中顺手低成本触达；否则留后续 cleanup/v0.2

## Definition of Done

与 active.md 对应阶段 `done_when` 一一映射：

- [x] `ProviderList` 视图：账号卡片 + 余额 + 状态 badge + 上次刷新时间 ↔ M2.5, M2.6, M2.7
- [x] `ProviderEditor` 弹窗：baseURL（默认 `https://api.deepseek.com`）+ apiKey（带 👁 显隐）+ 阈值（CNY）↔ M2.2, M2.8, M2.9
- [x] 手动刷新按钮（单账号 + 全部）↔ M2.5, M2.6, M2.11
- [x] 失败态 / 失效态视觉清楚（按 PRD §Interaction）↔ M2.7, M2.8
- [x] 操作流程符合 AC-1（3 分钟内“配 key → 看到余额”）↔ M2.12
- [x] B-017 已处理：M1 临时 runner / EnvSecretStore / 路径解析从 ContentView 移除或替换 ↔ M2.1, M2.4, M2.10
- [x] B-018 的 M2 部分已处理：共享路径解析有单一来源；Widget 禁止 fallback 的真实读取留 M4 ↔ M2.1, M2.13
- [x] 全部 task 表逐条勾选完成
- [x] 最终测试 / build / governance check 通过 ↔ M2.14
- [x] 用户明确确认

## Review Log

代码改动后的 review 留痕。规则见 `rules/DEVELOPMENT_PROCESS.md` "Code Review 后置" 段。`Review Method` 示例：`claude-code:/code-review`、`claude-code:/security-review`、`opencode:<review-agent-or-command>`、`codex:<review-agent-or-command>`、`project-script:<command>`、`agent-self-review`。

| Date | Scope | Result | Findings | Fix Status | Review Method |
|---|---|---|---|---|---|
| 2026-06-26 | 全阶段 | deferred-with-user-approval | Code Review 后置规则在阶段执行时（governance 1.1.0）尚未生效 | not-applicable | governance-1.1.0-predates-rule |

## Mutation Log

执行中改动留痕。规则见 `rules/DEVELOPMENT_PROCESS.md` "Task Plan 前置 · 执行中改动" 段。

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
| 2026-06-26 | Initial approval — plan locked at 14 tasks | 用户 review 后明确确认 "M2 过" | 2026-06-26 |
| 2026-06-26 | M2.11 added `TokenScope-macOSTests` target and app ViewModel tests | ViewModel lives in App target, so tests need an app-hosted unit-test target rather than SPM tests | 自动应用（测试基础设施补齐） |
| 2026-06-26 | User accepted M2 smoke result | 用户本机新增账号 → 保存 → 刷新，看到余额；明确说 "M2 smoke 过" | 2026-06-26 |
