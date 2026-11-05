//
//  ImportStatementView.swift
//  SubCheck
//
//  Importa um extrato em CSV, mostra o que parece assinatura e deixa o
//  usuário escolher o que adicionar. O arquivo é lido e descartado no
//  próprio aparelho.
//

import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ImportStatementView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var existing: [Subscription]

    @State private var showImporter = false
    @State private var detected: [DetectedSubscription] = []
    @State private var selected: Set<String> = []
    @State private var transactionCount: Int?
    @State private var errorMessage: String?

    private var existingKeys: Set<String> {
        Set(existing.map { RecurrenceDetector.merchantKey($0.name) })
    }

    private var fresh: [DetectedSubscription] { detected.filter { !existingKeys.contains($0.key) } }
    private var alreadyAdded: [DetectedSubscription] { detected.filter { existingKeys.contains($0.key) } }

    var body: some View {
        NavigationStack {
            List {
                introSection

                if let errorMessage {
                    Section { Text(errorMessage).foregroundStyle(Color.warning) }
                }

                if transactionCount != nil {
                    resultsSection
                }
            }
            .navigationTitle("Importar do extrato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !selected.isEmpty { addBar }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.commaSeparatedText, .plainText, .text, .data]
            ) { result in
                handle(result)
            }
        }
    }

    // MARK: - Seções

    private var introSection: some View {
        Section {
            Button {
                showImporter = true
            } label: {
                Label(
                    transactionCount == nil ? "Escolher arquivo CSV" : "Escolher outro arquivo",
                    systemImage: "doc.text.magnifyingglass"
                )
            }
        } footer: {
            Text("Exporte o extrato do cartão ou da conta em CSV no app do seu banco e escolha o arquivo aqui. O arquivo é lido só neste aparelho e nada é enviado.")
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        if fresh.isEmpty {
            Section {
                Text(detected.isEmpty
                     ? L.t("Não encontramos cobranças que se repetem. Tente um extrato de 3 meses ou mais.")
                     : L.t("Tudo o que encontramos já está nas suas assinaturas."))
                    .foregroundStyle(Color.textSecondary)
            }
        } else {
            Section {
                ForEach(fresh) { item in
                    row(item)
                }
            } header: {
                Text(L.t("Encontramos %lld assinaturas", fresh.count))
            } footer: {
                Text("Confira os valores antes de adicionar. As que parecem canceladas vêm desmarcadas.")
            }
        }

        if !alreadyAdded.isEmpty {
            Section("Já cadastradas") {
                ForEach(alreadyAdded) { item in
                    HStack {
                        Text(item.name)
                        Spacer()
                        Image(systemName: "checkmark").foregroundStyle(Color.success)
                    }
                    .foregroundStyle(Color.textSecondary)
                }
            }
        }
    }

    private func row(_ item: DetectedSubscription) -> some View {
        Button {
            Haptics.impact(.light)
            if selected.contains(item.id) { selected.remove(item.id) } else { selected.insert(item.id) }
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: selected.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected.contains(item.id) ? Color.brand : Color.textTertiary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(L.t("%lld cobranças, a última em %@",
                             item.occurrences,
                             item.lastDate.formatted(date: .abbreviated, time: .omitted)))
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                    if !item.isLikelyActive {
                        Text("Parece cancelada")
                            .font(.caption2)
                            .foregroundStyle(Color.warning)
                    }
                }

                Spacer(minLength: Spacing.sm)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(Money.format(item.amount))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.textPrimary)
                    Text(item.frequency.perPeriodLabel)
                        .font(.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var addBar: some View {
        Button {
            addSelected()
        } label: {
            Text(L.t("Adicionar %lld assinaturas", selected.count))
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        }
        .buttonStyle(.borderedProminent)
        .padding(Spacing.lg)
        .background(.bar)
    }

    // MARK: - Ações

    private func handle(_ result: Result<URL, Error>) {
        errorMessage = nil
        guard case .success(let url) = result else {
            errorMessage = L.t("Não foi possível abrir o arquivo.")
            return
        }

        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            errorMessage = L.t("Não foi possível ler o arquivo.")
            return
        }

        let transactions = StatementParser.parse(text)
        guard !transactions.isEmpty else {
            transactionCount = nil
            errorMessage = L.t("Não reconhecemos esse formato. Precisamos de colunas de data, descrição e valor.")
            return
        }

        transactionCount = transactions.count
        detected = RecurrenceDetector.detect(transactions)
        selected = Set(fresh.filter(\.isLikelyActive).map(\.id))
    }

    private func addSelected() {
        let base = CurrencyService.shared.baseCode
        for item in fresh where selected.contains(item.id) {
            let subscription = Subscription(
                name: item.name,
                cost: item.amount,
                currencyCode: base,
                startDate: item.firstDate,
                frequency: item.frequency,
                category: SubscriptionCategorizer.categorizeRawValue(name: item.name),
                isCancelled: !item.isLikelyActive
            )
            context.insert(subscription)
        }
        context.saveReporting()

        let all = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        // Reconstrói os pagamentos passados e realinha lembretes e ilha.
        PaymentLedger.reconcile(all, in: context)
        for subscription in all where !subscription.isCancelled {
            NotificationService.shared.scheduleNotification(for: subscription)
        }
        LiveActivityService.shared.syncAll(with: all)
        BudgetService.evaluate(all)

        Haptics.success()
        dismiss()
    }
}
