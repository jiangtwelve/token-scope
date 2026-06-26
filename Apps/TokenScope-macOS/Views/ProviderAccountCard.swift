// ProviderAccountCard.swift
//
// 主列表里的单账号卡片，集中展示余额与 refresh/edit/delete 操作。

import SwiftUI
import TSCore

struct ProviderAccountCard: View {
    let row: AccountListViewModel.AccountRow
    let onRefresh: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.account.label)
                        .font(.headline)
                    Text(row.account.baseURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge
            }

            HStack(alignment: .firstTextBaseline) {
                Text(balanceText)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                Spacer()
                Text(lastRefreshText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let message = detailMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(detailColor)
            }

            HStack {
                Button(action: onRefresh) {
                    Label(row.isRefreshing ? "刷新中" : "刷新", systemImage: "arrow.clockwise")
                }
                .disabled(row.isRefreshing)

                Button("编辑", action: onEdit)
                Button("删除", role: .destructive, action: onDelete)
                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var statusBadge: some View {
        Text(statusText)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.16))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }

    private var statusText: String {
        guard let snapshot = row.latestSnapshot else { return "未刷新" }
        switch snapshot.status {
        case .success: return "正常"
        case .invalid: return "账号失效"
        case .failure: return "刷新失败"
        }
    }

    private var statusColor: Color {
        guard let snapshot = row.latestSnapshot else { return .secondary }
        switch snapshot.status {
        case .success: return .green
        case .invalid: return .orange
        case .failure: return .red
        }
    }

    private var balanceText: String {
        guard let snapshot = row.latestSnapshot else { return "—" }
        guard let remaining = snapshot.remaining else { return "— \(snapshot.unit ?? "")" }
        return "\(remaining) \(snapshot.unit ?? "")"
    }

    private var lastRefreshText: String {
        guard let date = row.latestSnapshot?.fetchedAt else { return "尚未刷新" }
        return date.formatted(.relative(presentation: .named))
    }

    private var detailMessage: String? {
        guard let snapshot = row.latestSnapshot else { return "点击刷新获取余额" }
        switch snapshot.status {
        case .success:
            return snapshot.isValid == false ? snapshot.invalidMessage : nil
        case .invalid:
            return snapshot.invalidMessage
        case .failure:
            return snapshot.errorMessage
        }
    }

    private var detailColor: Color {
        guard let snapshot = row.latestSnapshot else { return .secondary }
        switch snapshot.status {
        case .success: return .secondary
        case .invalid: return .orange
        case .failure: return .red
        }
    }
}
