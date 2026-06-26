// swift-tools-version: 6.0
//
// TSCore — 领域层（纯 Swift，0 框架依赖）。
// 详见 .project-governance/ssot/ARCHITECTURE.md §Module boundaries。
//
// Swift 6 语言模式开启 → 严格并发为默认（Sendable 等强制编译期检查）。
// 详见 decisions/D-003。

import PackageDescription

let package = Package(
    name: "TSCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "TSCore", targets: ["TSCore"]),
    ],
    targets: [
        .target(name: "TSCore"),
        .testTarget(name: "TSCoreTests", dependencies: ["TSCore"]),
    ],
    swiftLanguageModes: [.v6]
)
