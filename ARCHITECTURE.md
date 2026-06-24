# AIModelMonitor 架构文档

> 本文档是技术方案（How）的唯一信息来源。代码实现以此为准。
> 与 PRD 冲突时，以本文件为准；本文件与 DECISIONS.md 冲突时，以 DECISIONS.md 为准。

---

## 1. 技术栈

| 层 | 技术 |
|---|---|
| UI | SwiftUI（macOS 12+） |
| 菜单栏 | AppKit（NSStatusItem + NSPopover） |
| 桌面 Widget | WidgetKit（supportedFamilies: small / medium / large） |
| 网络请求 | URLSession（async/await） |
| 并发 | Swift Concurrency（TaskGroup / async let） |
| 存储 | Keychain Sharing / App Group UserDefaults / 共享 JSON 文件 |
| 本地化 | .strings 文件（zh-Hans / en） |
| 分发 | Xcode Archive → Developer ID 签名 → Notarization → DMG |

---

## 2. 模块划分

```
AIModelMonitor.xcodeproj
├── AIModelMonitor/                # 主 App target（macOS）
│   ├── App/
│   │   ├── AIModelMonitorApp.swift       # @main
│   │   └── AppDelegate.swift             # NSApplicationDelegate
│   ├── Features/
│   │   ├── Dashboard/                     # 首页模型卡片
│   │   ├── ModelManagement/              # 添加/删除/校验模型
│   │   └── Settings/                     # 设置页
│   ├── MenuBar/
│   │   ├── MenuBarManager.swift          # NSStatusItem 生命周期
│   │   └── MenuBarPopoverView.swift      # 下拉框 SwiftUI View
│   └── Resources/
│       ├── Assets.xcassets
│       ├── zh-Hans.lproj
│       └── en.lproj
│
├── AIModelMonitorWidget/          # Widget Extension target
│   ├── Provider/
│   │   ├── TimelineProvider.swift         # TimelineProvider 实现
│   │   └── WidgetEntry.swift              # TimelineEntry 定义
│   ├── Views/
│   │   ├── SmallWidgetView.swift
│   │   ├── MediumWidgetView.swift
│   │   └── LargeWidgetView.swift
│   └── Intents/
│       └── ModelSelectionIntent.swift    # AppIntent 配置
│
├── Shared/                        # 两个 target 共用（代码共享）
│   ├── Models/
│   │   ├── ModelUsage.swift               # 统一用量数据模型
│   │   ├── ProviderType.swift             # Provider 枚举
│   │   └── Status.swift                   # 状态枚举
│   ├── Providers/
│   │   ├── ProviderProtocol.swift         # Provider 协议
│   │   ├── DeepSeekProvider.swift
│   │   ├── SiliconFlowProvider.swift
│   │   ├── OpenRouterProvider.swift
│   │   ├── KimiProvider.swift
│   │   ├── GLMProvider.swift
│   │   └── CustomProvider.swift
│   ├── Storage/
│   │   ├── KeychainStore.swift            # Keychain 读写（API Key）
│   │   ├── SharedDefaults.swift           # App Group UserDefaults（元数据/偏好）
│   │   └── CacheStore.swift               # 共享 JSON 缓存（最新用量数据）
│   ├── Networking/
│   │   └── APIClient.swift                # 统一 HTTP 客户端
│   └── Extensions/
│       ├── Color+Brand.swift              # Provider 品牌色
│       └── Date+Relative.swift            # 时间格式化
│
└── Tests/                          # 单元测试 target
    ├── ProviderTests/                     # 各 Provider 适配器测试
    └── StorageTests/                      # Keychain / 缓存测试
```

---

## 3. 数据流

### 3.1 App 运行中（菜单栏存活）

```
┌───────────────────────────────────────────────┐
│  DataManager（主 App 进程）                      │
│                                                │
│  定时任务：按用户设定频率（默认 30s）触发          │
│  ┌─────────────────────────────────────────┐  │
│  │ TaskGroup 并发:                          │  │
│  │  ├─ DeepSeekProvider.fetchUsage()       │  │
│  │  ├─ SiliconFlowProvider.fetchUsage()    │  │
│  │  ├─ ... 所有已配置模型                   │  │
│  │  └─ 每个请求 ≤ 5s 超时                  │  │
│  │                                         │  │
│  │  → 聚合为 [String: ModelUsage]          │  │
│  │  → CacheStore.save(results)             │  │
│  │  → WidgetCenter.shared.reloadAllTimelines()│  │
│  └─────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
         ↓ 写入                ↓ 通知重绘
    App Group 共享         Widget Extension
    JSON 文件              → 读 CacheStore
                          → 按配置过滤
                          → 渲染 Widget
```

### 3.2 App 退出后

```
系统按 TimelineProvider 调度唤醒 Widget Extension
  → TimelineProvider.timeline(...)
    → 1. CacheStore.read() 读缓存
    → 2. 缓存 < 5 分钟 → 直接用，不发网络请求
    → 3. 缓存过期 → 只请求"这个 Widget 显示的模型"
       - systemSmall: 1 个请求
       - systemMedium: ≤4 个请求（并发）
       - systemLarge: ≤10 个请求（并发，5s 超时）
    → 4. 成功 → 写入 CacheStore + 渲染
    → 5. 失败 → 用旧数据 + stale 标记
```

### 3.3 用户主动操作

```
打开 App → DataManager.refreshAll() → 同 3.1
长按 Widget 编辑 → AppIntent 保存配置 → 下次 timeline 按新配置渲染
```

---

## 4. 核心抽象

### 4.1 ModelUsage（统一数据模型）

```swift
/// Widget 和 App 之间唯一的用量数据传递类型。
/// 所有 Provider 返回的数据在 DataManager 层统一映射为此类型。
struct ModelUsage: Codable {
    let modelId: String                    // 全局唯一
    let displayName: String
    let brandColorHex: String              // 用于 Widget 强调色

    // 主数字（Widget 上的核心显示）
    let primaryValue: Double               // 百分比 0-100, 或余额数字
    let primaryKind: PrimaryKind            // .percentage / .balance
    let unit: String?                       // "USD" / "Credits" / "%"

    // 副信息
    let resetAt: Date?                      // 配额重置时间（仅 CodingPlan）
    let updatedAt: Date                     // 数据获取时间

    // 完整原始数据（App / 菜单栏下拉框用）
    let detailFields: [DetailField]         // 名称-值对列表

    let status: UsageStatus                 // .ok / .stale / .deleted
}

enum PrimaryKind: String, Codable {
    case percentage     // 0-100, Widget 显示 "+进度条"
    case balance        // 金额/积分数, Widget 显示 "数字+单位"
}

enum UsageStatus: String, Codable {
    case ok             // 数据新鲜
    case stale          // 数据过期
    case deleted        // 模型已被删除
}

struct DetailField: Codable, Identifiable {
    let id = UUID()
    let label: String
    let value: String
}
```

### 4.2 ProviderProtocol（Provider 适配器接口）

```swift
protocol ProviderProtocol {
    associatedtype ProviderConfiguration

    /// Provider 类型标识
    var type: ProviderType { get }
    
    /// 默认 baseURL（预设 Provider 固定，自定义 Provider 由用户填写）
    var defaultBaseURL: URL? { get }

    /// 校验 API Key 是否有效。
    /// - 抛出 ProviderError.invalidKey（401/403）
    /// - 抛出 ProviderError.networkError（超时/无网络）
    /// - 抛出 ProviderError.unexpectedResponse（格式不对）
    func validate(apiKey: String, baseURL: URL?) async throws

    /// 获取最新用量数据。
    func fetchUsage(apiKey: String, baseURL: URL?) async throws -> ModelUsage
}

enum ProviderType: String, Codable, CaseIterable {
    case deepseek
    case siliconflowCN          // https://api.siliconflow.cn
    case siliconflowCOM         // https://api.siliconflow.com
    case openrouter
    case kimi
    case glmCN                  // https://open.bigmodel.cn
    case glmZAi                 // https://api.z.ai
    case custom                 // 用户自定义
}

enum ProviderError: Error, LocalizedError {
    case invalidKey(String)           // 401/403
    case networkError(Error)          // 超时/无网络
    case unexpectedResponse(String)   // 响应格式不对
    case rateLimited(Date?)           // 限流
}
```

### 4.3 刷新策略

```
App 运行（菜单栏存活）:
  defaultInterval: 30s
  configurableRange: [10s, 5min]  (用户设置可调)
  scope: 所有已配置模型（并发）
  timeoutPerRequest: 15s
  failure: 个体失败 → 该模型保留旧数据 + stale 标记
          整体失败 → 不做任何动作（下次重试）

App 退出后（Widget 自刷新）:
  systemDefaultInterval: ~15min (由系统决定)
  scope: 仅当前 Widget 显示的模型
  cacheTTL: 5min（缓存新鲜则不发请求）
  timeoutPerRequest: 5s
  totalWidgetBudget: 15s（超时则降级用旧数据）
  
用户强制:
  打开 App → DataManager.refreshAll() → reloadAllTimelines()
```

**超时数值是全项目唯一信息来源**。`CLAUDE.md §5.7` 和 `PROVIDERS.md` 中的超时表述均引用本节，不重复定义。

---

## 5. 存储方案

| 数据 | SSOT | 存储机制 | 访问路径 |
|---|---|---|---|
| API Key | Keychain | `SecItemAdd` / `SecItemCopyMatching` | Access group 两边共享 |
| 模型元数据 | App Group UserDefaults | `UserDefaults(suiteName: "group.xxx")` | 主 App 写，双方读 |
| 用户偏好 | App Group UserDefaults | 同 UserDefaults | 主 App 写，双方读 |
| 缓存数据 | App Group JSON 文件 | `FileManager.containerURL(forSecurityApplicationGroupIdentifier:)` + JSON 序列化 | DataManager 写，双方读 |

### Keychain Access Group 配置

```
Keychain Access Group: <TEAM_ID>.group.com.aimodelmonitor.shared
App Group ID: group.com.aimodelmonitor.shared
```

（具体 TEAM_ID 在注册 Apple Developer 后填入）

### 缓存 JSON 结构

```json
{
  "lastUpdated": "2026-06-23T14:30:00Z",
  "models": {
    "deepseek-main": {
      "displayName": "DeepSeek",
      "primaryValue": 12.50,
      "primaryKind": "balance",
      "unit": "USD",
      "resetAt": null,
      "updatedAt": "2026-06-23T14:30:00Z",
      "detailFields": [
        {"label": "总额度", "value": "$100.00"},
        {"label": "已使用", "value": "$87.50"},
        {"label": "可用余额", "value": "$12.50"}
      ],
      "status": "ok"
    },
    "kimi-coding": {
      ...
    }
  }
}
```

---

## 6. Widget 配置（AppIntent）

```swift
struct ModelSelectionIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "选择模型"
    
    @Parameter(title: "显示模型", optionsProvider: ModelOptionsProvider())
    var selectedModels: [String]  // modelId 数组
}
```

`ModelOptionsProvider` 从 App Group UserDefaults 读取已配置模型列表。

---

## 7. 视觉设计约定

- **基底**：`Material.ultraThinMaterial`（玻璃拟态，Widget）
- **强调色**：每个 Provider 的品牌色（定义在 `Color+Brand.swift`）
- **字号**：
  - Widget Small：主数字 28pt Bold，副文本 11pt
  - Widget Medium：主数字 20pt Bold，副文本 10pt
  - Widget Large：主数字 17pt Bold，副文本 10pt
- **圆角**：`containerRelativeFrame` + 系统标准圆角
- **深色/浅色**：自动跟随系统
- **动画**：`contentTransition(.numericText())` 数字变化

---

## 8. Xcode 配置要点

### 8.1 证书与 Capabilities

| Capability | 用途 | Target |
|---|---|---|
| App Groups | 共享组 `group.com.aimodelmonitor.shared` | 主 App + Widget |
| Keychain Sharing | Access group `<TEAM_ID>.group.com.aimodelmonitor.shared` | 主 App + Widget |
| Hardened Runtime | 公证要求 | 主 App |

### 8.2 最低版本

- macOS 12.0 Monterey（第一个支持桌面 WidgetKit 的版本）

### 8.3 签名

- Developer ID Application（分发用）
- Xcode 自动管理签名（v1.0 阶段）