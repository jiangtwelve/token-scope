# Task Plan: M3_ambient_layer · 菜单栏 + 后台刷新 + 告警（MMF-3：ambient 形态成立）

## Meta

- Version: v0.1
- Stage ID: M3_ambient_layer
- Drafted At: 2026-06-26
- Approved At: pending

## Tasks

> 颗粒度说明：M3 把 M2 的"手动刷新主窗口"升级为后台常驻形态：菜单栏数字、定时调度、告警通知、开机自启、设置面板。每条 task 控制在 ≤ 2 个同一认知单元的文件。无新增第三方依赖。

| id | title | 产出 / 验证 | 预估 | 依赖 |
|---|---|---|---|---|
| M3.1 | 更新 `ssot/GLOSSARY.md`：登记 M3 新概念 — App Preferences / Refresh Interval / Alert Ledger / Login Item | 4 条新行；术语红线满足 | 20 min | — |
| M3.2 | 写 TSCore 偏好与告警模型 + 协议：`Models/RefreshInterval.swift`、`Models/AppPreferences.swift`、`Protocols/PreferencesStore.swift`、`Protocols/AlertLedger.swift` | 4 文件；TSCore 编译过 | 35 min | M3.1 |
| M3.3 | 写 `TSCoreTests/AppPreferencesTests.swift`：默认值 / Codable round-trip / `RefreshInterval` 边界 | `swift test --package-path Packages/TSCore` 绿 | 25 min | M3.2 |
| M3.4 | 写 App 持久化：`Apps/.../Persistence/UserDefaultsPreferencesStore.swift` + `Apps/.../Persistence/UserDefaultsAlertLedger.swift`，统一使用 App Group `UserDefaults(suiteName:)` | 2 文件；编译过 | 45 min | M3.2 |
| M3.5 | 写 `Apps/.../Notifications/LowBalanceNotifier.swift`：包装 `UNUserNotificationCenter`，调用 `DetectLowBalanceUseCase`，依赖 `AlertLedger` 做 24h 去抖；包含授权检查与未授权降级 | 文件；编译过 | 50 min | M3.4 |
| M3.6 | 写 `Apps/TokenScope-macOSTests/LowBalanceNotifierTests.swift`：mock `AlertLedger` + 协议化的 notification center，覆盖 alert / debounced / aboveThreshold / invalid 四态 | xcodebuild test 绿，≥ 4 用例 | 45 min | M3.5 |
| M3.7 | 写 `Apps/.../Background/BackgroundRefreshScheduler.swift`：`NSBackgroundActivityScheduler` 包装，`apply(interval:)`、`start()`、`stop()`；每次触发调用 RefreshCoordinator + Notifier | 文件；编译过 | 45 min | M3.5 |
| M3.8 | 写 `Apps/.../Background/LoginItemController.swift`：`SMAppService.mainApp` register/unregister/read status；unsigned build 失败时返回明确错误 | 文件；编译过 | 30 min | — |
| M3.9 | 写 `Apps/.../MenuBar/MenuBarController.swift`：创建/销毁 `NSStatusItem`，订阅 ViewModel 余额更新数字（如 `¥38.2`），点击展开 `NSPopover`，响应 hideMenuBarIcon | 文件；编译过 | 55 min | M3.7 |
| M3.10 | 写 `Apps/.../MenuBar/MenuBarContent.swift`：SwiftUI popover 视图：账号列表（label + 余额 + 状态）+ 手动刷新 + 打开主窗口 + 退出 | 文件；编译过 | 35 min | M3.9 |
| M3.11 | 写设置面板：`Apps/.../Features/Settings/SettingsViewModel.swift` + `Apps/.../Features/Settings/SettingsView.swift`，控制刷新频率 Picker（15/30/60/Off）、开机自启 Toggle、隐藏菜单栏图标 Toggle | 2 文件；编译过 | 60 min | M3.4, M3.7, M3.8 |
| M3.12 | 改 `Apps/.../AppBootstrap.swift`：暴露 preferences / alertLedger / notifier / scheduler / loginItem / menuBarController；新增 `RefreshCoordinator` 作为 manual + scheduled 刷新唯一入口 | 编译过；现有 ViewModel 测试不破坏 | 50 min | M3.4-M3.11 |
| M3.13 | 改 `Apps/.../ViewModels/AccountListViewModel.swift`：刷新成功后调用 `LowBalanceNotifier`；新增 `AccountListViewModelTests` 覆盖"刷新触发 notifier" + 既有 3 用例不退化 | xcodebuild test 绿，≥ 4 用例 | 40 min | M3.12 |
| M3.14 | 改 `Apps/TokenScope-macOS/TokenScopeApp.swift`：注册 SwiftUI `Settings` Scene、AppDelegate 启动 `MenuBarController`、应用 `preferences` 到 scheduler/loginItem | App 启动后 Dock + 菜单栏图标同时出现；设置窗口可打开 | 45 min | M3.9, M3.11, M3.12 |
| M3.15 | 改 `Apps/project.yml`：保留 `LSUIElement: false`（v0.1 Dock + 菜单栏并存）；若 SettingsScene 需要新增 Info.plist key 一并补齐；不开 Sandbox（主 App 维持现状） | xcodegen generate 干净；diff 可读 | 20 min | M3.14 |
| M3.16 | 跑最终校验：TSCore / TSProviders / TSStorage / TSDesignSystem tests + xcodebuild build + xcodebuild test + `check-governance.sh` | 全绿 | 30 min | M3.1-M3.15 |
| M3.17 | 用户本机 smoke：① 菜单栏出现余额数字 ② 设置改刷新频率到 15 分钟后看后台日志/控制台 ③ 把阈值调到当前余额 + 1，触发刷新看本机通知 ④ 切开机自启 + 重启 macOS 看 App 自动拉起（unsigned build 失败可接受，记入 mutation log） | 用户口头确认前 3 项必过；第 4 项 best-effort | 30 min | M3.16 |

**预估总和**：约 660 min（≈ 11 小时纯开发）——M3 涉及 4 个新子系统（菜单栏 / 调度 / 通知 / 开机自启）+ 设置面板，单阶段开销最大。

## Risks

- **Risk A：`SMAppService.mainApp.register()` 在 unsigned build 行为不稳**
  - 触发条件：M3.8/M3.11/M3.17 测试开机自启时 register 返回非 success
  - 兜底动作：`LoginItemController` 把 OSStatus / `SMAppServiceStatus` 转成可读错误，`SettingsViewModel` 捕获后通过 alert 显示"开机自启注册失败，请检查 System Settings → General → Login Items"；M3.17 第 4 项允许失败，但需在 Mutation Log 记录现象
- **Risk B：`NSStatusItem` + SwiftUI 在 Swift 6 严格并发模式编译报错**
  - 触发条件：M3.9 build 时报 "non-Sendable type ... in @MainActor"
  - 兜底动作：`MenuBarController` 整体标 `@MainActor`，用 `NSHostingView` 装 `MenuBarContent`；订阅 ViewModel 用 `@Observable`/`withObservationTracking`，不跨 actor 拿引用类型
- **Risk C：`UNUserNotificationCenter` 在 unsigned / Debug build 授权或投递不稳**
  - 触发条件：M3.5 申请授权返回 `notDetermined` 或通知不弹
  - 兜底动作：`LowBalanceNotifier` 先 `getNotificationSettings()`，授权未通过时记录到日志并跳过通知（不影响刷新主路径）；M3.17 第 3 项失败时记入 Mutation Log
- **Risk D：`NSBackgroundActivityScheduler` 实际间隔被系统拉长**
  - 触发条件：用户设置 15 分钟但实际 30+ 分钟才触发
  - 兜底动作：在 `SettingsView` 阈值标签下加副标题"系统会根据负载决定实际间隔"；不试图绕过；M5 README 写清楚
- **Risk E：多入口并发刷新（菜单栏 / 调度器 / 主窗口）导致重入**
  - 触发条件：用户点菜单栏刷新的同时后台调度刚好触发
  - 兜底动作：`RefreshCoordinator` 暴露唯一 `refreshAll()`，内部用 `Task` 串行化或 `isRefreshing` flag 拒绝并发请求；`AccountListViewModel.refreshAll()` 改为转调 coordinator

## Explicitly Not Doing

- 不做 Widget Extension 真实读取 / `WidgetCenter.reloadAllTimelines()` 集成（M4）
- 不切 `LSUIElement = YES`（菜单栏-only 模式留给 M5 决定）
- 不做菜单栏图标自定义 / 主题 / 多账号汇总图表
- 不做通知点击 deeplink 跳账号详情（M4/M5 视情况）
- 不做多账号（PRD v0.1 仅 1 账号，但菜单栏 / 设置 UI 设计预留多账号扩展点）
- 不补 B-019（Decoder DTO）/ B-020（Money 安全 API）/ B-021（public 注释清查），除非顺手低成本触达
- 不引入新第三方依赖
- 不调整 GRDB schema（M3 不需要新增表）

## Definition of Done

与 `processes/active.md` M3_ambient_layer 的 `done_when` 一一映射：

- [ ] `NSStatusItem` 显示余额数字（如 `¥38.2`），点开下拉账号列表 ↔ M3.9, M3.10
- [ ] `BackgroundRefreshScheduler` 30 分钟一次，设置里可改 15/30/60/关闭 ↔ M3.7, M3.11
- [ ] `LoginItemController`（SMAppService）：设置里开关 "开机自启" ↔ M3.8, M3.11
- [ ] `LowBalanceNotifier`：跨越阈值发系统通知 + 24h 去抖 ↔ M3.5, M3.6, M3.13
- [ ] 设置面板：刷新频率、开机自启、隐藏菜单栏图标 ↔ M3.11, M3.14
- [ ] 全部 task 表逐条勾选完成
- [ ] 最终测试 / build / governance check 通过 ↔ M3.16
- [ ] 用户本机 smoke 通过（第 4 项 unsigned 失败可记录）↔ M3.17
- [ ] 用户明确确认

## Mutation Log

执行中改动留痕。规则见 `rules/DEVELOPMENT_PROCESS.md` "Task Plan 前置 · 执行中改动" 段。

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
