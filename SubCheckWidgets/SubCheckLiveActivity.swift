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
                        .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(amountText(context.state.nextAmount, kind: context.state.nextKind))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        CountdownText(until: context.state.nextDueDate)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.warning)
                            .lineLimit(1)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.confirmedName.map { "\(L.t("Pago")) · \($0)" } ?? context.state.nextName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.confirmedName == nil {
                        islandBottom(context.state)
                    }
                }
            } compactLeading: {
                ChargeIcon(iconRaw: context.state.nextIcon, kind: context.state.nextKind,
                           category: context.state.nextCategory, size: 22)
            } compactTrailing: {
                // Só o dia: um cronômetro de semanas estoura a largura compacta.
                CompactCountdown(until: context.state.nextDueDate)
            } minimal: {
                ChargeIcon(iconRaw: context.state.nextIcon, kind: context.state.nextKind,
                           category: context.state.nextCategory, size: 22)
            }
            .widgetURL(deepLink(context.state))
            .keylineTint(color(kind: context.state.nextKind, category: context.state.nextCategory))
        }
    }

    // MARK: - Tela de bloqueio

    private func lockScreen(_ context: ActivityViewContext<SubCheckActivityAttributes>) -> some View {
        let state = context.state

        if let name = state.confirmedName {
            return AnyView(paidConfirmation(name: name))
        }

        return AnyView(VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                ChargeIcon(iconRaw: state.nextIcon, kind: state.nextKind,
                           category: state.nextCategory, size: 38)

                VStack(alignment: .leading, spacing: 1) {
                    Text(state.nextKind == "bill" ? L.t("Conta da casa") : L.t("Próxima cobrança"))
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                    Text(state.nextName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(amountText(state.nextAmount, kind: state.nextKind))
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
            .tint(color(kind: state.nextKind, category: state.nextCategory))

            if !state.upcoming.isEmpty {
                Divider().overlay(Color.hairline)
                upcomingList(state)
            }

            if state.nextKind == "bill" {
                // Digitar o valor exige o app: o botão abre a tela da conta.
                Link(destination: deepLink(state)) {
                    Label(L.t("Informar valor"), systemImage: "square.and.pencil")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(Color.brand)
            } else {
                Button(intent: MarkPaidIntent(subscriptionID: state.nextID)) {
                    Label(L.t("Registrar pagamento"), systemImage: "checkmark.circle")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.brand)
            }
        }
        .padding(Spacing.lg))
    }

    /// Resposta imediata ao toque em "Registrar pagamento".
    private func paidConfirmation(name: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(L.t("Pago"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.textPrimary)
                Text(name)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
    }

    private func upcomingList(_ state: SubCheckActivityAttributes.ContentState) -> some View {
        VStack(spacing: Spacing.sm) {
            ForEach(state.upcoming.dropFirst()) { charge in
                HStack(spacing: Spacing.sm) {
                    ChargeIcon(iconRaw: charge.icon, kind: charge.kind,
                               category: charge.category, size: 20)

                    Text(charge.name)
                        .font(.caption)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    CountdownText(until: charge.dueDate)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)

                    Text(amountText(charge.amount, kind: charge.kind))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: - Ilha dinâmica

    private func islandBadge(_ state: SubCheckActivityAttributes.ContentState) -> some View {
        ChargeIcon(iconRaw: state.nextIcon, kind: state.nextKind,
                   category: state.nextCategory, size: 30)
    }

    /// Área inferior enxuta: a ilha expandida tem pouca altura, então só
    /// cabem o botão de pagamento e a próxima cobrança.
    private func islandBottom(_ state: SubCheckActivityAttributes.ContentState) -> some View {
        VStack(spacing: Spacing.sm) {
            if let following = state.upcoming.dropFirst().first {
                HStack(spacing: Spacing.sm) {
                    Text(following.name)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text(amountText(following.amount, kind: following.kind))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
            }

            if state.nextKind == "bill" {
                Link(destination: deepLink(state)) {
                    Label(L.t("Informar valor"), systemImage: "square.and.pencil")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(color(kind: state.nextKind, category: state.nextCategory), in: Capsule())
                        .foregroundStyle(.white)
                }
            } else {
                Button(intent: MarkPaidIntent(subscriptionID: state.nextID)) {
                    Label(L.t("Registrar pagamento"), systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .tint(color(kind: state.nextKind, category: state.nextCategory))
            }
        }
    }

    // MARK: - Auxiliares

    /// Ícone da cobrança: o logo da marca (ou o escolhido pelo usuário) para
    /// assinaturas e o símbolo da categoria para contas da casa.
    private struct ChargeIcon: View {
        let iconRaw: String?
        let kind: String?
        let category: String
        let size: CGFloat

        var body: some View {
            if kind != "bill", let iconRaw, let icon = SubscriptionIcon(rawValue: iconRaw) {
                SubscriptionIconView(icon: icon, fallbackColor: tint, size: size)
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: size * 0.45, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(tint.gradient, in: Circle())
            }
        }

        private var tint: Color {
            kind == "bill"
                ? (BillCategory(rawValue: category)?.color ?? .brand)
                : (CategoryType(rawValue: category)?.color ?? .brand)
        }

        private var symbolName: String {
            kind == "bill"
                ? (BillCategory(rawValue: category)?.icon ?? "doc.text.fill")
                : (CategoryType(rawValue: category)?.icon ?? "creditcard.fill")
        }
    }

    /// Ao vivo: mostra hh:mm:ss quando a cobrança é hoje e "amanhã"/"3d"
    /// quando falta mais tempo. Nenhum dos dois precisa de atualização.
    private struct CountdownText: View {
        let until: Date

        var body: some View {
            if until <= Date() {
                Text(L.t("widget.today"))
            } else if daysBetween(until) == 0 {
                // `Text(timerInterval:)` ocupa toda a largura disponível; sem
                // limite ele empurra o resto da linha e o texto sai torto.
                Text(timerInterval: countdownRange(until), countsDown: true)
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 64, alignment: .trailing)
            } else {
                Text(daysLabel(until))
            }
        }
    }

    /// Texto curto da ilha compacta: horas e minutos se for hoje, senão dias.
    private struct CompactCountdown: View {
        let until: Date

        var body: some View {
            let days = daysBetween(until)
            Group {
                if until <= Date() || days == 0 {
                    Text(L.t("widget.today"))
                } else {
                    Text("\(days)d")
                }
            }
            .font(.caption2.weight(.bold))
            .monospacedDigit()
            .lineLimit(1)
            .frame(minWidth: 24, alignment: .trailing)
        }
    }

    private func deepLink(_ state: SubCheckActivityAttributes.ContentState) -> URL {
        guard let id = UUID(uuidString: state.nextID) else { return WidgetLink.dashboard }
        return state.nextKind == "bill" ? WidgetLink.bill(id) : WidgetLink.subscription(id)
    }

    /// Conta variável ainda sem valor mostra "—" em vez de R$ 0,00.
    private func amountText(_ amount: Double, kind: String?) -> String {
        (kind == "bill" && amount <= 0) ? "—" : Money.format(amount)
    }

    private func color(kind: String?, category: String) -> Color {
        if kind == "bill" { return BillCategory(rawValue: category)?.color ?? .brand }
        return color(for: category)
    }

    private func symbol(kind: String?, category: String) -> String {
        if kind == "bill" { return BillCategory(rawValue: category)?.icon ?? "doc.text.fill" }
        return symbol(for: category)
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
