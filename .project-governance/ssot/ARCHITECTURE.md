# Architecture

技术架构、模块边界、数据模型和部署约束的 SSOT。任何架构变化都必须更新本文件并留痕。

- Status: confirmed   （允许值：`draft` / `confirmed` / `superseded`）

## Change History

`Version` 列填项目版本号（如 `v1.0`、`v1.1`），与 `ssot/PROJECT_STATE.md` 的 `Versions` 段对应。

| Date | Version | Change | Reason | Decision |
|---|---|---|---|---|
| 2026-06-24 | v0.1 | 初始草稿：SwiftUI + WidgetKit + GRDB + Keychain；UsageProvider 协议；App Group 共享 SQLite | 仅 macOS + 单家供应商 + 0 后端的 MVP 形态推导 | Pending second-stage confirmation |
| 2026-06-24 | v0.1 | 第二段技术栈确认完成：分发改"仅本机+开源代码"、Workspace+4 SPM 包、GRDB 7+Swift 6 严格并发、SPM 声明双平台、本机后台菜单栏常驻 | 收口本段全部 Open Questions；详见 decisions/D-001~D-005 | Confirmed by user |
| 2026-06-25 | v0.1 | Tech stack 加一行 "XcodeGen 生成 xcodeproj"；`*.xcodeproj/` 不进 git | M0.8/M0.9 执行前发现 xcodeproj 创建需借助工具，相比手写 pbxproj 与 Xcode UI 更利于 diff/review | Confirmed by user，详见 tasks/M0_skeleton_bootstrap.md Mutation Log |

## Content

### Technical goals

1. **可平移**：v0.2/v0.3 把 cc-switch 其他供应商搬过来时，每家 ≤ 1 个文件、≤ 100 行、零框架改动。
2. **可跨端**：v0.1 仅 macOS，但 `TSCore` / `TSProviders` / `TSStorage` 三个 Swift Package v0.2 上 iOS 时零改动复用；4 个 SPM 包从 v0.1 起即声明 macOS + iOS 双平台。
3. **Widget 永不联网**：硬约束。所有网络在主 App，Widget 只读 App Group SQLite。
4. **零密钥泄漏**：apiKey 仅在 Keychain；主数据库、日志、内存日志均不含明文。
5. **数据并发安全编译期保证**：Swift 6 严格并发模式启用，UsageProvider / SnapshotStore / SecretStore 全部 `Sendable`，跨进程读写在 actor 内隔离。

### Tech stack

| 层 | 选型 | 替代 | 选这个的原因 |
|---|---|---|---|
| 语言 / UI | Swift 6.0+ / SwiftUI / WidgetKit | RN / Flutter / Tauri / Electron | iOS Widget 唯一原生路径；macOS 同源复用 |
| 并发模式 | Swift 6 strict concurrency = complete | Swift 5 minimal | 编译期捕获 data race；上线后翻补成本远高 |
| HTTP | URLSession（标准库） | Alamofire / AsyncHTTPClient | 0 第三方依赖，Widget 二进制最小 |
| 持久化 | GRDB.swift 7.x | SwiftData / CoreData / GRDB 6 | 7.x 原生 async/await + observation v2，与 Swift 6 适配最佳 |
| 密钥 | Security.framework Keychain（kSecAttrAccessGroup） | UserDefaults / 文件 | 系统级安全，跨进程共享 |
| 菜单栏 | NSStatusItem + SwiftUI（NSHostingView） | 仅 Dock 图标 | S1 高频痛点要 ambient |
| 后台运行 | 菜单栏常驻 + ServiceManagement Login Item（开机自启）| LaunchAgent / 自起进程 | 简单、无需 root；Quit 即停止刷新（已与用户确认权衡） |
| 后台刷新调度 | NSBackgroundActivityScheduler（在主 App 进程内） | LaunchAgent 拉起独立进程 | 仅在 App 运行时调度，配合"开机自启 + 菜单栏常驻"覆盖 95% 场景 |
| 包管理 | Swift Package Manager | CocoaPods | 标准默认 |
| 工程组织 | TokenScope.xcworkspace + 4 个 SPM 包 + App.xcodeproj + Widget Extension target | 单 xcodeproj / Tuist | SPM 包可独立 `swift test`、强制分层；详见 decisions/D-002 |
| xcodeproj 生成 | XcodeGen（声明式 `project.yml` → 生成 .xcodeproj，非运行时依赖） | 手写 pbxproj / Tuist / Xcode UI | 可 diff / 可 review；`*.xcodeproj/` 不进 git。详见 decisions/D-002 的 Mutation Log 与 tasks/M0_skeleton_bootstrap.md Mutation Log |
| 测试 | Swift Testing（Xcode 16+） + URLProtocol mock | XCTest | 表驱动 Provider 单测最自然 |
| CI | GitHub Actions（macOS runner）：swift test SPM 包 + xcodebuild build App/Widget | 无 CI | 开源仓库贡献者 PR 可被自动验证 |
| 分发 | **v0.1**：仅本机 xcodebuild + GitHub 开源代码；不发 DMG | Developer ID DMG / TestFlight | v0.1 验证池子是作者本人，无需签名公证；v0.2 再上 Developer ID。Bundle ID 前缀用 `local.` 占位（如 `local.tokenscope.app`），上 Developer ID 后改为正式反域名 |

### System overview

```
┌──────────────────────────────────────────────────────────────┐
│                     macOS App（主进程）                       │
│                  ▶ 开机随 ServiceManagement 拉起             │
│                  ▶ 菜单栏常驻 NSStatusItem                   │
│  ┌────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ MenuBar    │  │ Main Window      │  │ Background       │  │
│  │ (NSStatus) │  │ (Provider 列表 / │  │ Scheduler        │  │
│  │            │  │  编辑 / 设置)    │  │ (30 min, 仅 App   │  │
│  │            │  │                  │  │  运行时)          │  │
│  └─────┬──────┘  └────────┬─────────┘  └────────┬─────────┘  │
│        └─────────────────┬┴─────────────────────┘            │
│                          │ 触发                              │
│           ┌──────────────▼──────────────┐                    │
│           │ RefreshAllAccountsUseCase   │                    │
│           └──────────────┬──────────────┘                    │
│                          │                                    │
│           ┌──────────────▼──────────────┐                    │
│           │ TSProviders                  │                   │
│           │  └─ DeepSeekProvider (v0.1) │                    │
│           └──────────────┬──────────────┘                    │
│                          │ UsageResult                       │
│           ┌──────────────▼──────────────┐                    │
│           │ GRDBSnapshotStore (write)   │                    │
│           │  GRDB 7 + actor isolation   │                    │
│           └──────────────┬──────────────┘                    │
│                          │ WidgetCenter.reloadAllTimelines() │
└──────────────────────────┼───────────────────────────────────┘
                           │
       ┌───────────────────▼──────────────────────┐
       │ App Group 容器                            │
       │ ~/Library/Group Containers/              │
       │   group.local.tokenscope.shared/         │
       │     Library/Application Support/         │
       │       snapshots.sqlite                   │
       │ Keychain Access Group:                   │
       │   $(AppIdentifierPrefix)local.tokenscope.shared │
       │   （v0.2 上 Developer ID 后替换前缀）    │
       └───────────────────┬──────────────────────┘
                           │ read-only
       ┌───────────────────▼──────────────────────┐
       │ Widget Extension（独立进程，无网络权限） │
       │   TimelineProvider 读 SQLite             │
       │   渲染 systemMedium 卡片                 │
       └──────────────────────────────────────────┘
```

### Module boundaries

```
TokenScope/                              ← Workspace 根
├── Packages/                            ← 4 个独立 SPM 包，均 macOS 14+iOS 17 双平台
│   ├── TSCore/                          [纯 Swift, 0 依赖]
│   │   ├── Package.swift                平台：macOS(.v14), iOS(.v17)
│   │   ├── Sources/TSCore/
│   │   │   ├── Models/
│   │   │   │   ├── Provider.swift       Provider 元数据（id, displayName, defaultBaseURL）
│   │   │   │   ├── Account.swift        (id, providerID, label, baseURL, thresholdCNY)
│   │   │   │   ├── UsageSnapshot.swift  一比一对齐 cc-switch UsageData，Sendable
│   │   │   │   ├── UsageResult.swift    三态枚举：success/failure/invalid，Sendable
│   │   │   │   └── Money.swift          Decimal + ISO 币种，Sendable
│   │   │   ├── UseCases/
│   │   │   │   ├── RefreshAllAccountsUseCase.swift
│   │   │   │   └── DetectLowBalanceUseCase.swift
│   │   │   └── Protocols/
│   │   │       ├── UsageProvider.swift  Sendable 协议
│   │   │       ├── SnapshotStore.swift  Sendable 协议
│   │   │       └── SecretStore.swift    Sendable 协议
│   │   └── Tests/TSCoreTests/           Swift Testing 单测
│   │
│   ├── TSProviders/                     [v0.1 只 DeepSeek]
│   │   ├── Package.swift                依赖 TSCore；双平台
│   │   ├── Sources/TSProviders/
│   │   │   ├── DeepSeekProvider.swift   ~80 行
│   │   │   ├── DeepSeekResponseDecoder.swift  解码独立便于单测
│   │   │   └── ProviderRegistry.swift   id → factory 注册表
│   │   └── Tests/TSProvidersTests/      Decoder 表驱动单测（含 API_CONTRACT 9 用例）
│   │
│   ├── TSStorage/                       [GRDB 7 + Keychain]
│   │   ├── Package.swift                依赖 TSCore + GRDB；双平台
│   │   ├── Sources/TSStorage/
│   │   │   ├── GRDBSnapshotStore.swift  实现 SnapshotStore，actor
│   │   │   └── KeychainSecretStore.swift  实现 SecretStore
│   │   └── Tests/TSStorageTests/        smoke：临时 sqlite 写读
│   │
│   └── TSDesignSystem/                  [SwiftUI tokens + 共用组件]
│       ├── Package.swift                双平台（v0.2 上 iOS 时复用）
│       └── Sources/TSDesignSystem/
│           ├── Tokens/                  Color / Spacing / Typography
│           └── Components/              BalanceCard / StatusBadge
│
├── Apps/
│   └── TokenScope-macOS.xcodeproj
│       └── TokenScope/
│           ├── App.swift                @main, Scene 注册
│           ├── Features/
│           │   ├── ProviderList/        主窗口账号列表
│           │   ├── ProviderEditor/      新增/编辑账号弹窗
│           │   ├── MenuBar/             NSStatusItem + SwiftUI 菜单
│           │   └── Settings/            刷新频率 / 阈值 / 语言 / 开机自启开关
│           ├── Background/
│           │   ├── BackgroundRefreshScheduler.swift   NSBackgroundActivityScheduler
│           │   └── LoginItemController.swift          SMAppService 注册/反注册
│           └── Notifications/
│               └── LowBalanceNotifier.swift           UserNotifications + 24h 去抖
│
├── Widgets/                             ← 与 App.xcodeproj 同 project，独立 target
│   └── TokenScopeWidget-macOS/
│       ├── BalanceWidget.swift          @main, Widget 入口
│       ├── BalanceTimelineProvider.swift  读 GRDB
│       └── Views/BalanceMediumView.swift
│
├── Shared/
│   └── AppGroupConstants.swift          group.local.tokenscope.shared
│
└── .github/workflows/
    └── ci.yml                           swift test + xcodebuild build
```

依赖方向（严格单向）：

```
Apps ─┐
       ├─→ TSProviders ─┐
Widget ┘                 ├─→ TSCore
       └─→ TSStorage ────┘
       └─→ TSDesignSystem ─→ TSCore（仅类型，不依赖运行时）
```

`TSCore` 永远不 import 任何 framework 之外的东西，保证可移植与可测试。

### Data model

**Account 表（GRDB）**

| 字段 | 类型 | 说明 |
|---|---|---|
| id | TEXT (UUID) | 主键 |
| providerID | TEXT | "deepseek" |
| label | TEXT | 用户起的名字，如"主账号" |
| baseURL | TEXT | 默认 `https://api.deepseek.com` |
| thresholdCNY | DECIMAL | 低余额告警阈值，默认 10 |
| createdAt | DATETIME | |
| updatedAt | DATETIME | |

注：**apiKey 不在此表**，存于 Keychain，key = `tokenscope.account.<id>.apiKey`。

**UsageSnapshot 表（GRDB）**

| 字段 | 类型 | 说明 |
|---|---|---|
| id | INTEGER | 自增主键 |
| accountID | TEXT | FK → Account.id |
| providerID | TEXT | |
| fetchedAt | DATETIME | 拉取时间 |
| status | TEXT | "success" / "failure" / "invalid" |
| planName | TEXT? | 对齐 cc-switch `plan_name`（DeepSeek 这里放 currency 如 "CNY"） |
| remaining | DECIMAL? | 对齐 cc-switch `remaining` |
| unit | TEXT? | ISO 币种，"CNY" / "USD" |
| isValid | BOOL? | 对齐 cc-switch `is_valid` |
| invalidMessage | TEXT? | 失效原因文案 |
| errorMessage | TEXT? | failure 时填 |

**保留策略**：每账号只保留最近 7 天快照（v0.1 用不上历史，但留窗口给低成本统计）；启动时清理过期。

### Security and privacy

| 关注点 | 措施 |
|---|---|
| apiKey 存储 | macOS Keychain，`kSecAttrAccessGroup` = App Group |
| apiKey 传输 | 仅 HTTPS；URLSession 默认 ATS 限制 |
| 数据库加密 | v0.1 不加密 SQLite（不存 apiKey）；v1.0 上 App Store 时考虑 SQLCipher |
| 日志 | apiKey 任何场合不出现在日志；网络错误日志只记录 URL host 而非完整 URL |
| 沙盒 | v0.1 App target **不开** App Sandbox（本机跑无审核要求；菜单栏常驻 + 后台刷新 + 自更新路线在 sandbox 下受限，留 v0.2 上 Developer ID 时统一开启）；**Widget Extension 必须开 sandbox**（macOS 平台硬约束：widget 由 chronod 以沙盒进程加载，未开 sandbox 不会被 Widget Gallery 挂载） |
| 崩溃上报 | v0.1 不接 Sentry；如接需保证 apiKey 不进 breadcrumb |
| 公证 | v0.1 不公证（本机 + 开源代码）；v0.2 上 Developer ID 后必须公证 |

### Deployment

- **v0.1**：
  - 仅本机 xcodebuild Run；不分发；不发 DMG
  - 代码开源到 GitHub（公开仓库），README 给出"自行 Clone + 在 Xcode 打开 + Run"的步骤
  - Bundle ID：`local.tokenscope.app` / `local.tokenscope.widget`（占位，v0.2 切正式反域名）
  - 自启：用户首次 Run 后在 App 设置里勾选"开机自启"，由 SMAppService 注册 Login Item
- **v0.2（前瞻）**：
  - 申请 Apple Developer 账号
  - 替换 Bundle ID 前缀为正式反域名（如 `io.github.<you>.tokenscope`）
  - Developer ID 签名 + Apple notarization
  - GitHub Release + DMG（create-dmg）
  - 评估 Sparkle 2 内建更新

### Other constraints

- 最低系统：macOS 14.0（桌面 Widget 系统门槛）
- 最低 Xcode：16.0（Swift Testing + Swift 6）
- 最低 Swift：6.0
- 二进制目标：universal（arm64 + x86_64）
- 包大小目标：本地 build 产物 < 30 MB（v0.1 不打 DMG，无 DMG 大小约束）

### Open questions

- 全部 v0.1 Open Questions 已在第二段技术栈确认中收口。新增问题待第三段开发中按追问协议处理后归档到 decisions/。
