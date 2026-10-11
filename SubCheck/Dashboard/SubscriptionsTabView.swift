import SwiftUI
import SwiftData

struct SubscriptionsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @State private var isAddingSubscription = false
    @State private var selectedSubscription: Subscription?

    var body: some View {
        NavigationStack {
            List {
                if subscriptions.isEmpty {
                    ContentUnavailableView("Nenhuma assinatura", systemImage: "creditcard",
                        description: Text("Adicione suas primeiras assinaturas para começar."))
                } else {
                    ForEach(subscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button {
                                    selectedSubscription = subscription
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.accentColor)
                                Button(role: .destructive) {
                                    NotificationManager.shared.cancelNotification(for: subscription)
                                    modelContext.delete(subscription)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button("Editar") { selectedSubscription = subscription }
                                Button("Excluir", role: .destructive) {
                                    NotificationManager.shared.cancelNotification(for: subscription)
                                    modelContext.delete(subscription)
                                }
                            }
                    }
                }
            }
            .navigationTitle("Assinaturas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isAddingSubscription = true } label: {
                        Label("Nova Assinatura", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingSubscription) { AddSubscriptionView() }
            .sheet(item: $selectedSubscription) { EditSubscriptionView(initialSubscription: $0) }
        }
    }
}
