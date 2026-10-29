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

    /// Ícone, título, descrição e cor de cada recurso desbloqueado.
    private var benefits: [(icon: String, title: String, detail: String, tint: Color)] {
        [
            ("infinity", L.t("Assinaturas ilimitadas"),
             L.t("Cadastre quantos serviços quiser."), .brand),
            ("chart.xyaxis.line", L.t("Análise completa"),
             L.t("Evolução e comparação de meses e anos."), .info),
            ("square.and.arrow.up", L.t("Exportar em CSV"),
             L.t("Leve seus dados para qualquer planilha."), .success),
            ("faceid", L.t("Bloqueio por Face ID"),
             L.t("Suas assinaturas protegidas ao abrir o app."), .warning)
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    header
                    benefitsList
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
            Image(systemName: "sparkles")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(
                    Color.brandGradient,
                    in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
                )
                .softShadow()

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

                if index < benefits.count - 1 {
                    Divider().padding(.leading, 40)
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Compra

    @ViewBuilder
    private var purchaseBlock: some View {
        if store.isPro {
            Label(L.t("Pro ativo neste aparelho"), systemImage: "checkmark.seal.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.success)
                .frame(maxWidth: .infinity)
                .padding(Spacing.lg)
                .background(
                    Color.success.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                )
        } else {
            VStack(spacing: Spacing.md) {
                Button {
                    Task {
                        if await store.purchase() { dismiss() }
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        if store.isPurchasing {
                            ProgressView().tint(.white)
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
                .buttonStyle(.plain)
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

    /// "Desbloquear por R$ 39,90" enquanto o preço da loja não chegou.
    private var purchaseTitle: String {
        guard let price = store.displayPrice else { return L.t("Carregando…") }
        return L.t("Desbloquear por %@", price)
    }
}

#Preview {
    ProView(reason: L.t("Você atingiu o limite de 5 assinaturas ativas."))
}
