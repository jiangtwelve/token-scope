# Agent Bootstrap

除非 `AGENTS.md` 中 project-governance block 为 `Status: disabled`，否则所有 agent 必须遵守本文件。

Metadata: governance_skill=project-governance; governance_version=1.2.2; initialized_at=2026-06-24; project_type=macos-native-swift-app

## 启动

1. 先读 `ssot/PROJECT_STATE.md`，确认当前 `Current Version`、骨架四段状态、`Active Process`、`Backlog` 与 `Stage Regressions`。
2. 再读 `rules/GRILLING_PROTOCOL.md`、`rules/DEVELOPMENT_PROCESS.md`、`rules/VERSION_RULES.md`、`rules/DOCUMENTATION_RULES.md`、`ssot/GLOSSARY.md`。
3. 若当前版本已进入第三段，读 `.project-governance/processes/active.md`，了解本版本商定的开发流程。
4. 按任务读取相关 SSOT、流程、验收、导入或决策文件；默认只读 `.project-governance/decisions/INDEX.md`，需追溯时再读单个决策文件。

## 红线（必须守住，细节看对应规则文件）

- **骨架红线**：四段不可重命名/合并/跳过；第一、二段未 `Confirmed` 不得进第三段；第四段未 `Confirmed` 不得结束当前版本、不得启动新版本。详见 `rules/DEVELOPMENT_PROCESS.md`。
- **版本红线**：当前版本未完成禁止升版本；硬升按 `rules/VERSION_RULES.md` 的"硬升应对"处理。
- **阶段级红线**：实际开发段内部流程中任何 `acceptance_required: true` 的阶段，未经用户明确确认不得推进。
- **Task Plan 红线**：实际开发段内部流程中任何 `acceptance_required: true` 的阶段，**进入编码前必须先在 `processes/tasks/<stage_id>.md` 产出颗粒级 task plan 并经用户明确确认**；未确认 task plan 时不允许出现任何编码 / 新建文件 / 修改既有文件的工具调用。task plan 的**结构、字段名、表头、列顺序**严格遵循 `templates/RECORD_TEMPLATES.md` 的 `Task Plan` 段（唯一权威格式，不允许 agent 自由发挥）。详见 `rules/DEVELOPMENT_PROCESS.md` 的 "Task Plan 前置" 段。
- **Code Review 红线**：任何 task 只要涉及代码新增、修改或删除，完成代码改动后必须先插入 code review，优先使用当前开发环境可用的独立审查能力（Claude Code 下可用 `/code-review`，安全敏感改动可用 `/security-review`；OpenCode、Codex 或其他环境使用等价 review agent / command / 工具）；未完成 review 或存在未修复的阻断问题时，不得标记 task 完成、不得进入下一编码 task、不得进入阶段验收。详见 `rules/DEVELOPMENT_PROCESS.md` 的 "Code Review 后置" 段。
- **追问红线**：歧义必须追问，一次一问、附建议与理由；用户明确表达才算确认。详见 `rules/GRILLING_PROTOCOL.md`。
- **术语红线**：用户或 agent 引入任何新概念前，必须先在 `ssot/GLOSSARY.md` 登记并对齐含义。维护与沟通规则见 `ssot/GLOSSARY.md` 自身与 `rules/GRILLING_PROTOCOL.md`。
- **文档红线**：不允许"先写代码、文档后补"；需求/架构/接口变化必须更新对应 SSOT 并留痕。详见 `rules/DOCUMENTATION_RULES.md`。
- **流程库红线**：第二段必须先查 `~/.claude/process-library/`，库为空或无合适模板时现场起草。沉淀触发与字段定义见 `rules/VERSION_RULES.md` 与 `rules/DEVELOPMENT_PROCESS.md`。

## 索引

- SSOT：`ssot/PRD.md`、`ssot/ARCHITECTURE.md`、`ssot/API_CONTRACT.md`、`ssot/PROJECT_STATE.md`、`ssot/GLOSSARY.md`
- 规则：`rules/GRILLING_PROTOCOL.md`、`rules/DEVELOPMENT_PROCESS.md`、`rules/VERSION_RULES.md`、`rules/DOCUMENTATION_RULES.md`、`rules/UPGRADE_RULES.md`
- 流程：`.project-governance/processes/active.md`（本项目本版本流程）、`.project-governance/processes/tasks/`（每个 acceptance_required 阶段的颗粒级 task plan）、`~/.claude/process-library/`（用户私有流程库）
- 追溯：`.project-governance/decisions/INDEX.md`、`.project-governance/imports/SOURCE_INDEX.md`
