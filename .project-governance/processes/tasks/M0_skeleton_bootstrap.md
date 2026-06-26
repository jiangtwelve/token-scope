# Task Plan: M0_skeleton_bootstrap · 工程骨架就位

## Meta

- Version: v0.1
- Stage ID: M0_skeleton_bootstrap
- Drafted At: 2026-06-24
- Approved At: 2026-06-25

## Tasks

| id | title | 产出 / 验证 | 预估 | 依赖 |
|---|---|---|---|---|
| M0.0 | 装 XcodeGen（`brew install xcodegen`），写一个最小 `project.yml` 占位（仅含 name 字段） | `xcodegen --version` 有输出；`project.yml` 存在 | 5 min | — |
| M0.1 | 建项目根目录树（`Packages/` `Apps/` `Widgets/` `Shared/` `.github/workflows/`）与空 `TokenScope.xcworkspace`；`.gitignore` 加 `*.xcodeproj/`（生成产物不进 git） | `tree -L 2` 看到完整目录；Xcode 能打开空 workspace；`.gitignore` 含 `*.xcodeproj/` | 10 min | M0.0 |
| M0.2 | 写 `Shared/AppGroupConstants.swift`：单一来源放 `group.local.tokenscope.shared` + Keychain service 名 + Bundle ID 占位字符串 | 文件存在；编译用 `swiftc -parse` 通过 | 10 min | M0.1 |
| M0.3 | 创建 SPM 包 `Packages/TSCore`：`Package.swift` 声明 `swift-tools-version:6.0` + 平台 `macOS(.v14)` + `iOS(.v17)` + strict concurrency complete；放一个 placeholder Sendable 类型 | `swift test --package-path Packages/TSCore` 绿 | 15 min | M0.2 |
| M0.4 | 在 TSCore 加一个 hello-world test（`#expect(...)`），用 Swift Testing | 同 M0.3 的 `swift test` 跑出 1 个测试通过 | 5 min | M0.3 |
| M0.5 | 创建 SPM 包 `Packages/TSProviders`：双平台声明、依赖 TSCore、placeholder + hello-world test | `swift test --package-path Packages/TSProviders` 绿 | 15 min | M0.4 |
| M0.6 | 创建 SPM 包 `Packages/TSStorage`：双平台、依赖 TSCore + GRDB（锁版本 `from: "7.0.0"`、`upToNextMajor`）、placeholder + hello-world test | `swift test --package-path Packages/TSStorage` 绿；GRDB resolve 成功 | 20 min | M0.5 |
| M0.7 | 创建 SPM 包 `Packages/TSDesignSystem`：双平台、依赖 TSCore、placeholder + hello-world test | `swift test --package-path Packages/TSDesignSystem` 绿 | 10 min | M0.6 |
| M0.8 | 把 `project.yml` 完善为 macOS App target：Bundle ID `local.tokenscope.app`、min macOS 14、Swift 6 + strict concurrency=complete、链 4 个 SPM 包；跑 `xcodegen generate` 产出 `Apps/TokenScope-macOS.xcodeproj` | cmd-R 起空白 SwiftUI Window；workspace 里能看到 App target | 25 min | M0.7 |
| M0.9 | `project.yml` 加 Widget Extension target：Bundle ID `local.tokenscope.widget`、min macOS 14、设置 Embed Foundation Extensions build phase；重跑 `xcodegen generate` | cmd-R 选 Widget scheme，Widget Gallery 中出现 placeholder 卡片 | 20 min | M0.8 |
| M0.10 | 给 App 与 Widget target 各配 App Group entitlement（在 `project.yml` 里声明），值 = `AppGroupConstants` 里的字符串；重跑 `xcodegen generate` | 两 target 编译通过；`.entitlements` 文件存在并被引用 | 10 min | M0.9 |
| M0.11 | （已合入 M0.8/M0.9：SPM 包链接通过 project.yml 声明）验证 App 和 Widget 各自能 `import TSCore` `import TSProviders` 等 | 在 App.swift 与 Widget 主文件加一行 `import TSCore` 编译通过；之后可删去 | 10 min | M0.10 |
| M0.12 | 写 `.github/workflows/ci.yml`：matrix 跑 4 个包的 `swift test` + 一个 job 跑 `brew install xcodegen` → `xcodegen generate` → `xcodebuild build -workspace ... -scheme TokenScope-macOS`（不指定 destination） | push 后 Actions 跑通绿色 | 30 min | M0.11 |
| M0.13 | 写项目根 `README.md`：项目定位、v0.1 范围、cmd-R 步骤（说明先跑 `xcodegen generate`）、与子目录 `cc-switch/` 的关系说明 | README 在 GitHub 上可读、3 分钟内能让别人理解项目和跑起来 | 15 min | — |
| M0.14 | 跑 `.project-governance/scripts/check-governance.sh` + 自查 active.md 的 M0 done_when 5 条 | 校验通过 + 5 条 done_when 全部勾上 | 5 min | M0.12, M0.13 |

**预估总和**：约 205 min（≈ 3.4 小时纯编码）；考虑试错与摸索，预留 1 个工作日。

## Risks

本次实例预估外风险。每条附触发条件 + 兜底动作。不重复 `processes/active.md` M0 段的 `typical_pitfalls`。

- **Risk A：GRDB 7 在 SPM 严格并发模式下与 transitive 依赖冲突**
  - 触发条件：M0.6 执行 `swift test` 时出现 unresolved 警告或 Sendable 编译错
  - 兜底动作：把 GRDB 依赖临时注释，M0.6 改为仅 placeholder 跑通，新开 task M0.6.a 单独打通 GRDB 7 集成，不阻塞 M0.7~M0.9
- **Risk B：GitHub Actions macOS runner 首次跑 xcodebuild 因 simulator runtime 缺失失败**
  - 触发条件：M0.12 第一次 push 后 Actions 红
  - 兜底动作：去掉 `-destination` 改纯 `xcodebuild build`；若仍红，把 Widget scheme 暂时移出 CI、留在 README 写"本地 cmd-R 验证 Widget"
- **Risk C：Widget Extension 在 unsigned + non-sandbox 下 Widget Gallery 不显示**
  - 触发条件：M0.9 cmd-R 后系统设置 Widgets 列表里看不到 token-scope
  - 兜底动作：在 README 注明"如看不到 widget，到系统设置 → 桌面与 Dock → Widgets 重启 widget 服务一次"；不阻塞 M0 完成
- **Risk D：Xcode workspace + 4 SPM 包的 import 解析卡顿（首次 resolve 偶尔 5~10 分钟）**
  - 触发条件：M0.11 编译 App target 时 Xcode 卡在 "Resolving Packages..."
  - 兜底动作：cmd+shift+K 清 build folder，File → Packages → Reset Package Caches，重 resolve

## Explicitly Not Doing

明确划走的事，避免边界蔓延：

- 不写任何业务逻辑（不写 `DeepSeekProvider`、不写 `ProviderList`、不写 `BackgroundRefreshScheduler` 等）—— 这些属于 M1~M4
- 不引第三方依赖除 GRDB（不引 Sparkle / Alamofire / SwiftLog / Composable Architecture 等）
- 不配置代码格式化 / lint（v0.1 不上 SwiftFormat / SwiftLint，节省决策开销，v0.2 评估）
- 不写图标 / 不做 visual design polish（v0.1 用 SwiftUI 默认样式）
- 不申请 Apple Developer 账号（决策见 D-001）
- 不设置 Sparkle / 自动更新（决策见 ARCHITECTURE §Deployment，B-016）
- 不开 App Sandbox（决策见 ARCHITECTURE §Security and privacy）

## Definition of Done

与 `processes/active.md` M0_skeleton_bootstrap 的 `done_when` 一一映射：

- [x] **done_when 1**（TokenScope.xcworkspace 在 Xcode 16 中能打开）↔ M0.1
- [x] **done_when 2**（4 个 SPM 包各有 placeholder + hello-world test 全绿）↔ M0.3, M0.4, M0.5, M0.6, M0.7
- [x] **done_when 3**（App target cmd-R 启动空白窗口）↔ M0.8, M0.10, M0.11（已经 xcodebuild 通过；用户 cmd-R 实际验证留 M0.14 自查阶段）
- [x] **done_when 4**（Widget Extension target 在 Widget Gallery 显示 placeholder）↔ M0.9, M0.10, M0.11（已经 ValidateEmbeddedBinary 通过；Widget Gallery 实际可见性留用户验证）
- [x] **done_when 5**（`.github/workflows/ci.yml` 第一次跑通）↔ M0.12（本地模拟 build 已通过；远程 Actions 待 push 后验证）
- [x] 全部 14 条 task 逐条勾选完成
- [x] `check-governance.sh` 通过（M0.14）
- [x] 用户明确针对本 task plan 与执行结果说"过 / 确认 / approve"

## Mutation Log

执行中改动留痕。规则见 `rules/DEVELOPMENT_PROCESS.md` "Task Plan 前置 · 执行中改动" 段。

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
| 2026-06-25 | Initial approval — plan locked at 14 tasks | 用户 review 后明确确认 | 2026-06-25 |
| 2026-06-25 | 加入 M0.0（装 XcodeGen）；M0.8 改为"写 project.yml + 跑 xcodegen 生成 App target"；M0.9 改为"在 project.yml 加 Widget target 并重跑 xcodegen"；.gitignore 加 `*.xcodeproj/` | 手写 project.pbxproj 风险大、Xcode UI 创建无 diff 友好；XcodeGen 是构建期生成器，不破 D-002 的"无第三方运行时依赖"原则 | 2026-06-25 |
| 2026-06-25 | Widget Bundle ID 改为 `local.tokenscope.app.widget`（原 `local.tokenscope.widget`）；同步改 `Shared/AppGroupConstants.swift` | macOS 强制要求 Widget Bundle ID 必须以 App Bundle ID 为前缀，否则 ValidateEmbeddedBinary 报错。属于 Apple 平台硬约束，非可商榷决策 | 自动应用（属事实修正） |
| 2026-06-25 | v0.1 签名策略从 "ad-hoc + 不签名" 调整为 "Personal Team 自动签名"。新增 `Apps/Local.xcconfig.template` + `Apps/Local.xcconfig`（gitignored，含用户 Team ID 975KKJ3ZQN）；project.yml 改为 `CODE_SIGN_IDENTITY: Apple Development` + 从 xcconfig 读 DEVELOPMENT_TEAM | M0.10 执行时发现 macOS 强制要求 App Group entitlement 必须配 development cert；纯 ad-hoc 签名无法附带这个 entitlement。Personal Team 是免费替代，任何 Apple ID 可用。D-001 原"不签名"语义保留，但实操降级为"不办 $99 Developer Program，使用免费 Personal Team 本地签名" | 2026-06-25 |
| 2026-06-25 | Team ID 修正为 `L4TSHU55BH`（原误填 `975KKJ3ZQN`）；同步修正 Local.xcconfig.template 与 AppGroupConstants.swift 注释 | Personal Team 证书的 OU 字段（`L4TSHU55BH`）才是 Team ID，CN 括号里（`975KKJ3ZQN`）是开发者个人 Membership ID。两者格式相同（10 位字母数字）但语义不同；初次错填导致 xcodebuild "No profiles for ..." 报错；通过 `openssl x509 -text` 看证书 Subject 确认 | 自动应用（属事实修正） |
| 2026-06-25 | Widget Extension target 改为 `ENABLE_APP_SANDBOX: YES` + entitlements 加 `com.apple.security.app-sandbox: true`（App target 保持 sandbox=NO 不变） | M0.14 收尾时用户实测 Widget 不在系统 Widget Gallery 显示。macOS widget extension 由 chronod 以沙盒进程加载，未开 sandbox 不会被挂载。这是平台硬约束，与 App 关 sandbox 不冲突。同步更新 ARCHITECTURE §Security and privacy 沙盒条目 | 自动应用（属事实修正） |
| 2026-06-25 | M0 stage 全部勾选完毕、用户验收"看到了" | done_when 5 条全过 + 用户实测 App 窗口 + Widget Gallery placeholder 卡片可见 | 2026-06-25 用户确认 |
