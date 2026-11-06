//
//  BillComponents.swift
//  SubCheck
//
//  Peças das Contas: selo da categoria, o cartão "sobra do mês" e a linha de
//  cada conta.
//

import SwiftUI

// MARK: - Selo

struct BillBadge: View {
    let category: BillCategory
    var size: CGFloat = 40

    var body: some View {
        Image(systemName: category.icon)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(category.color.gradient, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Cartão do mês

/// Setas de mês do cartão do resumo.
struct MonthNavigation {
    var canGoBack: Bool
    var canGoForward: Bool
    var isCurrent: Bool
    var back: () -> Void
    var forward: () -> Void
    var today: () -> Void
}

/// "Quanto sobra": salário líquido contra assinaturas e contas.
struct MonthSummaryCard: View {

    let plan: MonthPlan
    let salaryDay: Int
    var month: Date = Date()
    var navigation: MonthNavigation?
    let onEditSalary: () -> Void

    private var monthTitle: String {
        month.formatted(Date.FormatStyle().month(.wide).year().locale(L.current)).capitalizedFirst
    }

    /// Só faz sentido contar até o salário no mês atual.
    private var isCurrentMonth: Bool {
        BillSchedule.monthStart(of: month) == BillSchedule.monthStart(of: Date())
    }

    private var daysToPayday: Int? {
        guard isCurrentMonth, plan.hasSalary, salaryDay > 0,
              let next = BillSchedule.upcomingDueDates(day: salaryDay, from: Date(), count: 1).first
        else { return nil }
        return BillMath.daysUntil(next)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.xs) {
                if let navigation {
                    arrow("chevron.left", label: "Mês anterior", enabled: navigation.canGoBack, action: navigation.back)
                }
                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let navigation {
                    arrow("chevron.right", label: "Próximo mês", enabled: navigation.canGoForward, action: navigation.forward)
                    if !navigation.isCurrent {
                        Button(action: navigation.today) {
                            Text("Hoje")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.brand)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.white, in: Capsule())
                        }
                        .padding(.leading, Spacing.xs)
                    }
                }
                Spacer(minLength: 0)
                if plan.hasSalary {
                    Button(action: onEditSalary) {
                        Label("Editar salário", systemImage: "pencil")
                            .labelStyle(.iconOnly)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.white.opacity(0.18), in: Circle())
                    }
                    .accessibilityLabel(Text("Editar salário"))
                }
            }

            if plan.hasSalary {
                filled
            } else {
                empty
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.xl)
        .background(Color.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
        .softShadow()
    }

    private func arrow(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Image(systemName: symbol)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white.opacity(enabled ? 1 : 0.3))
                .frame(width: 30, height: 30)
                .background(.white.opacity(enabled ? 0.18 : 0.08), in: Circle())
        }
        .disabled(!enabled)
        .accessibilityLabel(Text(LocalizedStringKey(label)))
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Quanto sobra no seu mês?")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text("Informe o salário líquido, já com os descontos. O SubCheck soma assinaturas e contas e mostra o que sobra.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
            Button(action: onEditSalary) {
                Label("Informar salário", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brand)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm + 2)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var filled: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.isOver ? L.t("Faltam") : L.t("Sobra do mês"))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(Money.format(abs(plan.remaining)))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(plan.isOver ? Color(red: 1, green: 0.78, blue: 0.78) : .white)
                    .contentTransition(.numericText())
                Text(L.t("de %@ de salário líquido", Money.format(plan.salary)))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }

            GeometryReader { proxy in
                HStack(spacing: 2) {
                    segment(plan.subscriptions, color: .white, in: proxy.size.width)
                    segment(plan.billsPaid, color: Color.brandMint, in: proxy.size.width)
                    segment(plan.billsPending, color: .white.opacity(0.42), in: proxy.size.width)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.2), in: Capsule())
                .clipShape(Capsule())
            }
            .frame(height: 10)
            .accessibilityHidden(true)

            VStack(spacing: Spacing.xs + 2) {
                legend(L.t("Assinaturas"), plan.subscriptions, .white)
                legend(L.t("Contas pagas"), plan.billsPaid, Color.brandMint)
                legend(L.t("Contas a pagar"), plan.billsPending, .white.opacity(0.5))
            }

            if let days = daysToPayday {
                Label(
                    days == 0 ? L.t("Salário cai hoje") : L.t("Salário cai em %lld dia(s)", days),
                    systemImage: "calendar.badge.clock"
                )
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs + 1)
                .background(.white.opacity(0.18), in: Capsule())
            }
        }
        .animation(.snappy, value: plan)
    }

    @ViewBuilder
    private func segment(_ value: Double, color: Color, in width: CGFloat) -> some View {
        let w = max(0, (width - 4) * plan.share(value))
        if w > 0.5 {
            Capsule().fill(color).frame(width: w)
        }
    }

    private func legend(_ title: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: Spacing.sm) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.9))
            Spacer(minLength: 0)
            Text(Money.format(value))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Linha

struct BillRow: View {

    let name: String
    let category: BillCategory
    let dueDate: Date
    let paidAt: Date?
    let isPaid: Bool
    /// Valor informado (0 = ainda não informou).
    let amount: Double
    /// Estimativa mostrada enquanto a conta variável não tem valor.
    let estimate: Double
    /// Previsão de mês futuro: ainda não existe linha para editar.
    var isProjected = false

    init(entry: BillEntry, estimate: Double) {
        name = entry.billName
        category = entry.category
        dueDate = entry.dueDate
        paidAt = entry.paidAt
        isPaid = entry.isPaid
        amount = entry.amount
        self.estimate = estimate
    }

    init(occurrence item: BillOccurrence) {
        name = item.name
        category = item.category
        dueDate = item.dueDate
        paidAt = item.paidAt
        isPaid = item.status == .paid
        amount = item.isEstimate ? 0 : item.amount
        estimate = item.isEstimate ? item.amount : 0
        isProjected = item.isProjected
    }

    private var status: BillStatus {
        BillMath.status(isPaid: isPaid, dueDate: dueDate)
    }

    private var days: Int { BillMath.daysUntil(dueDate) }

    var body: some View {
        HStack(spacing: Spacing.md) {
            BillBadge(category: category, size: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(subtitleColor)
            }

            Spacer(minLength: Spacing.sm)

            trailing
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var subtitle: String {
        switch status {
        case .paid:
            let date = (paidAt ?? dueDate)
                .formatted(Date.FormatStyle().day().month(.abbreviated).locale(L.current))
            return L.t("Paga em %@", date)
        case .dueToday:
            return L.t("Vence hoje")
        case .overdue:
            return L.t("Venceu há %lld dia(s)", abs(days))
        case .upcoming:
            let day = Calendar.current.component(.day, from: dueDate)
            // Em outro mês a contagem de dias não ajuda: só o dia.
            if abs(days) > 40 || isProjected { return L.t("Vence dia %lld", day) }
            return L.t("Vence dia %lld · em %lld dia(s)", day, days)
        }
    }

    private var subtitleColor: Color {
        switch status {
        case .overdue: Color.danger
        case .dueToday: Color.warning
        default: Color.textSecondary
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if isPaid {
            Text(Money.format(amount))
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
        } else if amount > 0 {
            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.format(amount))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                if status != .upcoming {
                    Text("Marcar paga")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.brand)
                }
            }
        } else if status == .upcoming || isProjected {
            Text(estimate > 0 ? "~\(Money.format(estimate))" : "—")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .monospacedDigit()
        } else {
            Text("Informar valor")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 6)
                .background(Color.brandGradient, in: Capsule())
        }
    }

    private var accessibilityText: String {
        var parts = [name, subtitle]
        if amount > 0 {
            parts.append(Money.format(amount))
        } else if (status == .upcoming || isProjected), estimate > 0 {
            parts.append(L.t("estimativa %@", Money.format(estimate)))
        } else if status != .paid {
            parts.append(L.t("Informar valor"))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Card do painel

/// Versão compacta do plano do mês, para o painel. Leva à aba Contas.
struct MonthPlanCard: View {

    let plan: MonthPlan
    let toInform: Int
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Label("Seu mês", systemImage: "wallet.pass.fill")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    Spacer(minLength: 0)
                    if toInform > 0 {
                        Text(L.t("%lld para informar", toInform))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(Color.warning, in: Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.textTertiary)
                }

                if plan.hasSalary {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(plan.isOver ? L.t("Faltam") : L.t("Sobra do mês"))
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            Text(Money.format(abs(plan.remaining)))
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(plan.isOver ? Color.danger : Color.success)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        Spacer(minLength: Spacing.md)
                        Text(L.t("%@ comprometido", Money.percentPlain(plan.committedFraction)))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.textSecondary)
                    }

                    ProgressView(value: plan.committedFraction)
                        .tint(plan.isOver ? Color.danger : Color.brand)
                        .accessibilityHidden(true)
                } else {
                    Text("Informe seu salário líquido para ver quanto sobra depois das contas.")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardSurface()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Abre a aba Contas"))
    }
}
