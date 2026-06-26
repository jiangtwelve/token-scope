# Decision Log Index

默认只读取本索引。只有当前任务需要追溯某个决策原因时，才读取对应决策文件。

| ID | Date | Area | Title | Status | File |
|---|---|---|---|---|---|
| D-001 | 2026-06-24 | Distribution | v0.1 不签名不公证，仅本机 + 开源代码 | accepted | D-001-distribution-local-only.md |
| D-002 | 2026-06-24 | Project Layout | Workspace + 4 个 SPM 包 + App/Widget Extension target | accepted | D-002-workspace-with-spm.md |
| D-003 | 2026-06-24 | Concurrency / Persistence | GRDB 7 + Swift 6 strict concurrency=complete | accepted | D-003-grdb7-swift6-strict.md |
| D-004 | 2026-06-24 | Testing | v0.1 测试基线豁免 80% 全局红线：领域 + 解码表驱动 + UI/Storage smoke | accepted | D-004-testing-baseline-exemption.md |
| D-005 | 2026-06-24 | Background Execution | v0.1 后台模型：菜单栏常驻 + 开机自启；不上 LaunchAgent | accepted | D-005-background-stay-resident.md |
| D-006 | 2026-06-24 | Security | v0.1 unsigned build 下使用 non-shared Keychain；v0.2 切回 Access Group | accepted | D-006-keychain-v0.1-non-shared.md |

Status: `proposed`, `accepted`, `superseded`, `rejected`.
