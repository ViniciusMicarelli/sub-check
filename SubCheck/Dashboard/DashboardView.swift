import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    
    @State private var isAddingSubscription = false
    
    private var totalMonthlyExpense: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyCost }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Card de Resumo Financeiro
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gasto Mensal Estimado")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(totalMonthlyExpense, format: .currency(code: "BRL"))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 8)
                }
                
                // Lista de Assinaturas
                Section("Minhas Assinaturas (\(subscriptions.count))") {
                    if subscriptions.isEmpty {
                        ContentUnavailableView(
                            "Nenhuma assinatura",
                            systemImage: "creditcard.and.123",
                            description: Text("Toque no botão + para adicionar sua primeira assinatura.")
                        )
                    } else {
                        ForEach(subscriptions) { item in
                            SubscriptionRowView(subscription: item)
                        }
                        .onDelete(perform: deleteSubscriptions)
                    }
                }
            }
            .navigationTitle("SubCheck")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingSubscription = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingSubscription) {
                AddSubscriptionView()
            }
            .task {
                _ = await NotificationManager.shared.requestAuthorization()
            }
        }
    }
    
    private func deleteSubscriptions(offsets: IndexSet) {
        for index in offsets {
            let subscription = subscriptions[index]
            NotificationManager.shared.cancelNotification(for: subscription)
            modelContext.delete(subscription)
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                
                Text("Próximo vencimento: \(subscription.nextBillingDate.formatted(date: .numeric, time: .omitted))")
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
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
    }
}