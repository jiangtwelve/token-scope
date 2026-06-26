// TokenScopeApp.swift
//
// macOS App 入口。M0 阶段仅一个静态欢迎窗口；M2 阶段替换为 ProviderList。

import SwiftUI

@main
struct TokenScopeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}
