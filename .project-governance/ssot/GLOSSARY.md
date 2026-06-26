# Glossary

用户口语 ↔ 文档术语 ↔ 代码标识 的对照表。全项目唯一一份，跨版本共享。

## 维护规则（与四段骨架绑定）

- **第一段（需求确认）**：用户或 agent 引入任何新概念前，必须先在本表登记并对齐含义。未登记的术语不得写入 PRD、架构、API 或代码。
- **第二段（技术栈确认）**：补齐每条术语的 `Code Identifier`（代码字段、变量名、接口名）。
- **第三段（实际开发）**：开发中冒出未登记的新概念时，agent 必须按追问协议判断该概念是否影响需求/架构：
  - 影响：触发回归到第一段补登记。
  - 不影响：本段内补登记，但仍需用户明确确认。
- **第四段（验收测试）**：以本表为权威对齐用户反馈与文档/界面措辞。

## 沟通规则

agent 与用户对话时如何使用本表（白话优先、引用术语必先翻译、匹配冲突触发追问），见 `rules/GRILLING_PROTOCOL.md` 的"怎么追问"段。

## 演化规则

- 同一术语的含义跨版本扩展或收窄时，**追加** `Revisions` 记录，不覆盖旧含义。
- `Introduced In` 记录术语首次确认的版本号。
- 术语作废时，状态改为 `Deprecated` 并在 `Revisions` 写入作废原因；不直接删除。

## 字段说明

| 字段 | 说明 |
|---|---|
| User Term | 用户口语说法，可有多个别名（用 `;` 分隔） |
| Doc Term | 文档与决策记录使用的标准词 |
| Code Identifier | 代码字段、变量名、接口名（第二段起填） |
| Meaning | 一句话白话解释 |
| Appears In | 关联到 PRD / 架构 / API 的章节定位 |
| Counter Example | 容易混淆的相近概念，明确"不指什么" |
| Introduced In | 首次确认的版本号（如 `v1.0`） |
| Revisions | 修订记录列表：`<版本> <旧含义→新含义> <原因> <用户确认时间>` |
| Status | `Active` / `Deprecated` |

## 条目

| User Term | Doc Term | Code Identifier | Meaning | Appears In | Counter Example | Introduced In | Revisions | Status |
|---|---|---|---|---|---|---|---|---|
| 供应商; 厂家; 服务商; provider | Provider | Provider | 一家提供 LLM API 的公司或网关（如 DeepSeek、OpenRouter、火山方舟） | PRD §F-101、ARCH §Module | 不指具体模型（如 deepseek-chat），不指账号 | v0.1 | — | Active |
| 账号; key; 密钥账户 | Account | Account | 用户在某个 Provider 下持有的一组凭据（baseURL + apiKey），可设置 label 与告警阈值 | PRD §F-101 | 不指系统登录账号 / 不指多个 apiKey | v0.1 | — | Active |
| baseURL; 接口地址; 域名 | Base URL | baseURL | Provider HTTP 接口的根地址，DeepSeek 默认 `https://api.deepseek.com` | API §Base URL | 不含具体 path | v0.1 | — | Active |
| apiKey; key; 令牌; 密钥 | API Key | apiKey | 用于 Bearer 鉴权的字符串，仅存于 Keychain | PRD §F-109、API §Auth | 不指 OAuth token / 不指 AK+SK 对（火山方舟那种 v0.3 才出现） | v0.1 | — | Active |
| 余额; 钱; balance | Remaining Balance | remaining | 账号当前剩余金额，带币种 | PRD §F-102、API §Endpoints | 不指总额 / 不指已用 | v0.1 | — | Active |
| 用量; usage | Usage Snapshot | UsageSnapshot | 一次拉取得到的整组状态，含余额、币种、是否可用、拉取时间 | ARCH §Data model | 不指历史累计、不指趋势 | v0.1 | — | Active |
| 失效; 401; 过期 | Account Invalid | invalid | 上游返回 401/403 表示 apiKey 错误或被吊销 | API §Error format | 不指网络错误（network failure 是另一态） | v0.1 | — | Active |
| 网络错误; 拉不到; 网炸了 | Refresh Failure | failure | 网络/HTTP/解析任意失败但非鉴权问题，保留上次成功快照 | API §Error format | 不指账号失效 | v0.1 | — | Active |
| 阈值; 提醒线; 告警值 | Low Balance Threshold | thresholdCNY | 用户设的低余额线，低于此值触发本机通知 | PRD §F-106 | 不指自动充值线（v0.1 不做） | v0.1 | — | Active |
| 小组件; widget; 桌面卡 | Widget | BalanceWidget | macOS 桌面 / 通知中心展示账号余额的卡片，由独立 Extension 进程渲染 | PRD §F-108、ARCH §System overview | 不指主 App 窗口 / 不指菜单栏 | v0.1 | — | Active |
| 菜单栏; status bar | Menu Bar Item | NSStatusItem | macOS 顶部菜单栏常驻图标，显示余额数字 | PRD §F-107 | 不指 Dock / 不指 widget | v0.1 | — | Active |
| 后台刷新; 自动拉 | Background Refresh | BackgroundRefreshScheduler | 主 App 用 NSBackgroundActivityScheduler 定时拉取，默认 30 分钟 | PRD §F-104、ARCH §Module | 不指 iOS BGTask（v0.2 才出现） | v0.1 | — | Active |
| App Group; 共享容器 | App Group Container | group.io.tokenscope.shared | 主 App 与 Widget Extension 共享的沙盒目录与 Keychain Access Group | ARCH §System overview | 不指 iCloud / 不指公共目录 | v0.1 | — | Active |
| 中转站; 代理; 网关 | Relay / Gateway | — | 转发多家 LLM 的第三方 API 服务，行为上像独立 Provider（OpenRouter、SiliconFlow 等） | PROJECT_STATE §Key Facts | 不指浏览器代理 / 不指 cc-switch 本身 | v0.1（仅概念登记，v0.2 起出现实体） | — | Active |
| Coding Plan; 编码套餐 | Coding Plan | — | 国产 LLM 厂商按"包月/包年/Token 包"售卖给开发者的订阅产品，返回的是 quota tier 而非余额 | PROJECT_STATE §Key Facts | 不同于 token 计费余额（DeepSeek 那种） | v0.1（仅概念登记，v0.3 起出现实体） | — | Active |
| cc-switch | Reference Project: cc-switch | — | 项目根目录下作参考的另一独立项目，token-scope 的字段语义和接口实现以它为参照，但不依赖其代码 | PROJECT_STATE §Key Facts | 不是 token-scope 的子模块 / 不发布 / 不构建 | v0.1 | — | Active |
