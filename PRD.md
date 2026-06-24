# AIModelMonitor 产品需求文档

> 本文档是产品需求（What & Why）的唯一信息来源。
> 状态：v1.0 规划完成，待开发

---

## 1. 产品概述

### 1.1 一句话

macOS 桌面小组件应用，在桌面/菜单栏上统一展示多个 AI 模型的使用量、余额、配额信息。

### 1.2 目标用户

开发者 —— 正在使用多个 AI 模型（API 调用 / 订阅）并希望在一个地方看到所有用量概况的人。

### 1.3 价值主张

- **免登录**：只填 API Key，不跑 OAuth，不依赖 CLI 安装（v1.0）
- **一个视角**：所有模型用量，不论背后是哪家供应商，都在一个视图里
- **常驻可见**：Widget 贴桌面，菜单栏一点展开，不用打开浏览器/登录各家后台

### 1.4 隐私承诺

- API Key **仅存本地 Keychain**，不上传任何服务器
- App **直连各 AI 厂商官方 API**，不经过任何中间服务器
- 隐私声明在 Settings 页明确展示

---

## 2. 版本边界

### 2.1 v1.0（当前）

| 维度 | 范围 | 不做什么 |
|---|---|---|
| 平台 | macOS 12.0+ 仅 | iOS / iPadOS |
| 形态 | App 主窗口 + 菜单栏组件 + 桌面 Widget | 锁屏 Widget / 灵动岛 / Live Activities |
| Provider | 7 内置预设 + 1 自定义入口（`baseURL + API Key` 类） | OAuth 登录 / AK-SK 签名 / Copilot 独立 auth |
| 认证 | 仅 API Key（用户手动填入） | OAuth 设备码 / CLI 凭据复用 |
| 数据 | 当前快照（数字 + 进度条） | 历史趋势图 / 曲线 |
| 同步 | 无 iCloud 同步 | iCloud |
| 分发 | GitHub DMG（Developer ID 签名 + 公证） | App Store / TestFlight |
| 付费 | 免费开源 | 付费 / 订阅 |

### 2.2 v1.1（下一步）

- iOS / iPadOS 适配（数据层 100% 复用，UI 重写）
- OAuth Provider（Claude 官方 / ChatGPT Codex / Gemini / GitHub Copilot）+ 火山方舟（AK/SK 签名）+ StepFun / Novita / MiniMax / ZenMux
- 模型详情页（点 Widget 跳详情而非主窗口）

### 2.3 等待规划

- 历史趋势图
- iCloud 配置同步
- 锁屏 Widget / 灵动岛 / Live Activities
- App Store 上架
- OAuth 登录 claude.ai 网页版（无公开 device flow）

---

## 3. 用户故事

### 核心流程

```
用户下载 DMG（或 clone 自编译）
  → 首次打开 App
  → App 引导用户添加模型
  → 从预设 Provider 列表选一个
  → 填入 API Key
  → 系统立即校验：试拉一次接口
  → 校验通过 → 模型出现在 Dashboard 中 + 桌面上可选 Widget
  → 校验失败 → 不允许添加，提示原因
  → 添加更多模型…
  → 勾选"开机启动" → 菜单栏常驻 → 每 30 秒刷新一次
  → 在桌面上摆一个 Widget → 按 Widget 尺寸选择显示哪几个模型
```

### S01（v1.0 不支持）：Claude / ChatGPT 官方账号用量
**v1.0 明确不支持**查询 Anthropic / OpenAI 等官方厂商的账户余额/订阅用量，因为这些厂商**没有公开的"API Key → 余额"端点**——必须走 OAuth。OAuth 已规划到 v1.1。

如用户尝试添加"Claude 官方"作为自定义 Provider，校验阶段会失败（Anthropic API 没有兼容的余额端点）。UI 应在自定义 Provider 添加界面提示"Anthropic / OpenAI 官方账号将在 v1.1 通过 OAuth 支持"。

### S02：添加 DeepSeek
从预设 DeepSeek 选 → 填 API Key → 通过 → Dashboard 显示余额数字 + 进度条

### S03：添加 Kimi Coding Plan
从预设 Kimi 选 → 填 API Key → 通过 → Dashboard 显示使用百分比 + 重置时间

### S04：Widget 配置
桌面上长按 Widget → 选择"编辑 Widget" → 从已配置的模型列表中勾选 → 确认

### S05：Widget 状态
- 正常：显示数据
- 数据过期：显示"X 分钟前"，角标/变色
- 模型被删除：单模型显示"已移除"灰卡；多模型中该项灰卡占位

### S06：菜单栏
点击菜单栏图标 → 弹出框展示所有已配模型完整信息 → 底部"立即刷新 / 打开 App / 退出"

---

## 4. v1.0 功能介绍

### 4.1 模型管理

| 功能 | 描述 |
|---|---|
| 添加模型 | 选 Provider 类型（预设 7 个 / 自定义）→ 填 API Key（+ 自定义的 baseURL / 名称） → 实时校验通过则加入列表 |
| 删除模型 | 确认后从 Keychain + 元数据移除；提示该模型在 X 个 Widget 中被使用 |
| 模型列表 | Dashboard 中所有已添加模型的卡片概览 |

### 4.2 Dashboard

Bento 布局卡片展示所有已配置模型的完整信息：主数字 + 副信息 + 最近刷新时间。

### 4.3 桌面 Widget

- 三种尺寸：`systemSmall`（1 个）、`systemMedium`（≤4 个）、`systemLarge`（≤10 个）
- AppIntent 配置：长按选择显示哪些模型
- 信息层级：Logo + 名称 + 主数字 + 进度条/单位 + 更新时间
- 状态：仅"正常"和"数据过期"两种（不展示原始错误）
- 模型被删除 → 单模型灰卡占位，多模型中该项灰卡

### 4.4 菜单栏组件

- NSStatusItem 常驻（系统图标样式，v1.0 先用品牌图标）
- 点击 → NSPopover 下拉：
  - 所有已配置模型完整详情
  - 底部：立即刷新 / 打开 App / 退出
- App 退出后菜单栏消失

### 4.5 设置

| 项 | 默认值 | 可选值 |
|---|---|---|
| 刷新频率 | 30s | 10s / 30s / 1min / 5min |
| 开机启动 | 关 | 开 / 关 |
| 语言 | 跟随系统 | 中文 / English |

### 4.6 本地化

- 中英双语
- 跟随系统语言；非中英系统 → 英语
- 代码用英文标识符，界面字符串用 `.strings` 文件

---

## 5. 假数据 / AI Filler 规则

开发阶段（无真实 API Key 时）：
- 每个 Provider 在 `ProviderProtocol.fetchUsage` 中提供 `DevelopmentProvider` 实现
- 返回模拟的 `ModelUsage`：随机数字 + 固定示例数据 + 模拟的更新时间
- **禁止**把假数据逻辑混入生产代码路径；通过 `#if DEBUG` 或 mock 注入
- 提交到 GitHub main 分支的代码**不可包含**假数据路径被执行的可能

---

## 6. 验收标准

- [ ] macOS 12+ 编译通过、无警告
- [ ] 7 个内置 Provider 全部可从 UI 添加、校验、刷新
- [ ] 自定义 Provider 可从 UI 添加（填 baseURL + Key + 协议类型）
- [ ] Widget 三种尺寸渲染正常（无重叠 / 截断）
- [ ] 菜单栏下拉展开、收起、操作正常
- [ ] API Key 仅存入 Keychain，UserDefaults 中无明文 Key
- [ ] 中英双语切换生效
- [ ] App 签名 + 公证通过
- [ ] Widget 在 App 退出后仍能按系统调度刷新（使用旧数据兜底）
- [ ] 删除在 Widget 中使用的模型 → Widget 正确显示灰卡占位

---

## 7. 参考来源

- cc-switch（`/Users/jiangcan/Desktop/桌面组件开发/cc-switch/`）的 balance.rs / coding_plan.rs 作为 Provider API 参考