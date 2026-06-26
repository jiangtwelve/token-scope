// DecimalField.swift
//
// Decimal 文本输入控件，避免把金额阈值转换成 Double。

import SwiftUI

struct DecimalField: View {
    let title: String
    @Binding var value: Decimal
    @State private var text: String

    init(_ title: String, value: Binding<Decimal>) {
        self.title = title
        self._value = value
        self._text = State(initialValue: value.wrappedValue.description)
    }

    var body: some View {
        TextField(title, text: $text)
            .onChange(of: text) { _, newValue in
                if let decimal = Decimal(string: newValue.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    value = decimal
                }
            }
            .onChange(of: value) { _, newValue in
                if Decimal(string: text) != newValue {
                    text = newValue.description
                }
            }
    }
}
