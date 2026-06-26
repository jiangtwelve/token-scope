# D-001: v0.1 不签名不公证，仅本机 + 开源代码

- ID: D-001
- Date: 2026-06-24
- Title: v0.1 不签名不公证，仅本机 + 开源代码
- Area: Distribution
- Status: accepted
- Related SSOT: `ssot/ARCHITECTURE.md §Deployment`、`ssot/PRD.md §Acceptance criteria`

## Context

原方案 v0.1 = "Developer ID DMG + 灰度发 20 人 + 验证 H1（20 人/7 天留存）"。用户在第二段技术栈确认阶段被问及是否已有 Apple Developer 账号时，答案是"先考虑 GitHub 开源策略 + DMG + TestFlight"，但 agent 澄清：

- TestFlight 必须先把 App 上传到 App Store Connect，等于为 Mac App Store 沙盒审核做工程改造，与 v0.1 菜单栏常驻 + 后台刷新 + 自更新路线直接冲突。
- DMG 要"双击免提示"必须 Developer ID 签名 + Apple 公证，需要 $99/年账号。
- GitHub 开源解决代码可见性，不解决 Gatekeeper 拦截。

随后用户明确选择"仅本机 + 开源代码（不发 DMG）"。

## Options

- A. 开源 + Developer ID DMG（推荐但需 $99/年）
- B. 开源 + 未签名 DMG（0 费用，80% 用户被劝退）
- C. **仅本机 + 开源代码（0 费用，验证池=作者本人）** ← chosen
- D. v0.1 未签名、v0.2 补账号

## Chosen

**C**：v0.1 不发 DMG，不申请 Developer 账号。开源代码到 GitHub，README 给出 cmd-R 步骤；验收基准 = 作者本人 7 天连续使用。

## Impact

- PRD §Acceptance criteria：
  - 删除原 AC-7（开发者签名 + 公证 + DMG 安装无警告）
  - 改为：AC-1（本机 Run 3 分钟内配 key + 看到余额）、AC-7（开机自启）、AC-8（CI 全绿）、AC-9（作者本人 7 天 H0 成立）
- 原 H1（20 人/7 天留存）→ 推到 v0.2（B-013）
- v0.1 验证假设收窄为 H0：作者本人主观留存 + "我愿意一直开着"
- Bundle ID v0.1 用 `local.tokenscope.*` 占位 → B-013 v0.2 切正式反域名
- Keychain Access Group v0.1 不可靠 → D-006 v0.1 用 non-shared Keychain
- App Sandbox v0.1 暂不启用（避免 unsigned + sandbox 的连锁配置问题）

## Follow-ups

- v0.1 完成后做 7 天 H0 评估：
  - 若 H0 成立 → 启动 v0.2，按 B-013 ~ B-016 一次性补齐 Developer ID / Access Group / Sparkle / 评估 LaunchAgent
  - 若 H0 不成立 → 诚实记录，决定是否还要做 v0.2（不强行硬上）

## Revisions

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
| 2026-06-25 | 实操从"完全不签名（ad-hoc）"细化为"使用免费 Personal Team 本地签名"。仍不办 $99 Developer Program，仍不分发 DMG，仍是作者本人本机用。差别：用 Apple ID 自动颁发的 Personal Team 给 App + Widget 签名，让 App Group entitlement 可用 | M0.10 执行时发现 macOS 强制要求 App Group entitlement 必须配 development cert；纯 ad-hoc 签名无法附带这个 entitlement。Personal Team 免费、Apple ID 即得、足够支撑 v0.1 本机 ambient 体验。详见 tasks/M0_skeleton_bootstrap.md Mutation Log | 2026-06-25 |
