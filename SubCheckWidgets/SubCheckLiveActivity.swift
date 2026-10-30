//
//  SubCheckLiveActivity.swift
//  SubCheckWidgets
//
//  Live Activity da próxima cobrança. A contagem regressiva e a barra de
//  progresso usam `Text(timerInterval:)` e `ProgressView(timerInterval:)`:
//  o sistema anima sozinho, sem precisar de atualizações nem de push.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct SubCheckLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SubCheckActivityAttributes.self) { context in
            lockScreen(context)
                .widgetURL(deepLink(context.state))
                .activityBackgroundTint(Color.cardBackground)
                .activitySystemActionForegroundColor(Color.brand)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    islandBadge(context.state)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(Money.compact(context.state.monthlyTotal))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                        Text(L.t("Total mensal"))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.state.nextName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        CountdownText(until: context.state.nextDueDate)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.warning)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    islandUpcoming(context.state)
                }
            } compactLeading: {
                Image(systemName: symbol(for: context.state.nextCategory))
                    .foregroundStyle(color(for: context.state.nextCategory))
            } compactTrailing: {
                Text(timerInterval: countdownRange(context.state.nextDueDate), countsDown: true)
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
            } minimal: {
                Image(systemName: symbol(for: context.state.nextCategory))
                    .foregroundStyle(color(for: context.state.nextCategory))
            }
            .keylineTint(color(for: context.state.nextCategory))
        }
    }

    // MARK: - Tela de bloqueio

    private func lockScreen(_ context: ActivityViewContext<SubCheckActivityAttributes>) -> some View {
        let state = context.state

        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Image(systemName: symbol(for: state.nextCategory))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(color(for: state.nextCategory).gradient, in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: 1) {
                    Text(L.t("widget.nextLine"))
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                    Text(state.nextName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(Money.format(state.nextAmount))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                    CountdownText(until: state.nextDueDate)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.warning)
                }
            }

            ProgressView(timerInterval: countdownRange(state.nextDueDate), countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(color(for: state.nextCategory))

            if !state.upcoming.isEmpty {
                Divider().overlay(Color.hairline)
                upcomingList(state)
            }

            Button(intent: MarkPaidIntent(subscriptionID: state.nextID)) {
                Label(L.t("Registrar pagamento"), systemImage: "checkmark.circle")
                    .font(.caption.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.brand)
        }
        .padding(Spacing.lg)
    }

    private func upcomingList(_ state: SubCheckActivityAttributes.ContentState) -> some View {
        VStack(spacing: Spacing.sm) {
            ForEach(state.upcoming.dropFirst()) { charge in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: symbol(for: charge.category))
                        .font(.caption2)
                        .foregroundStyle(color(for: charge.category))
                        .frame(width: 16)

                    Text(charge.name)
                        .font(.caption)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    CountdownText(until: charge.dueDate)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)

                    Text(Money.format(charge.amount))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - Ilha dinâmica

    private func islandBadge(_ state: SubCheckActivityAttributes.ContentState) -> some View {
        Image(systemName: symbol(for: state.nextCategory))
            .font(.subheadline)
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(
                color(for: state.nextCategory).gradient,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }

    private func islandUpcoming(_ state: SubCheckActivityAttributes.ContentState) -> some View {
        VStack(spacing: Spacing.sm) {
            ProgressView(timerInterval: countdownRange(state.nextDueDate), countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(color(for: state.nextCategory))

            ForEach(state.upcoming.dropFirst()) { charge in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: symbol(for: charge.category))
                        .font(.caption2)
                        .foregroundStyle(color(for: charge.category))
                        .frame(width: 16)

                    Text(charge.name)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    CountdownText(until: charge.dueDate)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))

                    Text(Money.format(charge.amount))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - Auxiliares

    /// Ao vivo: mostra hh:mm:ss quando a cobrança é hoje e "amanhã"/"3d"
    /// quando falta mais tempo. Nenhum dos dois precisa de atualização.
    private struct CountdownText: View {
        let until: Date

        var body: some View {
            if until <= Date() {
                Text(L.t("widget.today"))
            } else if daysBetween(until) == 0 {
                Text(timerInterval: countdownRange(until), countsDown: true)
                    .monospacedDigit()
            } else {
                Text(daysLabel(until))
            }
        }
    }

    private func deepLink(_ state: SubCheckActivityAttributes.ContentState) -> URL {
        UUID(uuidString: state.nextID).map(WidgetLink.subscription) ?? WidgetLink.dashboard
    }

    private func color(for category: String) -> Color {
        CategoryType(rawValue: category)?.color ?? .brand
    }

    private func symbol(for category: String) -> String {
        CategoryType(rawValue: category)?.icon ?? "creditcard.fill"
    }
}

// MARK: - Contagem regressiva

/// Faixa usada pelo `timerInterval`. Nunca começa no futuro: um intervalo
/// invertido faria o `Text` quebrar em tempo de execução.
private func countdownRange(_ date: Date) -> ClosedRange<Date> {
    let start = min(Date(), date)
    return start...date
}

private func daysBetween(_ date: Date) -> Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let target = calendar.startOfDay(for: date)
    return max(0, calendar.dateComponents([.day], from: today, to: target).day ?? 0)
}

private func daysLabel(_ date: Date) -> String {
    let days = daysBetween(date)
    if days == 0 { return L.t("widget.today") }
    if days == 1 { return L.t("widget.tomorrow") }
    return L.t("widget.inDays", days)
}
