# D-004: v0.1 测试基线豁免 80% 全局红线

- ID: D-004
- Date: 2026-06-24
- Title: v0.1 测试基线豁免 80% 全局红线，采用"领域 + 解码表驱动 + UI/Storage smoke"
- Area: Testing
- Status: accepted
- Related SSOT: `ssot/ARCHITECTURE.md §Tech stack`、`processes/active.md` 各阶段 done_when

## Context

用户全局规则（`~/.claude/rules/common/testing.md`）要求最低 80% 测试覆盖率。但 v0.1 的现实约束：

- 验证池子=作者本人（D-001）
- 时间线 2~3 周
- 主要 bug 高发区是网络解码（DeepSeek 响应字段兼容字符串/数字、空数组、is_available 字段）

机械地追求 80% 会拖时间且不能精准命中真正脆弱的环节。

## Options

- A. 全面 TDD + UI snapshot test（按全局红线，时间线 +1 周）
- B. 领域 + 解码同 A，额外加 Storage / Keychain 集成测试
- C. **领域 + 解码表驱动 + UI/Storage smoke** ← chosen
- D. 仅 happy-path E2E smoke（最省，但风险过高）

## Chosen

C。具体边界：

- **必有单测**：
  - `TSCore`：UseCases、Decimal 计算、阈值判断、状态机
  - `TSProviders.DeepSeekResponseDecoder`：按 `API_CONTRACT.md §Endpoints` 9 个表驱动用例（T-API-1 ~ T-API-9）全绿
- **smoke 即可**：
  - `TSStorage.GRDBSnapshotStore`：临时 sqlite 写 → 读 → 过期清理（1~2 个用例）
  - `TSStorage.KeychainSecretStore`：建 → 读 → 删（1~2 个用例）
  - App UI：手动跑 cmd-R
  - Widget：手动 cmd-R + 拖到桌面

## Impact

- 这是对全局 80% 红线的**明确豁免**，仅适用于 v0.1
- v0.2 必须补齐 80% 覆盖率才能 GA（已登记 Backlog B-012）
- M5_release_polish 阶段不强求覆盖率数字，强求 AC-1 ~ AC-9 逐条勾选

## Follow-ups

- v0.2 启动时（B-012 解锁），重读本决策并补齐测试基线
- 若 v0.1 期间 DeepSeek 接口出现未覆盖的边界 case，逐条补到 T-API 表里（不另开决策）
