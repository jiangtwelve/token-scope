// swift-tools-version: 6.0
//
// TSStorage — 持久化层。GRDB 7（SQLite） + Keychain。
//
// GRDB 锁版本 ≥ 7.0.0，与 Swift 6 严格并发模式适配最好。
// 详见 .project-governance/ssot/ARCHITECTURE.md §Tech stack 与 decisions/D-003。

import PackageDescription

let package = Package(
    name: "TSStorage",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "TSStorage", targets: ["TSStorage"]),
    ],
    dependencies: [
        .package(path: "../TSCore"),
        .package(
            url: "https://github.com/groue/GRDB.swift.git",
            from: "7.0.0"
        ),
    ],
    targets: [
        .target(
            name: "TSStorage",
            dependencies: [
                "TSCore",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(
            name: "TSStorageTests",
            dependencies: ["TSStorage"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
