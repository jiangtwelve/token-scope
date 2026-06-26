# Documentation Rules

## SSOT

`.project-governance/ssot/*` 是项目开发的权威来源：

- `PRD.md`：产品需求、用户流程、交互要求、需求变更摘要。
- `ARCHITECTURE.md`：技术架构、模块边界、数据模型、部署约束、架构变更摘要。
- `API_CONTRACT.md`：跨组件接口契约，是契约消费方与提供方的共同标准；无外部接口的项目保留为 `n/a` 状态。
- `PROJECT_STATE.md`：当前版本、骨架四段状态、Active Process、Backlog、回归记录、跳过记录、关键事实。
- `GLOSSARY.md`：用户口语 ↔ 文档术语 ↔ 代码标识的对照表，全项目唯一一份，跨版本共享。

## 变更留痕

- 需求或交互变化必须更新 `PRD.md` 的 `Change History`。
- 架构变化必须更新 `ARCHITECTURE.md` 的 `Change History`。
- API 契约变化必须更新 `API_CONTRACT.md` 的 `Change History`。
- 术语含义变化必须追加 `GLOSSARY.md` 的 `Revisions`，不覆盖旧含义。
- 版本启动、版本结束、阶段回归、流程改动必须更新 `PROJECT_STATE.md` 对应段。
- 实际开发段内部流程定义变化写入 `.project-governance/processes/active.md` 的 `Mutation Log`。
- 详细讨论和权衡不要塞进 SSOT 主文档，写入 `.project-governance/decisions/` 单独文件，并在 `.project-governance/decisions/INDEX.md` 登记。

## 记录标准

记录会影响后续需求、架构、流程、版本或验收判断的事实：范围/交互变化、技术栈/数据/API 决策、阶段验收、骨架阶段回归、流程改动、版本启停、Backlog 增删、阻塞风险、返工方向、治理升级或停用。不要记录普通命令、提交 git、临时调试、格式化、无行为变化重命名或 agent 自言自语。

## 现有文档导入

- 导入时不主动移动或删除原始文档。
- 导入过程记录在 `imports/SOURCE_INDEX.md`。
- 从原始文档提炼出的内容必须经过追问和用户确认后，才能进入 SSOT 与 `GLOSSARY.md`。
- 原始文档被确认导入后不再作为权威来源；若与 SSOT 冲突，以 SSOT 为准，可由用户自行删除或归档。
- 用户最新明确确认的结论优先于原始文档，但必须写入 SSOT 和决策记录。

## 语言策略

- 说明、规则、确认文本、流程解释用中文为主。
- 文件名、目录名、字段名、阶段 ID 使用英文稳定索引。
- 阶段名必须同时保留中文名称和英文名称。
- 与用户对话遵循 `rules/GRILLING_PROTOCOL.md` 的措辞约束：白话优先，引用术语必先翻译。
