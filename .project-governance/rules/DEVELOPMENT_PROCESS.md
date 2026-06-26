# Development Process

本文件描述项目级开发流程模型。跨流程的硬规则在 `AGENT_BOOTSTRAP.md`，本文件只列流程专属规则。

## 模型概览

项目周期由两层组成：

- **项目骨架**：固定四段，跨项目不可变、不可重命名、不可合并、不可跳过。
- **实际开发段内部流程**：第三段（实际开发）下挂载"本项目商定的开发流程"，这一层是动态的，按项目情况由 agent 与用户讨论商定。

两层规则相互独立：骨架由 skill 强制，永远焊死；内部流程的可变性受版本与阶段状态约束（见下文）。

## 项目骨架（固定四段）

| ID | 中文名称 | English Name | 完成条件 |
|---|---|---|---|
| 01_requirements_confirmation | 需求确认 | Requirements Confirmation | `ssot/PRD.md` 经用户明确确认 |
| 02_tech_stack_confirmation | 技术栈确认 | Tech Stack Confirmation | `ssot/ARCHITECTURE.md` 经用户明确确认，并在本段完成流程库检索与开发流程商定 |
| 03_active_development | 实际开发 | Active Development | 按本版本商定的开发流程全部完成且通过 |
| 04_acceptance_testing | 验收测试 | Acceptance Testing | 用户对本版本全量功能明确验收 |

骨架阶段状态机：`Not Started` → `In Progress` → `Confirmed`；任何阶段可通过显式回归动作回到 `In Progress`，标注为 `Blocked: regressed to <stage>`。

## 流程库与开发流程商定

- 流程库存放在用户本机 `~/.claude/process-library/`，不在项目内，也不随 skill 发版分发。首次使用时库为空。
- 第二段开始时，agent 必须检索流程库（按项目类型 + 技术栈关键词匹配），把候选模板的 `applicable_to` 与 `lessons_learned` 摘出来给用户，建议是否采用、改用或现场起草。
- 库中无合适模板时，agent 现场按流程模板字段（见下文）起草一份，逐条追问与用户对齐。
- 商定后的开发流程写入 `.project-governance/processes/active.md`，并在 `ssot/PROJECT_STATE.md` 的 `Active Process` 字段引用该文件。
- 当前版本商定的流程仅服务于当前版本；新版本启动时重新走第二段，可选择继续沿用、修改或换一份流程。

### 流程模板字段

每份流程（包括 active.md 与库里的模板）使用下述字段：

- `name`：流程名（库内全局唯一，建议 `<product-type>-<variant>-vN`）。
- `applicable_to`：适用项目类型与边界条件（白话描述）。
- `stages[]`：阶段列表，每个阶段含：
  - `id`：稳定英文 ID。
  - `name_zh`：中文名。
  - `goal`：一句话目标。
  - `done_when`：可验证的完成条件。
  - `acceptance_required`：是否需要用户明确确认（`true` / `false`）。
  - `optional`：在裁剪时是否可省（`true` / `false`）。
  - `typical_pitfalls`：这一步容易踩的坑（一两条）。
- `lessons_learned`：关键经验，沉淀时由用户口述、agent 整理。
- `derived_from`：沉淀来源（项目名、版本号、日期）。

## 实际开发段内部流程的可变性

进入第三段前商定的流程，在本版本内可以改动，但必须遵守以下规则：

- 改动允许加阶段、删阶段、重排顺序、改阶段内容。
- 每条改动必须按追问协议逐条确认（一次一问、附建议、附理由）。
- 单次提议改动数量超过 `Process Mutation Threshold`（默认 3）时，agent 必须先反问：是否考虑换一份流程而不是改这份。换流程走"沉淀候选 → 第二段重新选模板"的路径。
- 流程改动一旦确认，本段必须从新流程的第一个阶段重新开始；新旧流程重叠部分由 agent 起草"重叠研判清单"（旧产物在哪、是否仍满足新流程的 `done_when`、建议复用 / 局部修补 / 重做、附理由），逐条与用户确认，结果写入 `.project-governance/decisions/`。

阶段级红线：流程中任何 `acceptance_required: true` 的阶段，agent 不允许在用户明确确认前推进到下一阶段。用户若希望松动此红线，必须显式修改流程文件（走追问协议），不允许在执行阶段隐式跳过。

## Task Plan 前置（颗粒级开发计划红线）

实际开发段的内部流程里，每个 `acceptance_required: true` 的阶段在开始编码前，必须先产出一份**颗粒级 task plan** 并经用户明确确认。任何编码、新建文件、修改既有文件的工具调用，都不允许出现在 task plan 确认之前。

### 为什么前置

- 流程模板里 `done_when` 是阶段验收门槛，不是执行步骤。done_when 之间存在大量隐含决策（先建哪个文件、依赖顺序、风险点、明确不做的事），不预先固化就会演变成"想到什么写什么"。
- 同一份流程在不同项目实例下的具体执行步骤不一样；`typical_pitfalls` 只是提醒，不能替代实际任务拆解。
- 用户对**颗粒级**的 task plan 才能 review 出"这条 task 不该做 / 应该拆得更细 / 漏了依赖"——粗粒度计划用户无从 review。

### 文件位置

每份 task plan 写入 `.project-governance/processes/tasks/<stage_id>.md`，文件名严格使用阶段 ID。

- 该目录是**项目运行时产物**，初始化时不存在；agent 在起草第一份 task plan 前 `mkdir -p` 创建即可。
- skill 模板不预置该目录与任何占位 README；这是为了避免让新项目误以为里面有可读内容。
- 一个阶段对应一个文件；阶段重做时不删旧文件，新开 `<stage_id>-rev2.md` 等并在 active.md `Mutation Log` 留痕。

### 必填字段

每份 task plan 至少包含以下区段：

- `Meta`：版本号、对应阶段 ID、起草日期、`Approved At`（用户确认后填）。
- `Tasks`：表格，每条 task 含：
  - `id`：本阶段内唯一短编号（如 `M0.1`、`M0.2`）。
  - `title`：动词开头的一句话。
  - `产出 / 验证`：可肉眼检查或机器跑过的具体产物（文件路径、命令、可见行为）。
  - `预估`：分钟或小时量级（agent 提供初稿，不强求精确）。
  - `依赖`：本表内的前置 task id 列表，或写 `—`。
- `Risks`：工作量黑洞与未知阻塞点。**不是**流程模板里的 `typical_pitfalls`（那是流程级提醒）；这里写本次实例的预估外风险，每条附"触发条件 + 兜底动作"。
- `Explicitly Not Doing`：明确划走的事（避免边界蔓延）。
- `Definition of Done`：与 active.md 对应阶段的 `done_when` 一一映射 + 本 task plan 自检条（如"已逐条勾选 task table"）。
- `Mutation Log`：执行中改动留痕表（Date / Change / Reason / User Confirmed）。

模板见 `templates/RECORD_TEMPLATES.md` 的 `Task Plan` 段。

### 颗粒度判定

颗粒级的判断标准是：**每条 task 单独失败时，agent 与用户能不混淆地指认是这条 task 而非别条**。可操作判据：

- 单条 task 产出 ≤ 1 个文件 / ≤ 1 个 entitlement / ≤ 1 个 CI 步骤；否则继续拆。
- 单条 task 预估超过 1 小时的，必须拆（高估比低估更危险）。
- 全表 task 数量上限默认 20 条；超出时反问用户是否阶段拆得过大。

### 审批

- agent 起草完 task plan 必须明确请求用户 review，按 `rules/GRILLING_PROTOCOL.md` 一次一问。
- 用户口头说"开始吧"不构成对 task plan 的确认，必须**明确针对 task plan 文件**说出"过 / 确认 / approve"等同义动作。
- 确认后由 agent 在 task plan 顶部 `Meta` 段补 `Approved At: <YYYY-MM-DD>`，并把同日期写到 `Mutation Log` 第一行。

### 执行中改动

- 已确认的 task plan 在阶段执行中允许追加 / 调整 / 删除 task，但每条改动必须：
  - 写入 task plan 文件的 `Mutation Log` 表。
  - 单次累计改动数量超过 `Process Mutation Threshold`（默认 3，与流程级阈值复用）时，agent 必须反问：是否本阶段拆解过粗、应当回到"task plan 重写"而不是继续打补丁。
- 改动等于跳过的不允许：用户明确指示"跳过这条"也必须先写入 Mutation Log，附跳过原因，再继续。

### 与流程改动的层级区分

- **task plan 改动**：同一流程阶段内的执行级调整，写在 task plan 文件的 `Mutation Log`。
- **流程阶段改动**（加 / 删 / 重排 / 改 stage）：流程级变更，按上一节"实际开发段内部流程的可变性"处理，写在 `processes/active.md` 的 `Mutation Log`。
- 发现 task 拆完后 done_when 仍达不成，是流程级问题，触发流程改动协议；发现某条具体 task 实施有偏差，是 task plan 级问题，走 task plan Mutation Log。

## 阶段回归

骨架阶段状态可回归，回归不是失败而是正常路径。典型场景：

- 第三段开发中发现需求改动 → 回归第一段，第二段视技术栈是否受影响决定是否同步回归。
- 第四段验收发现需求/架构问题 → 回归对应段。

回归动作的字段、写入规则与"回归 vs 跳过"的区分见 `rules/VERSION_RULES.md` 的"阶段回归"段。

## 跳过记录

骨架四段（需求确认、技术栈确认、实际开发、验收测试）不允许跳过，只允许在确认条件已实质满足且用户明确表达"已确认"时推进。

跳过只适用于实际开发段内部流程里 `optional: true` 的阶段。跳过时在 `ssot/PROJECT_STATE.md` 的 `Stage Skips` 段记录：阶段 ID、中文名、跳过原因、影响范围、用户明确确认时间。
