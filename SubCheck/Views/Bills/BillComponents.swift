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

/// "Quanto sobra": salário líquido contra assinaturas e contas.
struct MonthSummaryCard: View {

    let plan: MonthPlan
    let salaryDay: Int
    let onEditSalary: () -> Void

    private var monthTitle: String {
        Date().formatted(Date.FormatStyle().month(.wide).year().locale(L.current)).capitalizedFirst
    }

    private var daysToPayday: Int? {
        guard plan.hasSalary, salaryDay > 0,
              let next = BillSchedule.upcomingDueDates(day: salaryDay, from: Date(), count: 1).first
        else { return nil }
        return BillMath.daysUntil(next)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(monthTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
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

    let entry: BillEntry
    /// Estimativa mostrada enquanto a conta variável não tem valor.
    let estimate: Double

    private var status: BillStatus {
        BillMath.status(isPaid: entry.isPaid, dueDate: entry.dueDate)
    }

    private var days: Int { BillMath.daysUntil(entry.dueDate) }

    var body: some View {
        HStack(spacing: Spacing.md) {
            BillBadge(category: entry.category, size: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.billName)
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
            let date = (entry.paidAt ?? entry.dueDate)
                .formatted(Date.FormatStyle().day().month(.abbreviated).locale(L.current))
            return L.t("Paga em %@", date)
        case .dueToday:
            return L.t("Vence hoje")
        case .overdue:
            return L.t("Venceu há %lld dia(s)", abs(days))
        case .upcoming:
            let day = Calendar.current.component(.day, from: entry.dueDate)
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
        if entry.isPaid {
            Text(Money.format(entry.amount))
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
                .monospacedDigit()
        } else if entry.amount > 0 {
            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.format(entry.amount))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .monospacedDigit()
                if status != .upcoming {
                    Text("Marcar paga")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.brand)
                }
            }
        } else if status == .upcoming {
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
        var parts = [entry.billName, subtitle]
        if entry.amount > 0 {
            parts.append(Money.format(entry.amount))
        } else if status == .upcoming, estimate > 0 {
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
