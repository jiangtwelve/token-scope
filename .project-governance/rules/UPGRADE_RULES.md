# Upgrade Rules

治理版本记录在 `AGENT_BOOTSTRAP.md` 的 Metadata 中，使用语义化版本。

| Version | Meaning | Default stage handling |
|---|---|---|
| `patch` | 不改变流程语义 | 不中断当前阶段 |
| `minor` | 新增能力或规则强化 | 继续当前阶段，补齐必要文档 |
| `major` | 可能改变骨架、版本结构、流程模型或追问规则 | 必须做影响评估，必须用户确认 |

## 升级

- 可以检测版本、生成 diff 和升级建议；不得静默修改治理规则。
- 修改 `.project-governance/rules/*` 前必须获得用户确认。
- 不得覆盖项目事实文档：`ssot/PRD.md`、`ssot/ARCHITECTURE.md`、`ssot/API_CONTRACT.md`、`ssot/PROJECT_STATE.md`、`ssot/GLOSSARY.md`。
- 升级必须写入 `.project-governance/changelog/GOVERNANCE_CHANGELOG.md`；文件不存在时按需创建。

开发中升级不得默认重置开发流程。必须评估当前版本骨架阶段、内部流程是否受影响、已完成阶段、当前需求/交互/架构/API/验收、是否补齐产物、是否回退或重新验收；结论写入 `PROJECT_STATE.md` 和 `.project-governance/changelog/GOVERNANCE_CHANGELOG.md`。

## 从 0.x 升到 1.0.0（major）

1.0.0 引入了项目骨架四段、多版本结构、Backlog、阶段回归、流程库与对照表。从 0.x 升级时必须：

1. 与用户确认后再迁移 `ssot/PROJECT_STATE.md`：把旧的单段 `Current Stage` 字段迁移成 `Versions` 段下的 `v1.0` 骨架，对应的旧阶段按映射规则填入实际开发段内部流程。映射不明确时按追问协议询问用户。
2. 旧的 `rules/processes/ui-project.md` 文件（仅 0.x 项目可能存在；1.0.0 起 skill 不再预设流程）如果存在，引导用户决定：
   - 把它作为 v1.0 的实际开发流程拷贝到 `.project-governance/processes/active.md`，并询问是否沉淀进 `~/.claude/process-library/`；
   - 或者放弃，由 agent 在第二段重新检索流程库 / 现场起草。
   - 用户决定后删除该旧文件。
3. 新增 `ssot/GLOSSARY.md` 与 `rules/VERSION_RULES.md`；GLOSSARY 由 agent 与用户从现有 PRD/架构反向梳理首批术语。
4. 在 `.project-governance/changelog/GOVERNANCE_CHANGELOG.md` 写一条升级记录：升级前版本、升级后版本、迁移决定、影响范围、用户确认时间。
5. 升级期间不动用户的 PRD / 架构 / API 内容；只动状态与流程结构，且每步必须用户确认。

## 停用与重启

- 用户可通过关闭 `AGENTS.md` 的 project-governance 入口停用；停用后不再强制执行 `.project-governance/`。
- 建议保留 `.project-governance/` 作历史资料；是否删除由用户决定。
- 重新启用前必须扫描停用期间的需求、架构、API、代码、版本变化，更新 `PROJECT_STATE.md`（包括版本骨架、Backlog、回归记录），必要时更新 PRD/架构/API/决策/对照表，再恢复入口状态。
