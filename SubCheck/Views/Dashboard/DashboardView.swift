//
//  DashboardView.swift
//  SubCheck
//
//  KPI overview: totals, category split, biggest costs and upcoming charges.
//

import SwiftUI
import SwiftData

struct DashboardView: View {

    @Query(sort: \Subscription.cost, order: .reverse)
    private var subscriptions: [Subscription]

    @State private var showAddSheet = false

    private var active: [Subscription] { subscriptions.filter { !$0.isCancelled } }

    private var monthlyTotal: Double { active.reduce(0) { $0 + $1.monthlyCost } }
    private var yearlyTotal: Double { monthlyTotal * 12 }
    private var averageCost: Double { active.isEmpty ? 0 : monthlyTotal / Double(active.count) }
    private var dueSoonCount: Int { active.filter { $0.daysUntilNextBilling <= 7 }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    heroCard

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: Spacing.md),
                                  GridItem(.flexible(), spacing: Spacing.md)],
                        spacing: Spacing.md
                    ) {
                        MetricCard(
                            title: "Assinaturas ativas",
                            value: "\(active.count)",
                            icon: "checkmark.seal.fill",
                            tint: .brand
                        )
                        MetricCard(
                            title: "Custo anual",
                            value: Money.compact(yearlyTotal),
                            icon: "calendar",
                            tint: .info
                        )
                        MetricCard(
                            title: "Vencem em 7 dias",
                            value: "\(dueSoonCount)",
                            icon: "bell.badge.fill",
                            tint: dueSoonCount > 0 ? .warning : .success
                        )
                        MetricCard(
                            title: "Média por serviço",
                            value: Money.format(averageCost),
                            icon: "chart.bar.fill",
                            tint: .textSecondary
                        )
                    }

                    if active.isEmpty {
                        EmptyStateView(
                            icon: "tray",
                            title: "Nenhuma assinatura",
                            message: "Toque em + para adicionar sua primeira assinatura e acompanhar seus gastos.",
                            actionTitle: "Adicionar assinatura"
                        ) { showAddSheet = true }
                        .cardSurface()
                    } else {
                        CategoryDonutChart(subscriptions: active)
                        TopSubscriptionsChart(subscriptions: active)
                        UpcomingPaymentsSection(subscriptions: active)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle("Resumo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        showAddSheet = true
                    } label: {
                        Label("Nova assinatura", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddSubscriptionView()
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Total mensal")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            Text(Money.format(monthlyTotal))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: monthlyTotal)

            HStack(spacing: Spacing.lg) {
                Label("\(Money.compact(yearlyTotal)) por ano", systemImage: "calendar")
                Label("\(active.count) serviços", systemImage: "square.stack.3d.up.fill")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.9))
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .background(Color.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .softShadow()
    }
}
