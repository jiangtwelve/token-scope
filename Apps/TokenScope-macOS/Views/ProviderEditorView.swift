// ProviderEditorView.swift
//
// DeepSeek 账号新增/编辑弹窗。

import SwiftUI
import TSProviders

struct ProviderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var input: AccountEditorInput
    @State private var isAPIKeyVisible = false
    let onSave: (AccountEditorInput) async -> Bool

    init(input: AccountEditorInput, onSave: @escaping (AccountEditorInput) async -> Bool) {
        self._input = State(initialValue: input)
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(input.id == nil ? "新增 DeepSeek 账号" : "编辑 DeepSeek 账号")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 10) {
                TextField("账号名称", text: $input.label)
                TextField("Base URL", text: $input.baseURL)
                    .textContentType(.URL)

                HStack {
                    if isAPIKeyVisible {
                        TextField("API Key", text: $input.apiKey)
                    } else {
                        SecureField("API Key", text: $input.apiKey)
                    }
                    Button {
                        isAPIKeyVisible.toggle()
                    } label: {
                        Image(systemName: isAPIKeyVisible ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }

                HStack {
                    DecimalField("低余额阈值", value: $input.thresholdAmount)
                    Text("CNY")
                        .foregroundStyle(.secondary)
                }
            }
            .textFieldStyle(.roundedBorder)

            Text("API Key 会保存到 macOS Keychain，不会写入 SQLite。")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") {
                    Task {
                        if await onSave(input) {
                            dismiss()
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
