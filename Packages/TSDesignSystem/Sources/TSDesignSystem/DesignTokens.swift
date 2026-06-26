// DesignTokens.swift
//
// 设计系统的最小公共 token。M2 阶段会扩展为 Color / Spacing / Typography / BalanceCard。
// 这里保留一个真实的、可长期存在的 spacing token，避免 TSDesignSystem target 为空。

import Foundation

public enum DesignTokens: Sendable {
    public enum Spacing: Sendable {
        public static let xs: Double = 4
        public static let sm: Double = 8
        public static let md: Double = 12
        public static let lg: Double = 16
        public static let xl: Double = 24
    }
}
