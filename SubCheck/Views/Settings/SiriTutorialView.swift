//
//  SiriTutorialView.swift
//  SubCheck
//
//  Ensina a usar a Siri e o app Atalhos com o SubCheck: as frases que já
//  funcionam sem configurar, como montar um atalho próprio, automações e o
//  que fazer quando a Siri não responde.
//

import AppIntents
import SwiftUI

struct SiriTutorialView: View {

    @Environment(\.openURL) private var openURL

    private struct Phrase: Identifiable {
        let id: String
        let symbol: String
        let title: String
        let phrase: String
    }

    /// As frases abaixo são as mesmas de `AppShortcuts.strings`.
    private var phrases: [Phrase] {
        [
            Phrase(id: "pay", symbol: "checkmark.circle", title: L.t("siri.pay.title"), phrase: L.t("siri.pay.phrase")),
            Phrase(id: "add", symbol: "plus.circle", title: L.t("siri.add.title"), phrase: L.t("siri.add.phrase")),
            Phrase(id: "price", symbol: "arrow.up.arrow.down.circle", title: L.t("siri.price.title"), phrase: L.t("siri.price.phrase")),
            Phrase(id: "cancel", symbol: "xmark.circle", title: L.t("siri.cancel.title"), phrase: L.t("siri.cancel.phrase")),
            Phrase(id: "next", symbol: "calendar.badge.clock", title: L.t("siri.next.title"), phrase: L.t("siri.next.phrase")),
            Phrase(id: "total", symbol: "creditcard", title: L.t("siri.total.title"), phrase: L.t("siri.total.phrase")),
            Phrase(id: "soon", symbol: "bell.badge", title: L.t("siri.soon.title"), phrase: L.t("siri.soon.phrase"))
        ]
    }

    var body: some View {
        List {
            introSection
            phrasesSection
            stepsSection
            automationSection
            troubleshootingSection
        }
        .navigationTitle("Siri e Atalhos")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Seções

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Fale com o SubCheck", systemImage: "waveform.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color.brand)
                Text("Registre pagamentos, adicione assinaturas e consulte seus gastos pela voz, sem abrir o app. Não precisa configurar nada: as frases abaixo já funcionam.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.vertical, Spacing.xs)

            ShortcutsLink()
        } footer: {
            Text("O botão acima abre o app Atalhos já nos atalhos do SubCheck.")
        }
    }

    private var phrasesSection: some View {
        Section {
            ForEach(phrases) { item in
                HStack(alignment: .top, spacing: Spacing.md) {
                    Image(systemName: item.symbol)
                        .font(.title3)
                        .foregroundStyle(Color.brand)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline.weight(.semibold))
                        Text("“\(item.phrase)”")
                            .font(.footnote)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Diga “Ei Siri” e depois")
        } footer: {
            Text("Troque o nome da assinatura pela sua (por exemplo, Netflix). Se faltar alguma informação, a Siri pergunta.")
        }
    }

    private var stepsSection: some View {
        Section {
            step(1, "Abra o app Atalhos", "Ele já vem no iPhone. Se não achar, procure “Atalhos” na biblioteca de apps.")
            step(2, "Toque em + (canto superior)", "Isso cria um atalho novo.")
            step(3, "Toque em Adicionar Ação e procure SubCheck", "Aparecem Registrar pagamento, Adicionar assinatura, Atualizar valor, Próxima cobrança e outras.")
            step(4, "Escolha a ação e preencha", "Toque na assinatura ou no valor para fixar, ou deixe em branco para o atalho perguntar.")
            step(5, "Dê um nome curto", "O nome vira a frase da Siri: um atalho chamado “Paguei a Netflix” responde a “Ei Siri, paguei a Netflix”.")
            step(6, "Toque em OK", "Pronto. Para ter no início do iPhone, abra o atalho, toque em ⓘ e em Adicionar à Tela de Início.")
        } header: {
            Text("Criar seu próprio atalho")
        }
    }

    private var automationSection: some View {
        Section {
            idea("clock", "Todo dia 1º às 9h", "Automação de horário com a ação Total mensal: a Siri fala quanto você vai gastar no mês.")
            idea("location", "Ao chegar em casa", "Automação de local com a ação Próxima cobrança: você ouve o que vence em seguida.")
            idea("bell", "Toda segunda-feira", "Use Cobranças dos próximos dias com 7 dias e veja a semana que vem.")
        } header: {
            Text("Ideias de automação")
        } footer: {
            Text("No app Atalhos, abra a aba Automação, toque em + e escolha o gatilho. Em “Executar imediatamente”, o atalho roda sem pedir confirmação.")
        }
    }

    private var troubleshootingSection: some View {
        Section {
            idea("gearshape", "Siri ligada para o SubCheck", "Em Ajustes do iPhone > Siri > Aplicativos > SubCheck, ligue “Usar com Pergunte à Siri”.")
            idea("globe", "Idioma da Siri", "A Siri entende as frases no idioma configurado nela. Em português, use as frases em português.")
            idea("lock.shield", "iPhone bloqueado", "Para registrar ou alterar dados, a Siri pode pedir Face ID ou a senha.")
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            } label: {
                Label("Abrir Ajustes do iPhone", systemImage: "arrow.up.forward.app")
            }
        } header: {
            Text("A Siri não respondeu?")
        }
    }

    // MARK: - Componentes

    private func step(_ number: Int, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text("\(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.brand, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func idea(_ symbol: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .foregroundStyle(Color.brand)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.footnote).foregroundStyle(Color.textSecondary)
            }
        }
        .padding(.vertical, 2)
    }
}
