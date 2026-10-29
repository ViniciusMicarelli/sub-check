//
//  EmptyStateView.swift
//  SubCheck
//

import SwiftUI

struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.brand)

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(.brand)
                    .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
    }
}
