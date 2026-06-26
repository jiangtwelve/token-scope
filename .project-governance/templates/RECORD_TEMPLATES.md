# Record Templates

## Acceptance Report

- Version:
- Stage ID:
- 中文名称:
- English Name:
- Status: pending
- Confirmed at:
- Scope:
- Outcome:
- Required changes:

## Decision Record

`Title` 同时写入 `decisions/INDEX.md` 表格的 `Title` 列。

- ID:
- Date:
- Title:
- Area:
- Status: proposed
- Related SSOT:
- Context:
- Options:
- Chosen:
- Impact:
- Follow-ups:

## Stage Regression Record

短表写入 `PROJECT_STATE.md` 的 `Stage Regressions`；展开版（含 Impact）写入决策记录。

- Date:
- Version:
- From Stage:
- To Stage:
- Reason:
- Impact on existing artifacts:（写入决策记录，PROJECT_STATE 表内不展开）
- User Confirmed:

## Backlog Item

- ID:
- Description:
- From Version:
- From Stage:
- Target Version:（留空表示未指定）
- Reason:
- User Confirmed:

## Process Mutation Record

- Date:
- Version:
- Change Type:（add / remove / reorder / edit）
- Stage Affected:
- Detail:
- Reason:
- Overlap Adjudication:（reuse / patch / redo + 理由）
- User Confirmed:

## Task Plan

每个 `acceptance_required: true` 流程阶段进入编码前必须产出。规则见 `rules/DEVELOPMENT_PROCESS.md` 的 "Task Plan 前置" 段。文件写到 `processes/tasks/<stage_id>.md`。

```markdown
# Task Plan: <stage_id> · <name_zh>

## Meta

- Version: <vX.Y>
- Stage ID: <stage_id>
- Drafted At: <YYYY-MM-DD>
- Approved At: <YYYY-MM-DD or "pending">

## Tasks

| id | title | 产出 / 验证 | 预估 | 依赖 |
|---|---|---|---|---|
| <stage>.1 | 动词开头一句话 | 文件路径 / 命令 / 可见行为 | 10 min | — |
| <stage>.2 | ... | ... | 20 min | <stage>.1 |

## Risks

本次实例预估外风险。每条附触发条件 + 兜底动作。不重复 active.md 的 `typical_pitfalls`。

- Risk A：<描述>
  - 触发条件：<什么时候会出现>
  - 兜底动作：<出现后怎么救>

## Explicitly Not Doing

明确划走的事，避免边界蔓延：

- 不做的事 1
- 不做的事 2

## Definition of Done

与 active.md 对应阶段 `done_when` 一一映射：

- [ ] done_when 第 1 条 ↔ 本表 task <id>
- [ ] done_when 第 2 条 ↔ 本表 task <id>
- [ ] 全部 task 表逐条勾选完成
- [ ] 用户明确确认

## Mutation Log

执行中改动留痕。规则见 `rules/DEVELOPMENT_PROCESS.md` "Task Plan 前置 · 执行中改动" 段。

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
```

## Process Library Submission

- Date:
- Submitted From Project:
- Submitted From Version:
- Library Path: `~/.claude/process-library/<name>.md`
- Submission Type:（new / replace-existing）
- Lessons Learned Summary:
- User Confirmed:

## Glossary Revision

- Date:
- Term (Doc Term):
- Old Meaning:
- New Meaning:
- Triggered By Version:
- Reason:
- User Confirmed:
