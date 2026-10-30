//
//  CancellationSimulatorView.swift
//  SubCheck
//
//  Simulador de cancelamento: marca serviços e vê na hora quanto sobra por
//  mês e por ano. Recurso Pro.
//

import SwiftUI
import SwiftData

struct CancellationSimulatorView: View {

    @Query(sort: \Subscription.cost, order: .reverse)
    private var subscriptions: [Subscription]

    /// Assinaturas marcadas para cancelar.
    @State private var selected: Set<UUID> = []
    @State private var showPaywall = false

    private var store = StoreService.shared

    private var active: [Subscription] { subscriptions.filter { !$0.isCancelled } }

    private var monthlyTotal: Double { active.monthlyTotal(in: .shared) }

    /// Soma mensal do que foi marcado para cancelar.
    private var savedMonthly: Double {
        active
            .filter { selected.contains($0.id) }
            .monthlyTotal(in: .shared)
    }

    private var savedYearly: Double { savedMonthly * 12 }

    private var remainingMonthly: Double { max(0, monthlyTotal - savedMonthly) }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if store.hasProAccess {
                    savingsCard

                    if active.isEmpty {
                        EmptyStateView(
                            icon: "scissors",
                            title: L.t("Sem assinaturas ativas"),
                            message: L.t("Adicione serviços para simular o que você economizaria.")
                        )
                        .cardSurface()
                    } else {
                        selectionCard
                    }
                } else {
                    lockedCard
                }
            }
            .padding(Spacing.lg)
        }
        .background(Color.appBackground)
        .navigationTitle("Simulador de cancelamento")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.snappy, value: selected)
        .sheet(isPresented: $showPaywall) { ProView() }
    }

    // MARK: - Economia

    private var savingsCard: some View {
        VStack(spacing: Spacing.md) {
            Text("Você economizaria")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

            Text(Money.format(savedYearly))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: savedYearly)

            Text(L.t("%@ por ano", Money.format(savedMonthly)) + " · " + L.t("por mês"))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))

            Divider().overlay(Color.white.opacity(0.25))

            HStack(spacing: Spacing.lg) {
                summaryItem(title: L.t("Gasto atual"), value: Money.format(monthlyTotal))
                summaryItem(title: L.t("Depois de cancelar"), value: Money.format(remainingMonthly))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.xl)
        .background(
            Color.brandGradient,
            in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
        )
        .softShadow()
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Seleção

    private var selectionCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("O que você cancelaria")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if !selected.isEmpty {
                    Button(L.t("Limpar")) {
                        withAnimation(.snappy) { selected.removeAll() }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brand)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(active.enumerated()), id: \.element.id) { index, subscription in
                    row(for: subscription)

                    if index < active.count - 1 {
                        Divider().overlay(Color.hairline)
                    }
                }
            }
        }
        .cardSurface()
    }

    private func row(for subscription: Subscription) -> some View {
        let isSelected = selected.contains(subscription.id)

        return Button {
            Haptics.impact(.light)
            withAnimation(.snappy) {
                if isSelected { selected.remove(subscription.id) }
                else { selected.insert(subscription.id) }
            }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: subscription.categoryType.icon)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        subscription.categoryType.color.gradient,
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )

                VStack(alignment: .leading, spacing: 1) {
                    Text(subscription.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                    Text(Money.compact(subscription.monthlyCost(in: .shared)) + "/" + L.t("mês"))
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.danger : Color.textTertiary)
            }
            .padding(.vertical, Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bloqueio

    private var lockedCard: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "scissors")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Color.brand)
                .frame(width: 58, height: 58)
                .background(Color.brand.opacity(0.14), in: Circle())

            Text("Simulador de cancelamento")
                .font(.headline)
                .foregroundStyle(Color.textPrimary)

            Text("Descubra quanto sobra no seu bolso ao cortar serviços. Faz parte do SubCheck Pro.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                Haptics.impact(.light)
                showPaywall = true
            } label: {
                Text("Ver o SubCheck Pro")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(
                        Color.brandGradient,
                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .cardSurface(padding: Spacing.xl)
    }
}
