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
    /// Paywall aberto pelo limite de assinaturas ou pela Análise bloqueada.
    @State private var showPaywall = false
    @State private var paywallReason: String?
    /// Categoria destacada no gráfico; filtra o resto do painel.
    @State private var selectedCategory: CategoryType?
    /// Teto mensal definido nas Ajustes (ver `Budget`).
    @AppStorage(Budget.amountKey) private var monthlyBudget = 0.0

    private var store = StoreService.shared

    private var active: [Subscription] { subscriptions.filter { !$0.isCancelled } }

    /// `true` quando a versão gratuita ainda permite cadastrar.
    private var canAddMore: Bool {
        store.hasProAccess || active.count < StoreService.freeLimit
    }

    private var filteredActive: [Subscription] {
        guard let selectedCategory else { return active }
        return active.filter { $0.categoryType == selectedCategory }
    }

    private var monthlyTotal: Double { active.monthlyTotal(in: .shared) }
    private var yearlyTotal: Double { monthlyTotal * 12 }
    private var averageCost: Double { active.isEmpty ? 0 : monthlyTotal / Double(active.count) }
    private var dueSoonCount: Int { active.filter { $0.daysUntilNextBilling <= 7 }.count }
    private var dailyCost: Double { monthlyTotal / 30.44 }
    private var next30Total: Double { InsightsService.upcomingTotal(active, days: 30) }

    /// Assinatura que mais pesa no mês, já convertida para a moeda base.
    private var priciest: Subscription? {
        active.max { $0.monthlyCost(in: .shared) < $1.monthlyCost(in: .shared) }
    }

    /// Quanto os cancelamentos já tiram do gasto anual.
    private var cancelledYearlySavings: Double {
        subscriptions.filter(\.isCancelled).reduce(0) { $0 + $1.yearlyCost(in: .shared) }
    }

    private var nextCharge: Subscription? {
        active.min { $0.nextBillingDate < $1.nextBillingDate }
    }

    private var insights: [Insight] { InsightsService.insights(for: subscriptions) }

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
                            title: L.t("Assinaturas ativas"),
                            value: "\(active.count)",
                            icon: "checkmark.seal.fill",
                            tint: .brand
                        )
                        MetricCard(
                            title: L.t("Custo anual"),
                            value: Money.compact(yearlyTotal),
                            icon: "calendar",
                            tint: .info
                        )
                        MetricCard(
                            title: L.t("Vencem em 7 dias"),
                            value: "\(dueSoonCount)",
                            icon: "bell.badge.fill",
                            tint: dueSoonCount > 0 ? .warning : .success
                        )
                        MetricCard(
                            title: L.t("Média por serviço"),
                            value: Money.format(averageCost),
                            icon: "chart.bar.fill",
                            tint: .textSecondary
                        )
                        MetricCard(
                            title: L.t("A pagar em 30 dias"),
                            value: Money.compact(next30Total),
                            icon: "creditcard.fill",
                            tint: .brandSecondary
                        )
                        MetricCard(
                            title: L.t("Custo por dia"),
                            value: Money.format(dailyCost),
                            icon: "sun.max.fill",
                            tint: .warning
                        )
                        MetricCard(
                            title: L.t("Maior assinatura"),
                            value: priciest?.name ?? "—",
                            icon: "crown.fill",
                            tint: .danger,
                            subtitle: priciest.map { L.t("subscription.perMonth", Money.format($0.monthlyCost(in: .shared))) }
                        )
                        MetricCard(
                            title: L.t("Economia anual"),
                            value: Money.compact(cancelledYearlySavings),
                            icon: "leaf.fill",
                            tint: .success,
                            subtitle: cancelledYearlySavings > 0 ? L.t("com cancelamentos") : nil
                        )
                    }

                    if active.isEmpty {
                        EmptyStateView(
                            icon: "tray",
                            title: L.t("Nenhuma assinatura"),
                            message: L.t("Toque em + para adicionar sua primeira assinatura e acompanhar seus gastos."),
                            actionTitle: L.t("Adicionar assinatura")
                        ) { startAdding() }
                        .cardSurface()
                    } else {
                        CategoryDonutChart(subscriptions: active, selection: $selectedCategory)

                        if selectedCategory != nil {
                            activeFilterChip
                        }

                        TopSubscriptionsChart(subscriptions: filteredActive)
                        TrialsCard(subscriptions: active)
                        UpcomingPaymentsSection(subscriptions: filteredActive)

                        InsightsCard(insights: insights, hasPro: store.hasProAccess) {
                            paywallReason = L.t("Os insights completos fazem parte do SubCheck Pro.")
                            showPaywall = true
                        }
                    }

                    if store.hasProAccess, monthlyBudget > 0 {
                        BudgetCard(spent: monthlyTotal, budget: monthlyBudget)
                    }

                    analysisLink
                }
                .padding(Spacing.lg)
                .animation(.snappy, value: selectedCategory)
                .animation(.snappy, value: active.isEmpty)
            }
            .background(Color.appBackground)
            .navigationTitle("Resumo")
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
                ProView(reason: paywallReason)
            }
        }
    }

    // MARK: - Limite da versão gratuita

    /// Abre o formulário ou o paywall quando o limite é atingido.
    private func startAdding() {
        guard canAddMore else {
            Haptics.warning()
            paywallReason = L.t(
                "Você atingiu o limite de %lld assinaturas ativas.",
                StoreService.freeLimit
            )
            showPaywall = true
            return
        }
        showAddSheet = true
    }

    /// Chip mostrado quando uma fatia do gráfico está selecionada.
    private var activeFilterChip: some View {
        HStack(spacing: Spacing.sm) {
            if let selectedCategory {
                Label(selectedCategory.displayName, systemImage: selectedCategory.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(selectedCategory.color)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(selectedCategory.color.opacity(0.15), in: Capsule())
            }

            Spacer(minLength: 0)

            Button {
                Haptics.impact(.light)
                withAnimation(.snappy) { selectedCategory = nil }
            } label: {
                Label(L.t("Limpar filtro"), systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var analysisLink: some View {
        Group {
            if store.hasProAccess {
                NavigationLink {
                    AnalysisView()
                } label: {
                    analysisLabel
                }
            } else {
                Button {
                    Haptics.impact(.light)
                    paywallReason = L.t("A Análise completa faz parte do SubCheck Pro.")
                    showPaywall = true
                } label: {
                    analysisLabel
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var analysisLabel: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "chart.xyaxis.line")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(Color.brandGradient, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Análise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("Evolução dos gastos")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer(minLength: 0)

            if store.hasProAccess {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
            } else {
                Label(L.t("Pro"), systemImage: "lock.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.warning)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color.warning.opacity(0.15), in: Capsule())
            }
        }
        .cardSurface()
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
                Label(L.t("dashboard.perYear", Money.compact(yearlyTotal)), systemImage: "calendar")
                Label(L.t("dashboard.services", active.count), systemImage: "square.stack.3d.up.fill")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.9))
            .contentTransition(.numericText())
            .animation(.snappy, value: active.count)
            .padding(.top, Spacing.xs)

            if let nextCharge {
                Label(
                    L.t("Próxima: %@ em %lld dia(s)", nextCharge.name, nextCharge.daysUntilNextBilling),
                    systemImage: "arrow.triangle.2.circlepath"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(.white.opacity(0.18), in: Capsule())
                .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .background(Color.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .softShadow()
    }
}
