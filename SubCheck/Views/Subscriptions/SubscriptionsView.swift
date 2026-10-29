//
//  SubscriptionsView.swift
//  SubCheck
//

import SwiftUI
import SwiftData

struct SubscriptionsView: View {

    @Environment(\.modelContext) private var context
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]

    @State private var search = ""
    @State private var showAddSheet = false
    /// Paywall aberto quando o limite da versão gratuita é atingido.
    @State private var showPaywall = false

    private var store = StoreService.shared

    private var filtered: [Subscription] {
        guard !search.isEmpty else { return subscriptions }
        return subscriptions.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var activeList: [Subscription] { filtered.filter { !$0.isCancelled } }
    private var cancelledList: [Subscription] { filtered.filter(\.isCancelled) }

    /// `true` quando a versão gratuita ainda permite cadastrar.
    private var canAddMore: Bool {
        store.isPro || subscriptions.filter { !$0.isCancelled }.count < StoreService.freeLimit
    }

    private var monthlyTotal: Double {
        activeList.monthlyTotal(in: .shared)
    }

    var body: some View {
        NavigationStack {
            Group {
                if subscriptions.isEmpty {
                    ScrollView {
                        EmptyStateView(
                            icon: "list.bullet.rectangle.portrait",
                            title: L.t("Sem assinaturas"),
                            message: L.t("Adicione serviços para acompanhar cobranças e gastos."),
                            actionTitle: L.t("Adicionar assinatura")
                        ) { startAdding() }
                        .cardSurface()
                        .padding(Spacing.lg)
                    }
                    .background(Color.appBackground)
                } else {
                    List {
                        if !activeList.isEmpty {
                            Section {
                                ForEach(activeList) { row(for: $0) }
                            } header: {
                                sectionHeader("Ativas", count: activeList.count)
                            }
                        }

                        if !cancelledList.isEmpty {
                            Section {
                                ForEach(cancelledList) { row(for: $0) }
                            } header: {
                                sectionHeader("Canceladas", count: cancelledList.count)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .animation(.snappy, value: monthlyTotal)
                    .animation(.snappy, value: activeList.map(\.id))
                }
            }
            .navigationTitle("Assinaturas")
            .searchable(text: $search, prompt: "Buscar assinatura")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        startAdding()
                    } label: {
                        Label("Nova assinatura", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddSubscriptionView()
            }
            .sheet(isPresented: $showPaywall) {
                ProView(
                    reason: L.t(
                        "Você atingiu o limite de %lld assinaturas ativas.",
                        StoreService.freeLimit
                    )
                )
            }
        }
    }

    /// Abre o formulário ou o paywall quando o limite é atingido.
    private func startAdding() {
        guard canAddMore else {
            Haptics.warning()
            showPaywall = true
            return
        }
        showAddSheet = true
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(L.t(title))
            Spacer()
            if title == "Ativas" {
                Text(L.t("subscription.perMonth", Money.format(monthlyTotal)))
                    .contentTransition(.numericText())
            } else {
                Text("\(count)")
            }
        }
    }

    @ViewBuilder
    private func row(for subscription: Subscription) -> some View {
        NavigationLink {
            SubscriptionDetailView(subscription: subscription)
        } label: {
            SubscriptionRowView(subscription: subscription)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Haptics.warning()
                withAnimation { SubscriptionStore.delete(subscription, in: context) }
            } label: {
                Label("Excluir", systemImage: "trash")
            }

            Button {
                Haptics.impact()
                withAnimation { SubscriptionStore.toggleCancelled(subscription, in: context) }
            } label: {
                Label(
                    subscription.isCancelled ? "Reativar" : "Cancelar",
                    systemImage: subscription.isCancelled ? "arrow.uturn.backward" : "xmark.circle"
                )
            }
            .tint(subscription.isCancelled ? .success : .warning)
        }
        .contextMenu {
            Button {
                Haptics.impact()
                SubscriptionStore.toggleCancelled(subscription, in: context)
            } label: {
                Label(
                    subscription.isCancelled ? "Reativar" : "Cancelar assinatura",
                    systemImage: subscription.isCancelled ? "arrow.uturn.backward" : "xmark.circle"
                )
            }

            Button(role: .destructive) {
                Haptics.warning()
                SubscriptionStore.delete(subscription, in: context)
            } label: {
                Label("Excluir", systemImage: "trash")
            }
        }
    }
}
