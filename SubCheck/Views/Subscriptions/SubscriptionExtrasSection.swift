//
//  SubscriptionExtrasSection.swift
//  SubCheck
//
//  Descrição, cobrança por uso, divisão com outras pessoas e vínculo com um
//  pacote (Apple One → iCloud+, Music, Arcade, TV+). Tudo opcional: quem não
//  usa nada disso vê só uma seção curta.
//

import SwiftUI
import SwiftData

struct SubscriptionExtrasSection: View {

    @Bindable var subscription: Subscription
    @Environment(\.modelContext) private var context
    @Query(sort: \Subscription.name) private var all: [Subscription]

    private var service: CurrencyService { .shared }

    // MARK: Pacote

    /// Pacotes possíveis: qualquer outra assinatura que não esteja dentro de
    /// outro pacote (evita ciclos) e que não seja filha desta.
    private var bundleCandidates: [Subscription] {
        all.filter {
            $0.id != subscription.id && !$0.isIncludedInBundle && !$0.isCancelled
        }
    }

    private var children: [Subscription] {
        all.filter { $0.bundleParentID == subscription.id }
    }

    private var parentName: String? {
        guard let id = subscription.bundleParentID else { return nil }
        return all.first { $0.id == id }?.name
    }

    private var parentBinding: Binding<UUID?> {
        Binding(
            get: { subscription.bundleParentID },
            set: {
                subscription.bundleParentID = $0
                context.saveReporting()
            }
        )
    }

    // MARK: Corpo

    var body: some View {
        Group {
            Section {
                Picker("Tipo de cobrança", selection: kindBinding) {
                    Text("Valor fixo").tag(BillingKind.fixed)
                    Text("Por uso").tag(BillingKind.variable)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Como é cobrada")
            } footer: {
                Text(subscription.isVariable
                     ? L.t("O valor muda todo mês. Informe o valor real de cada cobrança; a previsão usa o valor cadastrado como estimativa.")
                     : L.t("Mesmo valor a cada cobrança."))
            }

            Section {
                TextField(L.t("Ex.: e-mail da conta, o que o plano inclui…"),
                          text: $subscription.notes, axis: .vertical)
                    .lineLimit(2...6)
            } header: {
                Text("Descrição")
            } footer: {
                Text("Só você vê. Fica neste aparelho e no seu iCloud, se ligado.")
            }

            Section {
                Stepper(value: $subscription.sharedPeople, in: 1...12) {
                    LabeledContent("Pessoas dividindo") {
                        Text("\(subscription.splitCount)")
                            .monospacedDigit()
                    }
                }

                if subscription.isShared {
                    LabeledContent("Preço cheio") {
                        Text(Money.format(subscription.fullMonthlyCost(in: service)) + "/" + L.t("mês"))
                    }
                    LabeledContent("Sua parte") {
                        Text(Money.format(subscription.monthlyCost(in: service)) + "/" + L.t("mês"))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.brand)
                    }
                }
            } header: {
                Text("Compartilhada")
            } footer: {
                Text(subscription.isShared
                     ? L.t("Os totais do app contam só a sua parte.")
                     : L.t("Divida o valor com 1 ou mais pessoas e o app mostra o preço cheio e a sua parte."))
            }

            Section {
                Picker("Faz parte de", selection: parentBinding) {
                    Text("Nenhum").tag(UUID?.none)
                    ForEach(bundleCandidates) { candidate in
                        Text(candidate.name).tag(UUID?.some(candidate.id))
                    }
                }

                if !children.isEmpty {
                    LabeledContent("Inclui") {
                        Text(children.map(\.name).formatted(.list(type: .and)))
                            .multilineTextAlignment(.trailing)
                    }
                }
            } header: {
                Text("Pacote")
            } footer: {
                Text(subscription.isIncludedInBundle
                     ? L.t("Incluído em %@: não soma duas vezes nos totais.", parentName ?? "")
                     : L.t("Ex.: o Apple One inclui iCloud+, Music, Arcade e TV+. Vincule os serviços ao pacote para não contar em dobro."))
            }
        }
        .onChange(of: subscription.notes) { _, _ in context.saveReporting() }
        .onChange(of: subscription.sharedPeople) { _, _ in context.saveReporting() }
    }

    private var kindBinding: Binding<BillingKind> {
        Binding(
            get: { subscription.billingKind },
            set: {
                subscription.billingKind = $0
                context.saveReporting()
            }
        )
    }
}
