// DesignTokensTests.swift
import Testing
@testable import TSDesignSystem

@Suite("DesignTokens")
struct DesignTokensTests {
    @Test
    func spacingValuesAreAscending() {
        #expect(DesignTokens.Spacing.xs < DesignTokens.Spacing.sm)
        #expect(DesignTokens.Spacing.sm < DesignTokens.Spacing.md)
        #expect(DesignTokens.Spacing.md < DesignTokens.Spacing.lg)
        #expect(DesignTokens.Spacing.lg < DesignTokens.Spacing.xl)
    }
}
