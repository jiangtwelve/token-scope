// TokenScopeWidget.swift
//
// macOS Widget Extension 入口（M0 占位）。M4 阶段替换为 BalanceWidget 读 App Group SQLite。
//
// 严格并发说明：TimelineProvider 在 Swift 6 + WidgetKit 下，completion 闭包默认 @Sendable。
// 用 async/await 形式可绕开 completion handler 的 sendability 标注问题。

import WidgetKit
import SwiftUI
// M0.11 link 验证：Widget Extension 能从 TSCore import。M4 起改为 import TSStorage 读共享 SQLite。
import TSCore

@main
struct TokenScopeWidgetBundle: WidgetBundle {
    var body: some Widget {
        TokenScopePlaceholderWidget()
    }
}

struct TokenScopePlaceholderWidget: Widget {
    let kind: String = "TokenScopePlaceholder"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TokenScopePlaceholderProvider()) { entry in
            TokenScopePlaceholderView(entry: entry)
        }
        .configurationDisplayName("Token Scope")
        .description("Placeholder — populates in M4")
        .supportedFamilies([.systemMedium])
    }
}

struct TokenScopePlaceholderEntry: TimelineEntry, Sendable {
    let date: Date
}

struct TokenScopePlaceholderProvider: TimelineProvider {
    typealias Entry = TokenScopePlaceholderEntry

    func placeholder(in context: Context) -> TokenScopePlaceholderEntry {
        TokenScopePlaceholderEntry(date: Date())
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping @Sendable (TokenScopePlaceholderEntry) -> Void
    ) {
        completion(TokenScopePlaceholderEntry(date: Date()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping @Sendable (Timeline<TokenScopePlaceholderEntry>) -> Void
    ) {
        let entry = TokenScopePlaceholderEntry(date: Date())
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct TokenScopePlaceholderView: View {
    var entry: TokenScopePlaceholderEntry

    var body: some View {
        VStack(spacing: 6) {
            Text("Token Scope")
                .font(.headline)
            Text("Placeholder")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("M4 将接入真实数据")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            // M1 link 验证：使用 TSCore 的真实类型，避免 M0 占位类型残留。
            Text("provider=\(Provider.deepSeek.id)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.tertiary.opacity(0.7))
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
