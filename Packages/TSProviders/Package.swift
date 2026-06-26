// swift-tools-version: 6.0
//
// TSProviders — 上游用量数据采集层。v0.1 仅含 DeepSeek。
// 字段语义对齐 cc-switch/src-tauri/src/services/balance.rs（参考源，非依赖）。
// 详见 .project-governance/ssot/ARCHITECTURE.md §Module boundaries 与
//     .project-governance/imports/SOURCE_INDEX.md。

import PackageDescription

let package = Package(
    name: "TSProviders",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "TSProviders", targets: ["TSProviders"]),
    ],
    dependencies: [
        .package(path: "../TSCore"),
    ],
    targets: [
        .target(
            name: "TSProviders",
            dependencies: ["TSCore"]
        ),
        .testTarget(
            name: "TSProvidersTests",
            dependencies: ["TSProviders"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
