# PRD

产品需求和交互要求的 SSOT。任何需求或交互变更都必须更新本文件并留痕。

- Status: confirmed   （允许值：`draft` / `confirmed` / `superseded`）

## Change History

`Version` 列填项目版本号（如 `v1.0`、`v1.1`），与 `ssot/PROJECT_STATE.md` 的 `Versions` 段对应。

| Date | Version | Change | Reason | Decision |
|---|---|---|---|---|
| 2026-06-24 | v0.1 | 初始草稿：macOS-only + 仅 DeepSeek，桌面 Widget + 菜单栏，验证 ambient 形态 | 用户最初提"双端 + 各模型"过宽，逐刀收口到当下可验证的最窄切面 | Confirmed by user |
| 2026-06-24 | v0.1 | 第二段后调整：分发改为"仅本机 + 开源代码"，AC-7 从"签名公证 DMG"改为"本机 Run 全绿"，H1（20 人留存）推到 v0.2 | 用户选择不办 Apple Developer 账号、v0.1 仅作者本人使用 | Confirmed by user |

## Content

### Product goal

让"用 `baseURL + apiKey` 接入多家 LLM 的重度用户"，在 macOS 桌面/菜单栏一眼看见每家账号的余额与可用状态，避免**事后才发现账户欠费/告罄**。

一句话差异化：**"cc-switch 管你切，token-scope 管你看。"**

### Scope in/out

**In（v0.1 范围）**

- 平台：macOS 14+（Sonoma 及以上，桌面 Widget 系统能力门槛）
- 供应商：DeepSeek 1 家
- 形态：菜单栏 App（NSStatusItem 常驻）+ 桌面 Widget（systemMedium）+ 通知中心 Widget（同一 Widget Extension）
- 指标：剩余余额（带 CNY 币种）、是否可用、上次刷新时间、低余额阈值告警
- 主 App 单页：账号增/删/改、手动刷新、最近刷新结果展示

**Out（明确排除，落入 Backlog）**

- 任何非 macOS 平台（iOS / iPadOS / Web / Windows）→ B-001
- DeepSeek 之外的任何供应商 → B-003 / B-004 / B-005
- 趋势图、模型拆分、历史明细 → B-007
- 多账号同一供应商 → B-008
- 同步 / 团队 / 商业化 → B-002 / B-009 / B-010

### Users and workflows

**目标用户**（v0.1 画像）：

- 重度 AI 编程用户 / 自部署中转站用户 / 国产 Coding Plan 订阅者
- 共同特征：所有模型都以 `baseURL + apiKey` 形式接入
- 排除：Codex / Claude.ai / ChatGPT Plus 等订阅式聊天产品用户

**核心工作流**：

1. 首次打开主 App → 点 "+" → 选 DeepSeek → 粘贴 apiKey（baseURL 默认 `https://api.deepseek.com`）→ 设置低余额阈值（默认 10 CNY）→ 保存
2. App 立即拉取一次余额并显示在主 App + 菜单栏
3. 用户启用 Widget → 在桌面/通知中心看到余额卡片
4. App 后台每 30 分钟自动刷新，低于阈值时本机通知
5. 用户菜单栏点一下能立即手动刷新

### Functional requirements

| ID | 功能 | 说明 |
|---|---|---|
| F-101 | 账号管理 | 新增/编辑/删除一个 DeepSeek 账号；字段：label（用户起名）、baseURL（默认 `https://api.deepseek.com`，可改）、apiKey、低余额阈值（CNY，默认 10） |
| F-102 | 余额查询 | 调用 `GET {baseURL}/user/balance`，Bearer 认证，超时 15s；解析 `balance_infos[].total_balance` 与 `is_available`；详见 `API_CONTRACT.md` |
| F-103 | 状态三态 | success（拉到数据）/ failure（网络错误，保留上次成功快照）/ invalid（401/403，标红"账号失效"，对应 `is_valid=false`） |
| F-104 | 后台自动刷新 | 默认 30 分钟一次；用户可在设置改为 15/30/60 分钟或关闭 |
| F-105 | 手动刷新 | 菜单栏按钮 + 主 App 按钮 + Widget 长按（macOS 14+ 支持的话） |
| F-106 | 低余额告警 | 余额 < 阈值时发系统通知（同一阈值跨越事件 24h 内最多 1 次，避免轰炸） |
| F-107 | 菜单栏显示 | NSStatusItem 直接显示数字（如 "¥38.2"），点开展开账号列表 |
| F-108 | 桌面 Widget | systemMedium 单尺寸，展示账号 label + 余额数字 + 币种 + 刷新时间相对值（如"5 分钟前"） |
| F-109 | 密钥安全 | apiKey 仅存 macOS Keychain（Access Group 共享给 Widget Extension），主数据库不含明文 |
| F-110 | "建议接入新供应商"入口 | 主 App 显眼位置一个按钮，弹窗收集用户想要的供应商名称，本地落 JSON（供 v0.2 决策用）—— **验证 H3 的关键** |

### Interaction requirements

- **首次启动空状态**：直接进入"添加 DeepSeek 账号"卡片，不显示通用引导页
- **菜单栏图标**：默认显示美元符号或自定义 logo + 第一个账号余额数字；多账号时只显示总余额或"3 个账号"
- **配置弹窗**：apiKey 输入框默认遮蔽，旁边一个 👁 切换显示；保存前**不做联网校验**（避免用户首次输入慢、网卡），保存后立即触发一次刷新，刷新失败时把账号标红
- **Widget 失败态**：网络错误显示灰色"--"和"5 分钟前" + 一个刷新箭头；invalid 失效显示红色 "!"，引导用户回主 App 处理
- **告警通知文案**：`DeepSeek 余额低于阈值：剩 ¥X.XX（阈值 ¥Y）`，点击直达主 App
- **语言**：v0.1 支持中文 + 英文，跟随系统语言

### Acceptance criteria

> v0.1 验收基准已调整为"作者本人本机使用"。原"20 人留存"H1 推到 v0.2，原"签名公证 DMG"AC 推到 v0.2。

- AC-1：作者在自己的 macOS 14+ 机器上 Xcode 打开 workspace，cmd-R 即可 Run 主 App，3 分钟内完成"配 key → 看到余额"。
- AC-2：合法 apiKey 拉取成功率 ≥ 95%（剩余 5% 给网络抖动）。
- AC-3：401/403 必然落 invalid，主 App + Widget 都展示失效状态。
- AC-4：Widget 在主 App 后台刷新后 30 秒内可见新数据（含 `WidgetCenter.reloadAllTimelines()` 调用）。
- AC-5：低余额告警在跨越阈值时触发；同阈值持续低位时 24h 内不重复发。
- AC-6：所有 apiKey 离开主 App 主进程后只存在于 Keychain（用 Keychain Access 工具可见、用 `defaults read` 与 SQLite 直读均不可见）。
- AC-7：开机自启在 macOS 重启后能自动拉起主 App（菜单栏图标可见）。
- AC-8：CI（GitHub Actions）`swift test` 全绿，`xcodebuild build` 主 App + Widget Extension 双 target 编译通过。
- AC-9：作者本人连续使用 7 天，主观判断"我愿意一直开着" → H0 成立 → v0.2 启动条件。

### Open questions

- OQ-1：菜单栏默认展示"总余额"还是"第一个账号"？v0.1 只有 1 账号无影响，v0.2 需回看。
- OQ-2：低余额告警阈值是否需要支持按"百分比"（如剩 < 10%）—— 但 DeepSeek 接口不返回 total，目前只能按绝对金额。
- OQ-3：是否在 v0.1 就支持 deeplink（如 `tokenscope://refresh?account=xxx`）方便与 cc-switch 互通？倾向不做，记 v0.2。
