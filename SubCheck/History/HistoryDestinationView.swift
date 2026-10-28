//
//  HistoryView.swift
//  SubCheck
//
//  View for subscription history
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]
    
    var body: some View {
        NavigationStack {
            List {
                if subscriptions.isEmpty {
                    ContentUnavailableView("Nenhum histórico", systemImage: "clock.fill",
                        description: Text("Nenhuma assinatura encontrada no histórico."))
                } else {
                    ForEach(subscriptions) { subscription in
                        HistorySubscriptionRowView(subscription: subscription)
                    }
                }
            }
            .navigationTitle("Histórico")
            .searchable(text: \.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Limpar Histórico") {
                        clearHistory()
                    }
                }
            }
        }
    }
    
    private func clearHistory() {
        modelContext.delete(subscriptions)
    }
}

struct HistorySubscriptionRowView: View {
    let subscription: Subscription
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundStyle(categoryColor(for: subscription.category))
                
                Text("Vencimento: \(subscription.nextBillingDate.formatted(date: .numeric, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(subscription.cost, format: .currency(code: subscription.currencyCode))
                    .font(.subheadline)
                    .bold()
                
                Text(subscription.frequency.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
            }
        }
        .padding(14)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "entretenimento": return .purple
        case "trabalho": return .blue
        case "saúde": return .green
        case "utilitários": return .orange
        default: return .gray
        }
    }
}

#Preview {
    HistoryView()
}
