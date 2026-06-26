// ContentView.swift
//
// 主窗口根视图。M2 起承载真实账号列表 UI。

import SwiftUI

struct ContentView: View {
    private let bootstrapResult = Result { try AppBootstrap.makeDefault() }

    var body: some View {
        switch bootstrapResult {
        case .success(let bootstrap):
            ProviderListView(viewModel: AccountListViewModel(bootstrap: bootstrap))
        case .failure(let error):
            ContentUnavailableView(
                "Token Scope 启动失败",
                systemImage: "exclamationmark.triangle",
                description: Text("\(error)")
            )
            .frame(minWidth: 520, minHeight: 360)
        }
    }
}

#Preview {
    ContentView()
}
