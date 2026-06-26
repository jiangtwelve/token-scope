# Active Process

本文件记录**当前项目当前版本商定的开发流程**。在骨架第二段（技术栈确认）由 agent 与用户共同填写。本文件只服务于实际开发段；启动新版本时按需重新填写或继承。

字段定义、改动规则与可裁剪边界见 `rules/DEVELOPMENT_PROCESS.md`，沉淀规则见 `rules/VERSION_RULES.md`。

> **Task Plan 红线（v0.1 已明确确认）**：本流程的 M0~M5 全部为 `acceptance_required: true`。进入任一阶段编码前，agent 必须先在 `processes/tasks/<stage_id>.md` 产出**颗粒级** task plan（单条 task 产出 ≤ 1 个文件、预估 ≤ 1 小时、可肉眼验证），并经用户明确说"过 / 确认 / approve"才能开始写代码。模板见 `templates/RECORD_TEMPLATES.md`，规则见 `rules/DEVELOPMENT_PROCESS.md` "Task Plan 前置" 段。

## Metadata

- Name: `macos-native-mmf-first-v1`
- Applicable To: 单/双工程师 + 单平台 macOS 原生 App（SwiftUI + 可选 Widget Extension）+ PRD 已拆为 ≤ 5 个独立可用 MMF + 强调"每个 MMF 后用户可停下" + 测试基线豁免 80% 覆盖率
- Source: `drafted-in-project`（流程库为空，现场起草）
- Applied To Version: v0.1
- Confirmed At: 2026-06-24

## Stages

按 `rules/DEVELOPMENT_PROCESS.md` 的字段顺序逐条填写。每个阶段结束后必须用户明确确认才进下一阶段。

### M0_skeleton_bootstrap

- id: M0_skeleton_bootstrap
- name_zh: 工程骨架就位
- goal: 把 workspace、4 个 SPM 包、App + Widget Extension target、CI workflow 全部跑通空壳。
- done_when:
  - TokenScope.xcworkspace 在 Xcode 16 中能打开
  - 4 个 SPM 包 (`TSCore` / `TSProviders` / `TSStorage` / `TSDesignSystem`) 各有空 placeholder + 一个 "hello world" 测试，`swift test` 全绿
  - App target 能 cmd-R 启动空白窗口
  - Widget Extension target 能 cmd-R 在 Widget Gallery 显示 "placeholder" 卡片
  - `.github/workflows/ci.yml` 第一次跑通（swift test + xcodebuild build 均绿）
- acceptance_required: true
- optional: false
- typical_pitfalls:
  - App Group 和 Bundle ID 一开始就乱命名后期难统一改 → 用 `local.tokenscope.*` 占位时也要在 `Shared/AppGroupConstants.swift` 单一来源
  - Widget Extension target 漏配 App Group entitlement → cmd-R 时 Widget 拉不到容器路径
  - GRDB 7 + Swift 6 严格并发的 SPM resolve 要锁版本（最低 7.x，写死 minor）

### M1_data_layer_with_deepseek

- id: M1_data_layer_with_deepseek
- name_zh: 数据层 + DeepSeek Provider（MMF-1：核心数据可拉取）
- goal: 用临时按钮触发，能从 DeepSeek 拉到余额并写入 GRDB；apiKey 仅存 Keychain（v0.1 unsigned 下接受 non-shared Keychain）。
- done_when:
  - `TSCore` 模型 + 协议 + UseCase 完成（`RefreshAllAccountsUseCase` / `DetectLowBalanceUseCase`）
  - `TSProviders.DeepSeekProvider` + `DeepSeekResponseDecoder` 完成，按 `API_CONTRACT.md` 9 个表驱动用例全绿
  - `TSStorage.GRDBSnapshotStore`（actor）+ `KeychainSecretStore` 完成，smoke 测试通过
  - App 加临时 "Refresh test" 按钮：硬编码 apiKey 拉一次、写库、控制台打印
- acceptance_required: true
- optional: false
- typical_pitfalls:
  - Decoder 把 `total_balance` 当 `Double` 解析，DeepSeek 实际返回字符串 → 按 cc-switch `parse_f64_field` 兼容字符串与数字
  - GRDB Snapshot actor 与主线程 SwiftUI 桥接易触发 Swift 6 严格并发警告 → 提前约定 `@MainActor` 边界
  - Keychain Access Group 在 unsigned build 下行为不确定 → v0.1 接受用 non-shared Keychain 跑通，v0.2 上 Developer ID 再切回 Access Group（**已识别迁移点，见 decisions/D-006**）

### M2_main_app_ui

- id: M2_main_app_ui
- name_zh: 主 App UI（MMF-2：肉眼可用）
- goal: 用户能在主窗口完成账号增/删/改、手动刷新、看到余额数字；删除 M1 临时按钮。
- done_when:
  - `ProviderList` 视图：账号卡片 + 余额 + 状态 badge + 上次刷新时间
  - `ProviderEditor` 弹窗：baseURL（默认 `https://api.deepseek.com`）+ apiKey（带 👁 显隐）+ 阈值（CNY）
  - 手动刷新按钮（单账号 + 全部）
  - 失败态 / 失效态视觉清楚（按 PRD §Interaction）
  - 操作流程符合 AC-1（3 分钟内"配 key → 看到余额"）
- acceptance_required: true
- optional: false
- typical_pitfalls:
  - apiKey 输入框默认遮蔽如果用 `.textContentType(.password)`，部分 macOS 版本会触发 Keychain 弹窗 → 用 `SecureField` + 自定义切换
  - "保存前不联网校验" vs "保存后立即刷新"边界要清晰，避免双重 loading
  - 阈值 CNY 输入支持 Decimal（避免 Double 精度），用 `DecimalField`

### M3_ambient_layer

- id: M3_ambient_layer
- name_zh: 菜单栏 + 后台刷新 + 告警（MMF-3：ambient 形态成立）
- goal: 用户合上窗口后，菜单栏图标实时显示余额，后台每 30 分钟自动刷新，低余额时本机通知。
- done_when:
  - `NSStatusItem` 显示余额数字（如 "¥38.2"），点开下拉账号列表
  - `BackgroundRefreshScheduler`（NSBackgroundActivityScheduler）30 分钟一次，设置里可改 15/30/60/关闭
  - `LoginItemController`（SMAppService）：设置里开关 "开机自启"
  - `LowBalanceNotifier`：跨越阈值发系统通知 + 24h 去抖（按 PRD F-106）
  - 设置面板：刷新频率、开机自启、隐藏菜单栏图标
- acceptance_required: true
- optional: false
- typical_pitfalls:
  - `NSBackgroundActivityScheduler` 在 App inactive 时调度间隔被系统拉长 → README 写清楚预期
  - `SMAppService.mainApp.register()` 在 unsigned build 下成功率不稳 → v0.1 接受"可能失败一次"，第二次成功即可
  - 通知 24h 去抖需持久化"上次告警时间"，写 UserDefaults 而非 GRDB（重启后仍去抖）

### M4_widget_extension

- id: M4_widget_extension
- name_zh: Widget Extension（MMF-4：桌面 ambient）
- goal: 用户把 Widget 拖到桌面/通知中心，看到与 App 一致的余额卡片，主 App 刷新后 30 秒内更新。
- done_when:
  - `BalanceWidget` + `BalanceTimelineProvider` 完成
  - `systemMedium` 单尺寸卡片：账号 label + 余额 + 币种 + 相对时间（"5 分钟前"）+ 失败/失效态
  - Widget 通过 App Group 读取 SQLite，**完全不联网**（entitlements 不开网络权限作硬约束）
  - 主 App 写完调用 `WidgetCenter.shared.reloadAllTimelines()`，30 秒内 Widget 可见新数据（满足 AC-4）
  - macOS 桌面 + 通知中心两处都能正常添加和显示
- acceptance_required: true
- optional: false
- typical_pitfalls:
  - Widget Extension 与主 App 共享代码时把 `URLSession` 也带进了 Widget → 用条件编译或拆 storage-only 依赖把网络栈隔离
  - GRDB 在 Widget Extension 中以**只读**模式打开（`DatabaseQueue` 只读），避免并发写冲突
  - TimelineProvider 的 `getTimeline` 必须返回多个 entry 才不被系统过度调度，但 v0.1 只放 1 个 entry + `policy: .never`（依赖 App 触发 reload）

### M5_release_polish

- id: M5_release_polish
- name_zh: 自验证 + 文档（MMF-5：可对外说"看下我做的"）
- goal: 作者本人 7 天连续使用 + 写一份 README 让任何会 cmd-R 的开发者能跑起来。
- done_when:
  - 全部 AC（AC-1 ~ AC-9）逐条勾选通过
  - GLOSSARY 全部条目的 `Code Identifier` 已补齐
  - README.md（项目根，与 `cc-switch/README.md` 区分）写明：项目定位、v0.1 范围、cmd-R 步骤、已知限制、v0.2 路线
  - 作者本人连续使用 ≥ 7 天，每天主观打分（GitHub Issue 记"今天有没有让我后悔开着它"）
  - 7 天后做一次回顾：H0 是否成立？发现的 bug/痛点列入 v0.2 Backlog
- acceptance_required: true
- optional: false
- typical_pitfalls:
  - 自己用自己写的工具容易"只走 happy path"，要刻意触发：错 key、断网、改阈值、合盖一夜……
  - README 容易写成开发者文档，要明确"这是 v0.1 自用版"，不要承诺签名 DMG 等 v0.2 内容
  - 7 天回顾如果发现 H0 不成立（如"装上就忘"），诚实写入决策记录，决定停在 v0.1 还是继续 v0.2，**不要因为已经投入了就硬上 v0.2**

## Lessons Learned

（v0.1 完成后回填，再决定是否沉淀到 `~/.claude/process-library/macos-native-mmf-first-v1.md`）

## Mutation Log

记录本流程在当前版本内的改动历史。改动规则见 `rules/DEVELOPMENT_PROCESS.md`。

| Date | Change Type | Detail | Reason | User Confirmed |
|---|---|---|---|---|
