// swift-tools-version: 6.0
//
// TSDesignSystem — 设计系统：Color / Spacing / Typography tokens + 共用组件。
// 双平台声明（macOS 14 + iOS 17）使 v0.2 上 iOS 时零改动复用。

import PackageDescription

let package = Package(
    name: "TSDesignSystem",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "TSDesignSystem", targets: ["TSDesignSystem"]),
    ],
    dependencies: [
        .package(path: "../TSCore"),
    ],
    targets: [
        .target(
            name: "TSDesignSystem",
            dependencies: ["TSCore"]
        ),
        .testTarget(
            name: "TSDesignSystemTests",
            dependencies: ["TSDesignSystem"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
