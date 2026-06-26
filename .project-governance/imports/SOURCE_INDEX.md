# Source Index

已有项目文档导入索引。导入规则见 `rules/DOCUMENTATION_RULES.md`。

| Source Path | Type | Trust Level | Import Status | Imported Into | Notes |
|---|---|---|---|---|---|
| `cc-switch/src-tauri/src/services/balance.rs` | Reference code (Rust) | High | reference-only | API_CONTRACT §DeepSeek、ARCH §UsageSnapshot 字段映射 | DeepSeek `/user/balance` 调用模式、字段语义、错误三态（成功/网络错/401-403 失效）全部以本文件为权威参照；token-scope 用 Swift 重写、字段一比一对齐 |
| `cc-switch/src-tauri/src/services/coding_plan.rs` | Reference code (Rust) | High | reference-only | Backlog B-004 / B-005 | 火山方舟 SigV4 实现 + Coding Plan quota tier 模型；v0.3 平移时回看 |
| `cc-switch/src/config/codingPlanProviders.ts` | Reference code (TS) | High | reference-only | Backlog B-005 | Coding Plan 供应商 URL 检测表，v0.3 平移时复用模式 |
| `cc-switch/src/types/usage.ts` | Reference code (TS) | High | reference-only | ARCH §Data model（UsageSnapshot） | UsageData 字段定义参照源 |
| `cc-switch/src/components/UsageFooter.tsx` | Reference code (TSX) | Medium | reference-only | PRD §Interaction（Widget 卡片设计参考） | 卡片态、失效态、刷新时间相对值 UI 表达 |
| `cc-switch/README.md` 系列 | Reference docs | Low | reference-only | — | 仅作背景理解；token-scope 不复用其文案 |
