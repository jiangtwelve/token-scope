# Task Plan: M1_review_fixes · Code Review 修复

## Meta

- Version: v0.1
- Stage ID: M1_review_fixes
- Drafted At: 2026-06-26
- Approved At: 2026-06-26
- Source: 用户确认“那就按照你的计划执行吧”

## Tasks

> 颗粒度说明：本阶段是 M1 执行后的 review-fix，不新增产品能力，只修 code review 发现的 P0/P1 与一个低成本 P2。暂缓项已同步记录到 `PROJECT_STATE.md` Backlog，避免后续遗忘。

| id | title | 产出 / 验证 | 预估 | 依赖 |
|---|---|---|---|---|
| RF1 | 修改 `.github/workflows/ci.yml`：CI 直接构建 XcodeGen 生成的 `Apps/TokenScope-macOS.xcodeproj`，不依赖未跟踪 workspace | CI build 命令使用 `-project Apps/TokenScope-macOS.xcodeproj` | 10 min | — |
| RF2 | 修改 `GRDBSnapshotStore.loadAccounts()`：账号 row 解码失败时抛出明确错误，不再 `compactMap` 静默丢弃 | 源码中无静默丢账号路径 | 25 min | — |
| RF3 | 增加 `GRDBSnapshotStore` 坏账号行测试：手动插入不可解码 row，确认 `loadAccounts()` 抛错 | `swift test --package-path Packages/TSStorage` 覆盖坏数据路径 | 30 min | RF2 |
| RF4 | 修正 `RefreshAllAccountsUseCaseTests.partialFailure_oneSucceedsOneInvalid`：真实双账号，一成功一 invalid | `swift test --package-path Packages/TSCore` 覆盖混合结果路径 | 25 min | — |
| RF5 | 修改 `DeepSeekProvider`：非 2xx failure message 只保留 HTTP status，不持久化远端响应体 preview | `swift test --package-path Packages/TSProviders` 仍绿 | 10 min | — |
| RF6 | 更新 `PROJECT_STATE.md`：`03_active_development` 改为 `In Progress`，并记录本 review-fix 与暂缓项 | 治理状态不再误导后续 agent；暂缓项进入 Backlog | 20 min | — |
| RF7 | 跑测试与构建校验：TSCore / TSProviders / TSStorage / TSDesignSystem、Xcode build、governance check | 全部通过，失败则修复 | 40 min | RF1-RF6 |

## Deferred Review Items

这些项本次不修，已同步进 `PROJECT_STATE.md` Backlog：

- M2：拆分 `ContentView.swift` 中的 M1 临时 runner / env secret store / 路径解析，避免 M2 替换 UI 时遗失逻辑。
- M2/M4：抽共享数据库路径解析器；Widget 禁止 fallback，App fallback 时必须提示“Widget 不会更新”。
- v0.2：把 Provider decoder 的中间结果从 `UsageSnapshot` 占位对象改为 DTO，避免占位 UUID/Date 被误用。
- v0.2：评估 `Money` 跨币种安全 API，避免未来多币种聚合误用 `precondition` 导致 release crash。
- cleanup：补齐 public 方法级 doc comment，满足全局规则。

## Definition of Done

- [x] RF1-RF6 全部完成
- [x] TSCore tests 通过
- [x] TSProviders tests 通过
- [x] TSStorage tests 通过
- [x] TSDesignSystem tests 通过
- [x] App + Widget build 通过
- [x] `.project-governance/scripts/check-governance.sh` 通过

## Review Log

代码改动后的 review 留痕。规则见 `rules/DEVELOPMENT_PROCESS.md` "Code Review 后置" 段。`Review Method` 示例：`claude-code:/code-review`、`claude-code:/security-review`、`opencode:<review-agent-or-command>`、`codex:<review-agent-or-command>`、`project-script:<command>`、`agent-self-review`。

| Date | Scope | Result | Findings | Fix Status | Review Method |
|---|---|---|---|---|---|
| 2026-06-26 | 全阶段 | deferred-with-user-approval | Code Review 后置规则在阶段执行时（governance 1.1.0）尚未生效 | not-applicable | governance-1.1.0-predates-rule |

## Mutation Log

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
| 2026-06-26 | Initial review-fix plan locked at 7 tasks | 用户确认按建议执行，并要求暂缓项不要遗忘 | 2026-06-26 |
| 2026-06-26 | RF4 implementation adjusted `ApiKeyRoutingProvider` to an actor | Swift 6 disallows `NSLock.lock()` from async contexts; actor keeps fetch count concurrency-safe and tests green | 自动应用（属编译修复） |
