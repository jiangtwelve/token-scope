# Token Scope

让用 `baseURL + apiKey` 接入多家 LLM 的用户，在 macOS 桌面 / 菜单栏 / Widget 上一眼看见每家账号的余额与可用状态——无需打开任何后台网页。

> 一句话：**"cc-switch 管你切，token-scope 管你看。"**

---

## 当前状态

- **版本**：v0.1（开发中）
- **平台**：仅 macOS 14+
- **首发供应商**：DeepSeek 一家
- **形态**：菜单栏 App + 桌面 Widget + 通知中心 Widget
- **分发**：仅本机 cmd-R 运行 + 开源代码；**不发 DMG、不上 TestFlight**

v0.1 的验证对象是作者本人（7 天连续使用看 H0 是否成立）。如果你不是作者本人，能 cmd-R 跑起来就行，但功能没经过广泛测试。

完整范围、路线图、决策追溯见 [`.project-governance/`](.project-governance/AGENT_BOOTSTRAP.md)。

---

## 先决条件

| 工具 | 版本 |
|---|---|
| macOS | 14.0+（桌面 Widget 系统门槛） |
| Xcode | 16.0+（Swift Testing + Swift 6） |
| Apple ID | 任何 Apple ID，本机登录后免费 Personal Team 即可（**不需要 $99/年 Developer Program**） |
| Homebrew | 任意近期版本 |
| XcodeGen | `brew install xcodegen` |

---

## 第一次跑起来（cmd-R）

```bash
git clone <this repo>
cd token-scope

# 1. 装 XcodeGen（若未装）
brew install xcodegen

# 2. 在 Xcode 里登录你的 Apple ID
#    Xcode → Settings → Accounts → "+" → Apple ID
#    （登录后会自动获得 Personal Team，免费、无需付费订阅）

# 3. 配置本机 Team ID
cp Apps/Local.xcconfig.template Apps/Local.xcconfig
# 用编辑器打开 Apps/Local.xcconfig，把 DEVELOPMENT_TEAM 改为你的 Team ID
# （查 Team ID 的方法见 Apps/Local.xcconfig.template 注释）

# 4. 生成 xcodeproj
cd Apps && xcodegen generate && cd ..

# 5. 打开 workspace 并 cmd-R
open TokenScope.xcworkspace
```

**首次在 Xcode 里 cmd-R 之前**：选 `TokenScope-macOS` target → Signing & Capabilities → 设置 Team 为你的 Personal Team。同样对 `TokenScopeWidget-macOS` 设一次。Xcode 会自动生成 provisioning profile。之后才能在终端跑 `xcodebuild`。

---

## 工程结构

```
token-scope/
├── TokenScope.xcworkspace/         ← 顶层 workspace（提交进 git）
├── Packages/                       ← 4 个独立 SPM 包
│   ├── TSCore/                       领域层（0 框架依赖）
│   ├── TSProviders/                  上游 API 采集层
│   ├── TSStorage/                    GRDB 7 + Keychain
│   └── TSDesignSystem/               SwiftUI tokens / 组件
├── Apps/
│   ├── project.yml                 ← XcodeGen 唯一来源
│   ├── Local.xcconfig.template       Team ID 模板
│   ├── Local.xcconfig                你的 Team ID（不进 git）
│   ├── TokenScope-macOS/             macOS App 源码
│   └── TokenScope-macOS.xcodeproj/   ← 生成产物，不进 git
├── Widgets/                        ← v0.1 暂空（Widget 源在 Apps/TokenScopeWidget-macOS/）
├── Shared/
│   └── AppGroupConstants.swift     ← Bundle ID / App Group / Keychain 标识单一来源
├── .github/workflows/ci.yml        ← swift test + xcodebuild build（不签名）
├── .project-governance/            ← 项目治理（PRD / 架构 / 决策 / 流程）
├── cc-switch/                      ← 参考源（独立项目，不构建、不修改、不入索引）
└── README.md                       ← 本文件
```

依赖方向严格单向：`Apps / Widgets → TSProviders, TSStorage, TSDesignSystem → TSCore`。

---

## 单包测试

```bash
swift test --package-path Packages/TSCore
swift test --package-path Packages/TSProviders
swift test --package-path Packages/TSStorage
swift test --package-path Packages/TSDesignSystem
```

GRDB 7 首次 resolve 会下载 ~5 MB 并编译 ~30s。

---

## 与 `cc-switch/` 子目录的关系

仓库里 `cc-switch/` 是另一个独立的开源项目（[cc-switch](https://github.com/farion1231/cc-switch)），**不是 token-scope 的代码、不参与 build、不会被 import**。

它在此处的角色是 **token-scope 的协议与实现参考**——`cc-switch/src-tauri/src/services/balance.rs` 包含 DeepSeek 等 6 家供应商的 Rust 实现，token-scope 用 Swift 重写但**字段语义一比一对齐**（详见 [`API_CONTRACT.md`](.project-governance/ssot/API_CONTRACT.md) 与 [`imports/SOURCE_INDEX.md`](.project-governance/imports/SOURCE_INDEX.md)）。

clone 时如果不需要参考，可以直接删 `cc-switch/` 目录（已在 `.gitignore` 里）。

---

## v0.1 路线（MMF-first）

| 阶段 | 名称 | 状态 |
|---|---|---|
| M0 | 工程骨架就位 | 🟡 进行中 |
| M1 | 数据层 + DeepSeek Provider | ⏳ |
| M2 | 主 App UI（账号管理 + 手动刷新） | ⏳ |
| M3 | 菜单栏 + 后台刷新 + 低余额告警 | ⏳ |
| M4 | Widget Extension（桌面 ambient） | ⏳ |
| M5 | 自验证 + 文档收尾 | ⏳ |

每个阶段完成后用户拍板才进下一个，详见 [`processes/active.md`](.project-governance/processes/active.md)。

---

## v0.2+ 已登记到 Backlog

- iOS 端 + iCloud Keychain 同步
- 火山方舟 / OpenRouter / SiliconFlow / 智谱 GLM / Kimi 等供应商
- Developer ID 签名 + DMG 分发 + Sparkle 自动更新
- 自定义中转站协议

详见 [`PROJECT_STATE.md` §Backlog](.project-governance/ssot/PROJECT_STATE.md)。

---

## License

MIT —— 详见 [`LICENSE`](LICENSE)。
