# Project State

当前状态快照，不是开发日志。开始工作前读取；结束后仅在发生实质状态变化时更新。

## Active Version

- Current Version: v0.1
- Active Process: `.project-governance/processes/active.md`（`macos-native-mmf-first-v1`）
- Process Mutation Threshold: 3

## Versions

每个版本包含独立的骨架四段。旧版本走完打 `Released`，新版本追加在下方。任何阶段状态变化必须更新本段。

### v0.1  Status: In Progress

| Stage ID | 中文名称 | Status |
|---|---|---|
| 01_requirements_confirmation | 需求确认 | Confirmed |
| 02_tech_stack_confirmation | 技术栈确认 | Confirmed |
| 03_active_development | 实际开发 | In Progress |
| 04_acceptance_testing | 验收测试 | Not Started |

状态值：`Not Started` / `In Progress` / `Confirmed` / `Blocked: regressed to <stage_id>`。

## Snapshot

- Current goal: 起草 M3_ambient_layer 颗粒级 task plan；用户 review 通过后再进入 M3 编码。
- Completed:
  - v0.1 第一段「需求确认」：PRD 通过用户明确确认。
  - v0.1 第二段「技术栈确认」：ARCHITECTURE 收口、6 项核心技术决策记录到 decisions/、Active Process 起草并确认。
  - Governance 升级到 1.1.0：增加 "Task Plan 前置" 红线。
  - **M0_skeleton_bootstrap ✅ 已验收完成**（2026-06-25）：15 条 task 全过 + 用户实测 App 窗口 + Widget Gallery placeholder 卡片可见。
  - **M1_data_layer_with_deepseek ✅ 已执行完成**（2026-06-26）：TSCore 模型/协议/UseCase、TSProviders DeepSeek Decoder/Provider/Registry、TSStorage GRDBSnapshotStore/KeychainSecretStore、App 临时 Refresh test 全链路完成。
  - M1 用户实测真实 DeepSeek 余额成功：`Saved snapshot rows: 1`，余额 `30.18 CNY`，SQLite 写入 App Group 容器：`~/Library/Group Containers/group.local.tokenscope.shared/Library/Application Support/snapshots.sqlite`。
  - M1 最终校验：TSCore 24 tests、TSProviders 20 tests、TSStorage 11 tests、TSDesignSystem 1 test 全绿；App + Widget build succeeded；governance validator OK。
  - **M1_review_fixes ✅ 已完成**（2026-06-26）：修复 CI workspace 依赖、GRDB 账号解码静默丢弃、部分失败测试覆盖、非 2xx 错误体持久化与治理状态同步；TSCore/TSProviders/TSStorage/TSDesignSystem tests 全绿；App + Widget build succeeded；governance validator OK。
  - **M1 最终确认 ✅**（2026-06-26）：用户明确说 “M1 过”，允许进入 M2 task plan 起草。
  - **M2 task plan ✅ 已确认**（2026-06-26）：用户明确说 “M2 过”，允许进入 M2_main_app_ui 编码。
  - **M2_main_app_ui ✅ 已验收完成**（2026-06-26）：实现 `AppBootstrap` / `SharedDatabaseURLResolver` / `AccountValidation` / `AccountListViewModel` / `ProviderListView` / `ProviderAccountCard` / `ProviderEditorView` / `DecimalField`；清理 M1 临时 runner、`EnvSecretStore`、`Refresh test` UI；接入 `KeychainSecretStore`。TSCore 29 tests / TSProviders / TSStorage / TSDesignSystem tests 全绿；App + Widget build succeeded；新增 `TokenScope-macOSTests` 3 个 ViewModel 测试通过；governance validator OK；用户本机 smoke 通过（"M2 smoke 过"）。已处理 Backlog B-017、B-018（M2 部分）。
- In progress: 等待 M3 task plan 起草与用户确认。
- Next steps:
  1. 起草 M3_ambient_layer task plan（菜单栏常驻 + 后台定时刷新 + 低余额通知 + 开机自启）。
  2. 用户 review M3 task plan 后再进入 M3 编码。
  3. M3 完成后进入 M4_widget_extension。
- Blockers: 无（等 M1 确认）。

## Key Facts

记录新 agent 不知道就可能做错需求、架构、流程或验收判断的项目级事实。

- **参考源 `cc-switch`**：项目根目录下 `cc-switch/` 子目录是另一独立项目的源码，**不是本项目代码**。它是 token-scope 的**协议与实现参考**，特别是 `cc-switch/src-tauri/src/services/balance.rs`（包含 DeepSeek、StepFun、SiliconFlow、OpenRouter、Novita 的 Rust 实现）和 `coding_plan.rs`（Kimi、智谱、MiniMax、ZenMux、火山方舟 Coding Plan 实现）。token-scope 字段语义一比一对齐 cc-switch `UsageData`，但**用 Swift 重写、不依赖 cc-switch 任何代码**。
- **画像极窄**：v0.1 用户画像不包含 Codex / Claude.ai / ChatGPT Plus / Cursor / Copilot 等订阅式产品 —— 这些产品没有 baseURL + apiKey 模式，要做需要另起一条产品线。
- **v0.1 验证池子=作者本人**：v0.1 不发 DMG、不上 TestFlight、无 Developer 账号。验收基准是作者本人 7 天连续使用 + 本机 build 全绿。原"20 人留存 H1"推到 v0.2。
- **Bundle ID 占位**：v0.1 用 `local.tokenscope.app` / `local.tokenscope.widget` / `group.local.tokenscope.shared`。v0.2 上 Developer ID 时一次性替换前缀（D-001 已留可控替换点）。
- **Keychain Access Group v0.1 → v0.2 迁移点**：v0.1 unsigned build 下使用 non-shared Keychain；v0.2 上 Developer ID 后切回 Access Group 共享给 Widget。详见 decisions/D-006。
- **DeepSeek 余额单位是 CNY**：返回的 `balance_infos[].currency` 通常为 "CNY"，UI 与告警阈值需按 CNY 处理。
- **Widget 永不联网**：架构硬约束。Widget Extension 只读 App Group 共享 SQLite，所有网络拉取在主 App 完成。
- **错误三态**：success / failure(network) / invalid(账号失效) —— 401/403 走 `invalid`，对齐 cc-switch `is_valid` 语义；与"网络瞬断"严格区分。
- **后台运行模型**：App 必须在菜单栏常驻 + 开机自启才能后台刷新（NSBackgroundActivityScheduler 仅在 App 运行时调度）。用户 Quit 后不刷新——这是已知权衡，v0.2 视反馈决定是否加 LaunchAgent。

## Stage Regressions

记录同版本内的回归动作。

| Date | Version | From Stage | To Stage | Reason | User Confirmed |
|---|---|---|---|---|---|

## Stage Skips

记录骨架阶段或开发流程内部阶段的一次性豁免。需求确认、技术栈确认、验收测试不允许跳过。

| Date | Version | Stage ID | 中文名称 | Reason | Impact | User Confirmed |
|---|---|---|---|---|---|---|

## Backlog

记录被推迟但未明确进入某版本的功能。`Target Version` 已标注的项进入对应版本的需求范围。

| ID | Description | From Version | From Stage | Target Version | Reason | User Confirmed |
|---|---|---|---|---|---|---|
| B-001 | iOS 端 App + 主屏/锁屏 Widget + 灵动岛 | v0.1 | 01_requirements_confirmation | v0.2 | v0.1 单端 4 周即可交付；iOS BGTask 与 iCloud 同步策略待 macOS 验证完再定 | 2026-06-24 |
| B-002 | iCloud Keychain 同步 baseURL + apiKey | v0.1 | 01_requirements_confirmation | v0.2 | 仅 macOS 时无跨端同步必要 | 2026-06-24 |
| B-003 | 平移 cc-switch OpenRouter / SiliconFlow / StepFun / Novita 实现 | v0.1 | 01_requirements_confirmation | v0.2 | 均为 Bearer + GET 同型，1 周可完成；v0.1 只保 1 家以最小化验证回路 | 2026-06-24 |
| B-004 | 火山方舟 Coding Plan（含 SigV4 火山变体签名库） | v0.1 | 01_requirements_confirmation | v0.3 | cc-switch 实现约 1150 行 Rust，移植为 Swift 约 2~3 天，v0.1 不承担 | 2026-06-24 |
| B-005 | 其他 Coding Plan：Kimi / 智谱 GLM / MiniMax / ZenMux | v0.1 | 01_requirements_confirmation | v0.3 | quota tier 语义与 balance 不同，需 v0.3 同时上 | 2026-06-24 |
| B-006 | 用户自定义中转站协议（JSON path 模板） | v0.1 | 01_requirements_confirmation | v0.4 | 长尾扩展，待主流家覆盖完再上 | 2026-06-24 |
| B-007 | 趋势图 / 模型拆分 / 按时间区间筛选 | v0.1 | 01_requirements_confirmation | v0.4 | v0.1~0.3 只看快照，趋势能力靠快照累积一段时间后再做 | 2026-06-24 |
| B-008 | 同一供应商多账号支持 | v0.1 | 01_requirements_confirmation | v0.2 | v0.1 每家只 1 个账号简化 UI 与数据模型 | 2026-06-24 |
| B-009 | Mac App Store 上架 + 订阅商业化 | v0.1 | 01_requirements_confirmation | v1.0 | v0.1~0.4 全免费走 DMG，先验证留存 | 2026-06-24 |
| B-010 | 团队共享余额 / 多人对账 | v0.1 | 01_requirements_confirmation | v1.0+ | 需后端、需权限模型，远期商业化触发再做 | 2026-06-24 |
| B-011 | Claude Code 本地 jsonl 解析（ccusage 思路） | v0.1 | 01_requirements_confirmation | v0.4 | 服务订阅型用户的入口；与本画像有偏差，推迟 | 2026-06-24 |
| B-012 | 补齐 80% 全局测试覆盖率红线（v0.1 已豁免） | v0.1 | 02_tech_stack_confirmation | v0.2 | v0.1 仅作者本机使用，测试基线收窄为"领域+解码+smoke"；正式分发前需补齐 | 2026-06-24 |
| B-013 | v0.1 → v0.2 切换正式 Bundle ID 前缀（`local.*` → 反域名）与 Developer ID 签名 | v0.1 | 02_tech_stack_confirmation | v0.2 | v0.1 用占位 Bundle ID 在本机跑；v0.2 申请 Developer 账号后一次性替换 | 2026-06-24 |
| B-014 | v0.1 → v0.2 切回 Keychain Access Group 共享给 Widget | v0.1 | 02_tech_stack_confirmation | v0.2 | unsigned build 下 Access Group 不可靠；v0.1 用 non-shared Keychain，v0.2 上 Developer ID 后切回 | 2026-06-24 |
| B-015 | v0.1 → v0.2 评估 LaunchAgent 兜底"用户 Quit 后仍想要 widget 刷新"的需求 | v0.1 | 02_tech_stack_confirmation | v0.2 | v0.1 接受 Quit 即停刷新；若 v0.1 用户反馈强烈再补 LaunchAgent 方案 | 2026-06-24 |
| B-017 | 拆分 `ContentView.swift` 中的 M1 临时 runner / `EnvSecretStore` / 数据库路径解析 | v0.1 | M1_review_fixes | M2 | M2 会替换临时 UI，届时应把组合根与测试 secret store 从 View 中移出，避免误删或重复实现 | 2026-06-26 |
| B-018 | 抽共享数据库路径解析器；Widget 禁止 fallback，App fallback 时提示“Widget 不会更新” | v0.1 | M1_review_fixes | M2/M4 | 当前实测已走 App Group，但 fallback 路径未来可能让 Widget 读不到 App 写入数据；Widget 接库前必须处理 | 2026-06-26 |
| B-019 | Provider decoder 使用 DTO 替代带占位 UUID/Date 的 `UsageSnapshot` 中间对象 | v0.1 | M1_review_fixes | v0.2 | 当前由 UseCase 覆盖上下文字段，暂不影响 M1；多 Provider 前应降低误用风险 | 2026-06-26 |
| B-020 | 评估 `Money` 跨币种安全 API，避免未来多币种聚合误用 `precondition` 导致 release crash | v0.1 | M1_review_fixes | v0.2 | 当前低余额 UseCase 已有币种 guard；多币种聚合/排序出现前再设计安全 API | 2026-06-26 |
| B-021 | 补齐 public 方法级 doc comment，满足全局“每一个方法都必须有注释”规则 | v0.1 | M1_review_fixes | cleanup | 不影响 M1 行为，但应在 cleanup 或 M2 前后统一补齐 | 2026-06-26 |

Last updated: 2026-06-24
