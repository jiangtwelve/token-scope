# D-005: v0.1 后台模型——菜单栏常驻 + 开机自启

- ID: D-005
- Date: 2026-06-24
- Title: v0.1 后台模型：菜单栏常驻 + 开机自启；不上 LaunchAgent
- Area: Background Execution
- Status: accepted
- Related SSOT: `ssot/ARCHITECTURE.md §Tech stack §System overview`、`ssot/PRD.md §F-104`

## Context

`NSBackgroundActivityScheduler` 只有在主 App 运行期间才能被系统调度。这就意味着：

- 用户主动 Quit 主 App 后，后台刷新即停
- 用户合上 Mac 一夜，回来 widget 是隔夜数据

三个候选方案：

- A. **菜单栏常驻 + 开机自启**：App 始终在跑，90% 场景刷新正常；Quit 后停刷新
- B. LaunchAgent 独立 headless 进程：App Quit 后仍刷新；但配置/部署复杂、部分 macOS 用户反感后台进程
- C. App 不常驻，Widget 点击时手动刷新：ambient 体验打折扣，违背 S1 痛点

## Options

见上。

## Chosen

A。

- 用 `SMAppService.mainApp.register()` 注册 Login Item，开机随系统启动
- App 默认以菜单栏图标常驻（用户可在设置里勾选"隐藏菜单栏图标"，但 App 仍后台在跑）
- `NSBackgroundActivityScheduler` 30 分钟一次，设置里可改 15/30/60/关闭
- 用户主动 Quit 后接受刷新停止（README 写清楚）

## Impact

- ARCHITECTURE §System overview 增加"开机随 ServiceManagement 拉起"标注
- PRD F-104 默认 30 分钟，可在设置里改 15/30/60/关闭
- 设置面板必须有"开机自启"开关 + "隐藏菜单栏图标"开关
- M3_ambient_layer 阶段 done_when 明确包含 SMAppService + 设置面板
- v0.1 unsigned build 下 `SMAppService.mainApp.register()` 成功率可能不稳，接受"可能失败一次，第二次成功"

## Follow-ups

- v0.2 若用户反馈"Quit 后也想要 widget 刷新"强烈，再评估 LaunchAgent（已登记 B-015）
- v0.2 上 Developer ID 后 SMAppService 成功率应回到 100%
