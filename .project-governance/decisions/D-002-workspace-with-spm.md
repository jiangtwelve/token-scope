# D-002: Workspace + 4 个 SPM 包 + App/Widget Extension target

- ID: D-002
- Date: 2026-06-24
- Title: Workspace + 4 个 SPM 包 + App/Widget Extension target
- Area: Project Layout
- Status: accepted
- Related SSOT: `ssot/ARCHITECTURE.md §Module boundaries`

## Context

需要决定 v0.1 的 Xcode 工程结构。三个选项的关键差别：能否 `swift test` 脱离 Xcode 跑、代码分层是否被强制、v0.2 上 iOS 时复用难度。

## Options

- A. **Workspace + 4 个 SPM 包 + App/Widget target** ← chosen
- B. 单 xcodeproj + 文件夹划分（最简但分层不强制）
- C. Tuist 生成工程（学习曲线 + 额外工具）

## Chosen

A。顶层 `TokenScope.xcworkspace`，包含：

- `Packages/` 下四个独立 SPM 包：`TSCore` / `TSProviders` / `TSStorage` / `TSDesignSystem`，可独立 `swift test`
- `Apps/TokenScope-macOS.xcodeproj`：主 App + Widget Extension target
- 4 个 SPM 包均声明 macOS 14 + iOS 17 双平台（见 D-003 关联决策）

## Impact

- CI 设计简化：SPM 包 `swift test` + App `xcodebuild build` 两步走（见 AC-8）
- v0.2 上 iOS = 加 `Apps/TokenScope-iOS` 与 iOS Widget Extension target；SPM 包零改动复用
- 分层被工程强制：`Apps` / `Widgets` 不能反过来被 SPM 包依赖
- Swift Testing 在 SPM 包内更自然，CI 不需要起 simulator/macOS app

## Follow-ups

- M0_skeleton_bootstrap 阶段产出空壳，CI 第一次跑通即视为本决策落地
- 第三段任何"放到哪一层"的争议回看本决策的依赖方向图

## Revisions

| Date | Change | Reason | User Confirmed |
|---|---|---|---|
| 2026-06-25 | 增补 XcodeGen 作为 xcodeproj 生成器（构建期工具，不进运行时依赖）；`*.xcodeproj/` 进 .gitignore | M0.8/M0.9 执行前评估：手写 pbxproj 风险高、Xcode UI 创建无 diff 友好 | 见 tasks/M0_skeleton_bootstrap.md Mutation Log |
