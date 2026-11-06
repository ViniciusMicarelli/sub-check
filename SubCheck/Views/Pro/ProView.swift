//
//  ProView.swift
//  SubCheck
//
//  Paywall da versão Pro. Compra única (não consumível), sem assinatura.
//

import SwiftUI

struct ProView: View {

    /// Texto de contexto quando o paywall abre a partir de algo bloqueado.
    var reason: String?

    @Environment(\.dismiss) private var dismiss

    @State private var store = StoreService.shared
    @State private var showTour = false

    /// Ícone, título, descrição e cor de cada recurso desbloqueado.
    private var benefits: [(icon: String, title: String, detail: String, tint: Color)] {
        [
            ("infinity", L.t("Assinaturas ilimitadas"),
             L.t("Cadastre quantos serviços quiser."), .brand),
            ("lightbulb.fill", L.t("Insights inteligentes"),
             L.t("Dicas automáticas para cortar gastos e economizar."), .warning),
            ("chart.xyaxis.line", L.t("Análise completa"),
             L.t("Evolução, mapa de calor e previsão de 12 meses."), .info),
            ("platter.filled.top.iphone", L.t("Ilha Dinâmica ao vivo"),
             L.t("Contagem regressiva e próximas cobranças na tela."), .danger),
            ("chart.pie", L.t("Orçamento com alertas"),
             L.t("Defina um teto mensal e seja avisado ao ultrapassar."), .warning),
            ("scissors", L.t("Simulador de cancelamento"),
             L.t("Veja quanto você economiza cortando serviços."), .brand),
            ("doc.richtext", L.t("Relatório em PDF"),
             L.t("Um resumo pronto para compartilhar."), .success),
            ("square.and.arrow.up", L.t("Exportar em CSV"),
             L.t("Leve seus dados para qualquer planilha."), .success),
            ("icloud", L.t("Sincronização com iCloud"),
             L.t("Mantenha seus dados iguais em todos os aparelhos."), .info),
            ("faceid", L.t("Bloqueio por Face ID"),
             L.t("Suas assinaturas protegidas ao abrir o app."), .warning)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    header
                    tourButton
                    benefitsList
                    comparison
                    purchaseBlock
                }
                .padding(Spacing.xl)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Cabeçalho

    private var header: some View {
        VStack(spacing: Spacing.lg) {
            BrandMark(size: 84)

            VStack(spacing: Spacing.xs) {
                Text("SubCheck Pro")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.textPrimary)

                Text(reason ?? L.t("Um pagamento único libera tudo para sempre."))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var tourButton: some View {
        Button {
            Haptics.impact(.light)
            showTour = true
        } label: {
            Label(L.t("Ver o que muda no Pro"), systemImage: "play.circle.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .foregroundStyle(Color.brand)
                .background(Color.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(PressableStyle())
        .sheet(isPresented: $showTour) { ProTourView() }
    }

    // MARK: - Recursos

    private var benefitsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                HStack(alignment: .top, spacing: Spacing.md) {
                    Image(systemName: benefit.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            benefit.tint.gradient,
                            in: RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(benefit.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.textPrimary)
                        Text(benefit.detail)
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.success)
                }
                .padding(.vertical, Spacing.md)
                .staggeredAppear(index)

                if index < benefits.count - 1 {
                    Divider().padding(.leading, 40)
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Grátis x Pro

    private var comparisonRows: [(title: String, free: String, pro: String)] {
        [
            (L.t("Assinaturas ativas"), "\(StoreService.freeLimit)", "∞"),
            (L.t("Resumo e widgets"), L.t("Sim"), L.t("Sim")),
            (L.t("Insights"), "1", L.t("Todos")),
            (L.t("Análise e previsão"), L.t("Não"), L.t("Sim")),
            (L.t("Orçamento e simulador"), L.t("Não"), L.t("Sim")),
            (L.t("Ilha Dinâmica"), L.t("Não"), L.t("Sim")),
            (L.t("PDF, CSV e Face ID"), L.t("Não"), L.t("Sim")),
            (L.t("iCloud"), L.t("Não"), L.t("Sim"))
        ]
    }

    private var comparison: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text(L.t("Grátis")).frame(width: 64)
                Text("Pro").frame(width: 64).foregroundStyle(Color.brand)
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.textSecondary)
            .padding(.bottom, Spacing.sm)

            ForEach(Array(comparisonRows.enumerated()), id: \.offset) { index, row in
                HStack {
                    Text(row.title)
                        .font(.subheadline)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text(row.free)
                        .frame(width: 64)
                        .foregroundStyle(Color.textSecondary)
                    Text(row.pro)
                        .frame(width: 64)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.success)
                }
                .font(.subheadline)
                .padding(.vertical, Spacing.sm)

                if index < comparisonRows.count - 1 { Divider() }
            }
        }
        .cardSurface()
    }

    // MARK: - Compra

    @ViewBuilder
    private var purchaseBlock: some View {
        if store.isPro {
            statusBanner(
                text: L.t("Pro ativo neste aparelho"),
                icon: "checkmark.seal.fill",
                tint: .success
            )
        } else {
            VStack(spacing: Spacing.md) {
                if store.isTrialActive {
                    statusBanner(
                        text: L.t("Teste gratuito: %lld dia(s) restante(s).", store.trialDaysRemaining),
                        icon: "hourglass",
                        tint: .warning
                    )
                }

                if store.canStartTrial {
                    Button {
                        store.startTrial()
                        Haptics.success()
                        dismiss()
                    } label: {
                        VStack(spacing: 2) {
                            Text("Testar 7 dias grátis")
                                .font(.headline)
                            Text("Sem cartão e sem cobrança")
                                .font(.caption)
                                .opacity(0.8)
                        }
                        .foregroundStyle(Color.brand)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            Color.brand.opacity(0.12),
                            in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        )
                    }
                    .buttonStyle(PressableStyle())
                }

                Button {
                    Task {
                        if await store.purchase() { dismiss() }
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if store.isPurchasing {
                            BrandSpinner(
                                size: 18,
                                lineWidth: 2,
                                colors: [.white.opacity(0.25), .white]
                            )
                        }
                        Text(purchaseTitle)
                            .font(.headline)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(
                        Color.brandGradient,
                        in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    )
                }
                .buttonStyle(PressableStyle())
                .disabled(store.isPurchasing || store.product == nil)
                .opacity(store.product == nil ? 0.6 : 1)

                Button {
                    Task { await store.restore() }
                } label: {
                    Text("Restaurar compra")
                        .font(.subheadline)
                        .foregroundStyle(Color.brand)
                }

                if let message = store.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(Color.danger)
                        .multilineTextAlignment(.center)
                }

                Text("Pagamento único. Sem assinatura e sem renovação.")
                    .font(.caption2)
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    /// Faixa de estado (Pro ativo ou teste em curso).
    private func statusBanner(text: String, icon: String, tint: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(Spacing.lg)
            .background(
                tint.opacity(0.12),
                in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            )
    }

    /// "Desbloquear por R$ 39,90" enquanto o preço da loja não chegou.
    private var purchaseTitle: String {
        guard let price = store.displayPrice else { return L.t("Carregando…") }
        return L.t("Desbloquear por %@", price)
    }
}

#Preview {
    ProView(reason: L.t("Você atingiu o limite de 5 assinaturas ativas."))
}
