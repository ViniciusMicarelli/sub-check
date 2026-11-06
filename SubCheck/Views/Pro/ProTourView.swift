//
//  ProTourView.swift
//  SubCheck
//
//  Mini tutorial "o que muda no Pro": um cartão por recurso, cada um com o
//  que a versão grátis oferece e o que o Pro acrescenta, lado a lado.
//

import SwiftUI

struct ProTourView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var page = 0

    private struct Item: Identifiable {
        let id: Int
        let icon: String
        let tint: Color
        let title: String
        let free: String
        let pro: String
    }

    private var items: [Item] {
        [
            Item(id: 0, icon: "infinity", tint: .brand,
                 title: L.t("Assinaturas"),
                 free: L.t("Até %lld ativas. Depois disso, é preciso cancelar uma para adicionar outra.", StoreService.freeLimit),
                 pro: L.t("Quantas você quiser, sem limite.")),
            Item(id: 1, icon: "lightbulb.fill", tint: .warning,
                 title: L.t("Insights"),
                 free: L.t("1 dica por vez."),
                 pro: L.t("Todas: sobreposição de serviços, reajustes de preço, concentração de gastos e o que cortar.")),
            Item(id: 2, icon: "chart.xyaxis.line", tint: .info,
                 title: L.t("Análise e previsão"),
                 free: L.t("Resumo do mês e simulação de anos à frente."),
                 pro: L.t("Evolução mês a mês, mapa de calor e previsão de 12 meses.")),
            Item(id: 3, icon: "chart.pie", tint: .warning,
                 title: L.t("Orçamento e simulador"),
                 free: L.t("Não incluso."),
                 pro: L.t("Defina um teto mensal com alerta e simule quanto economiza cancelando serviços.")),
            Item(id: 4, icon: "platter.filled.top.iphone", tint: .danger,
                 title: LiveSurface.name,
                 free: L.t("Widgets na tela inicial."),
                 pro: LiveSurface.text(
                    island: "Contagem regressiva ao vivo da próxima cobrança na Ilha Dinâmica e na tela de bloqueio.",
                    noIsland: "Contagem regressiva ao vivo da próxima cobrança na tela de bloqueio.")),
            Item(id: 5, icon: "icloud", tint: .info,
                 title: L.t("iCloud, PDF, CSV e Face ID"),
                 free: L.t("Dados só neste aparelho, sem exportar."),
                 pro: L.t("Sincroniza entre aparelhos, exporta PDF e CSV e protege o app com Face ID."))
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                TabView(selection: $page) {
                    ForEach(items) { item in
                        card(item).tag(item.id).padding(.horizontal, Spacing.xl)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    Haptics.impact(.light)
                    if page < items.count - 1 {
                        withAnimation(Motion.snappy) { page += 1 }
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(page < items.count - 1 ? L.t("Próximo") : L.t("Entendi"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(Color.brandGradient, in: RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, Spacing.xl)
            }
            .padding(.bottom, Spacing.lg)
            .background(Color.appBackground)
            .navigationTitle(L.t("O que muda no Pro"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L.t("Fechar")) { dismiss() }
                }
            }
        }
    }

    private func card(_ item: Item) -> some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: item.icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 72, height: 72)
                .background(item.tint.gradient, in: RoundedRectangle(cornerRadius: Radius.lg, style: .continuous))
                .padding(.top, Spacing.lg)

            Text(item.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)

            plan(label: L.t("Grátis"), text: item.free, tint: .textSecondary, icon: "circle")
            plan(label: "Pro", text: item.pro, tint: .brand, icon: "checkmark.circle.fill")

            Spacer(minLength: 0)
        }
    }

    private func plan(label: String, text: String, tint: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption.weight(.bold)).foregroundStyle(tint)
                Text(text).font(.subheadline).foregroundStyle(Color.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .cardSurface()
    }
}

#Preview { ProTourView() }
