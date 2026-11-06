//
//  SettingsView.swift
//  SubCheck
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var context
    @Query private var subscriptions: [Subscription]

    /// Mesma chave lida por `Profile`, o onboarding e a saudação do resumo.
    @AppStorage(Profile.nameKey) private var userName = ""
    @AppStorage("appearance") private var appearance: AppearanceOption = .system
    @AppStorage(L.languageKey) private var language: AppLanguage = .system
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    /// Mesma chave lida por `LiveActivityService`.
    @AppStorage(LiveActivityService.enabledKey) private var liveActivityEnabled = true
    /// Sincronização com iCloud; vale a partir do próximo lançamento.
    @AppStorage(SharedModelContainer.iCloudSyncKey) private var iCloudSync = false
    @State private var iCloudNeedsRestart = false
    /// Resultado do último teste da Ilha Dinâmica.
    @State private var liveActivityTestMessage: String?
    /// Teto mensal; zero desliga o orçamento (ver `Budget`).
    @AppStorage(Budget.amountKey) private var monthlyBudget = 0.0

    @State private var showEraseConfirmation = false
    @State private var showPaywall = false
    @State private var notificationStatus: String?
    /// Arquivo do CSV pronto para compartilhar; `nil` sem Pro. Refeito
    /// quando o conjunto de assinaturas muda.
    @State private var exportURL: URL?
    /// Relatório em PDF, pelo mesmo motivo.
    @State private var reportURL: URL?

    private var store = StoreService.shared

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                proSection
                budgetSection
                toolsSection
                notificationsSection
                liveActivitySection
                iCloudSection
                appearanceSection
                languageSection
                currencySection
                securitySection
                dataSection
                aboutSection
            }
            .navigationTitle("Ajustes")
            .sheet(isPresented: $showPaywall) {
                ProView()
            }
            .task(id: exportSignature) { refreshExport() }
            .onChange(of: store.hasProAccess) { _, _ in refreshExport() }
            .onChange(of: language) { _, newValue in
                L.store(newValue)
                // Lembretes já agendados guardam o texto no idioma antigo.
                rescheduleAll()
            }
            .onChange(of: monthlyBudget) { _, _ in
                BudgetService.evaluate(subscriptions)
                refreshExport()
            }
            .confirmationDialog(
                "Apagar todos os dados?",
                isPresented: $showEraseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Apagar tudo", role: .destructive) {
                    Haptics.warning()
                    SampleDataSeeder.eraseAll(in: context)
                    RemoteIconStore.clear()
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Todas as assinaturas e o histórico serão removidos. Esta ação não pode ser desfeita.")
            }
        }
    }

    // MARK: - Sobre você

    /// Nome informado no onboarding; fica só no aparelho e personaliza o resumo.
    private var profileSection: some View {
        Section {
            LabeledContent("Nome") {
                TextField(L.t("Como podemos te chamar?"), text: $userName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("Sobre você")
        } footer: {
            Text("Usado só para personalizar o resumo. Fica no aparelho.")
        }
    }

    // MARK: - Pro

    private var proSection: some View {
        Section {
            Button {
                Haptics.impact(.light)
                showPaywall = true
            } label: {
                HStack {
                    Label("SubCheck Pro", systemImage: "sparkles")
                    Spacer()
                    Text(store.isPro ? L.t("Ativo") : L.t("Ver opções"))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        } footer: {
            Text(proFooter)
        }
    }

    /// Explica o estado atual: compra feita, teste em curso ou bloqueado.
    private var proFooter: String {
        if store.isPro { return L.t("Obrigado por apoiar o SubCheck.") }
        if store.isTrialActive {
            return L.t("Teste gratuito: %lld dia(s) restante(s).", store.trialDaysRemaining)
        }
        return L.t("Um pagamento único libera todos os recursos para sempre.")
    }

    // MARK: - Segurança

    private var securitySection: some View {
        Section {
            Toggle(isOn: appLockBinding) {
                Label("Bloqueio por Face ID", systemImage: "faceid")
            }
        } header: {
            Text("Segurança")
        } footer: {
            Text(
                store.hasProAccess
                    ? L.t("Ao abrir o app, o Face ID ou a senha do aparelho é solicitado.")
                    : L.t("O bloqueio por Face ID faz parte do SubCheck Pro.")
            )
        }
    }

    /// Liga o bloqueio; sem Pro, leva para o paywall em vez de ativar.
    private var appLockBinding: Binding<Bool> {
        Binding(
            get: { appLockEnabled },
            set: { newValue in
                guard newValue else {
                    appLockEnabled = false
                    return
                }
                if store.hasProAccess {
                    appLockEnabled = true
                } else {
                    Haptics.impact(.light)
                    showPaywall = true
                }
            }
        )
    }

    // MARK: - Orçamento

    /// Gasto mensal atual das assinaturas ativas.
    private var spentMonthly: Double {
        subscriptions.filter { !$0.isCancelled }.monthlyTotal(in: .shared)
    }

    private var budgetSection: some View {
        Section {
            if store.hasProAccess {
                LabeledContent("Orçamento mensal") {
                    TextField("0,00", value: $monthlyBudget, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                if monthlyBudget > 0 {
                    LabeledContent("Gasto atual", value: Money.format(spentMonthly))

                    Button(role: .destructive) {
                        monthlyBudget = 0
                    } label: {
                        Label("Remover orçamento", systemImage: "trash")
                    }
                }
            } else {
                Button {
                    Haptics.impact(.light)
                    showPaywall = true
                } label: {
                    HStack {
                        Label("Orçamento mensal", systemImage: "target")
                        Spacer()
                        Label(L.t("Pro"), systemImage: "lock.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(Color.warning)
                    }
                }
            }
        } header: {
            Text("Orçamento")
        } footer: {
            Text(
                store.hasProAccess
                    ? L.t("Defina um teto mensal. Avisamos quando o gasto passar dele.")
                    : L.t("O orçamento com alertas faz parte do SubCheck Pro.")
            )
        }
    }

    // MARK: - Ferramentas

    private var toolsSection: some View {
        Section {
            NavigationLink {
                CancellationSimulatorView()
            } label: {
                Label("Simulador de cancelamento", systemImage: "scissors")
            }

            reportRow

            NavigationLink {
                SiriTutorialView()
            } label: {
                Label("Siri e Atalhos", systemImage: "waveform.circle")
            }
        } header: {
            Text("Ferramentas")
        } footer: {
            if !store.hasProAccess {
                Text("As ferramentas fazem parte do SubCheck Pro.")
            }
        }
    }

    /// Compartilha o PDF quando o Pro está ativo; sem ele, abre o paywall.
    @ViewBuilder
    private var reportRow: some View {
        if let reportURL {
            ShareLink(item: reportURL) {
                Label("Relatório em PDF", systemImage: "doc.richtext")
            }
        } else {
            Button {
                Haptics.impact(.light)
                showPaywall = true
            } label: {
                HStack {
                    Label("Relatório em PDF", systemImage: "doc.richtext")
                    Spacer()
                    Label(L.t("Pro"), systemImage: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.warning)
                }
            }
        }
    }

    // MARK: - iCloud

    /// `true` quando há uma conta do iCloud entrada neste aparelho.
    private var hasICloudAccount: Bool { FileManager.default.ubiquityIdentityToken != nil }

    private var iCloudSection: some View {
        Section {
            Toggle(isOn: iCloudBinding) {
                Label("Sincronizar com iCloud", systemImage: "icloud")
            }

            if iCloudSync && !hasICloudAccount {
                Label("Entre no iCloud em Ajustes do iOS para sincronizar.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.warning)
            }

            if iCloudSync && !store.hasProAccess {
                Label("Sincronização pausada: o iCloud faz parte do Pro. Seus dados continuam no aparelho.", systemImage: "pause.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.warning)
            }

            if iCloudNeedsRestart {
                Label("Feche e abra o SubCheck de novo para aplicar.", systemImage: "arrow.clockwise")
                    .font(.footnote)
                    .foregroundStyle(Color.brand)
                    .transition(.opacity)
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text(
                store.hasProAccess
                    ? L.t("Assinaturas e histórico ficam iguais em todos os seus aparelhos.")
                    : L.t("A sincronização com iCloud faz parte do SubCheck Pro.")
            )
        }
    }

    /// Só liga com Pro; a troca pede reinício porque o banco é aberto uma vez.
    private var iCloudBinding: Binding<Bool> {
        Binding(
            get: { iCloudSync },
            set: { newValue in
                guard !newValue || store.hasProAccess else {
                    Haptics.impact(.light)
                    showPaywall = true
                    return
                }
                iCloudSync = newValue
                withAnimation(Motion.snappy) { iCloudNeedsRestart = true }
            }
        )
    }

    // MARK: - Ilha Dinâmica

    private var liveActivitySection: some View {
        Section {
            Toggle(isOn: liveActivityBinding) {
                Label("Ilha Dinâmica", systemImage: "platter.filled.top.iphone")
            }

            Button {
                testLiveActivity()
            } label: {
                Label("Testar Ilha Dinâmica", systemImage: "play.circle")
            }

            if let liveActivityTestMessage {
                Text(liveActivityTestMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.textSecondary)
                    .transition(.opacity)
            }
        } header: {
            Text("Ilha Dinâmica")
        } footer: {
            Text(
                store.hasProAccess
                    ? L.t("live.footer")
                    : L.t("A Ilha Dinâmica faz parte do SubCheck Pro.")
            )
        }
    }

    /// Inicia a atividade na hora e explica o resultado. A ilha só aparece
    /// com o app em segundo plano, então a mensagem diz o que fazer em seguida.
    private func testLiveActivity() {
        guard store.hasProAccess else {
            Haptics.impact(.light)
            showPaywall = true
            return
        }
        let result = LiveActivityService.shared.start(with: subscriptions)
        let message: String
        switch result {
        case .started, .updated:
            Haptics.success()
            message = L.t("Ativa. Volte para a tela de início agora para ver a ilha (iPhone com Ilha Dinâmica) ou bloqueie a tela.")
        case .disabledBySystem:
            Haptics.warning()
            message = L.t("Atividades ao Vivo estão desligadas. Ative em Ajustes do iOS > SubCheck.")
        case .noSubscriptions:
            Haptics.warning()
            message = L.t("Adicione uma assinatura ativa para ver a ilha.")
        case .failed(let reason):
            Haptics.warning()
            message = L.t("Não foi possível iniciar: %@", reason)
        }
        withAnimation(Motion.snappy) { liveActivityTestMessage = message }
    }

    /// Só liga com Pro ativo; ao desligar, encerra a atividade em andamento.
    private var liveActivityBinding: Binding<Bool> {
        Binding(
            get: { liveActivityEnabled },
            set: { newValue in
                guard newValue else {
                    liveActivityEnabled = false
                    LiveActivityService.shared.stop()
                    return
                }
                if store.hasProAccess {
                    liveActivityEnabled = true
                    LiveActivityService.shared.syncAll(with: subscriptions)
                } else {
                    Haptics.impact(.light)
                    showPaywall = true
                }
            }
        )
    }

    private var notificationsSection: some View {
        Section("Notificações") {
            Button {
                Task {
                    let granted = await NotificationService.shared.requestAuthorization()
                    notificationStatus = granted ? L.t("Ativadas") : L.t("Negadas")
                    if granted { rescheduleAll() }
                }
            } label: {
                Label("Permitir notificações", systemImage: "bell.badge")
            }

            Button {
                rescheduleAll()
                Haptics.success()
            } label: {
                Label("Reagendar lembretes", systemImage: "arrow.clockwise")
            }

            if let notificationStatus {
                LabeledContent("Status", value: notificationStatus)
            }
        }
    }

    private var appearanceSection: some View {
        Section("Aparência") {
            Picker("Tema", selection: $appearance) {
                ForEach(AppearanceOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
        }
    }

    private var languageSection: some View {
        Section {
            Picker("Idioma", selection: $language) {
                ForEach(AppLanguage.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        } footer: {
            Text("O widget usa o mesmo idioma do aplicativo.")
        }
    }

    private var currencySection: some View {
        Section {
            Picker("Moeda base", selection: baseCurrencyBinding) {
                ForEach(CurrencyCode.ordered) { code in
                    Text(code.displayLabel).tag(code.code)
                }
            }

            Button {
                Task { await CurrencyService.shared.refresh() }
            } label: {
                HStack {
                    Label("Atualizar cotação", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    if CurrencyService.shared.isRefreshing {
                        ProgressView()
                    }
                }
            }
            .disabled(CurrencyService.shared.isRefreshing)

            LabeledContent("Status", value: ratesStatus)
        } header: {
            Text("Moeda e cotação")
        } footer: {
            Text("Os totais são convertidos para a moeda base. As cotações são atualizadas automaticamente e usadas offline quando não há internet.")
        }
    }

    private var baseCurrencyBinding: Binding<String> {
        Binding(
            get: { CurrencyService.shared.baseCode },
            set: { CurrencyService.shared.baseCode = $0 }
        )
    }

    private var ratesStatus: String {
        guard let updated = CurrencyService.shared.lastUpdated else {
            return L.t("Usando valores aproximados offline.")
        }
        return L.t("Atualizada em %@", updated.formatted(date: .abbreviated, time: .shortened))
    }

    private var dataSection: some View {
        Section {
            NavigationLink {
                HistoryView(embedded: true)
            } label: {
                Label("Histórico de assinaturas", systemImage: "clock.arrow.circlepath")
            }

            exportRow

            #if DEBUG
            Button {
                SampleDataSeeder.seed(in: context)
                Haptics.success()
            } label: {
                Label("Carregar dados de exemplo", systemImage: "wand.and.stars")
            }
            #endif

            Button(role: .destructive) {
                showEraseConfirmation = true
            } label: {
                Label("Apagar todos os dados", systemImage: "trash")
            }
        } header: {
            Text("Dados")
        } footer: {
            if !store.hasProAccess {
                Text("A exportação em CSV faz parte do SubCheck Pro.")
            }
        }
    }

    /// Compartilha o CSV quando o Pro está ativo; sem ele, abre o paywall.
    @ViewBuilder
    private var exportRow: some View {
        if let exportURL {
            ShareLink(item: exportURL) {
                Label("Exportar em CSV", systemImage: "square.and.arrow.up")
            }
        } else {
            Button {
                Haptics.impact(.light)
                showPaywall = true
            } label: {
                HStack {
                    Label("Exportar em CSV", systemImage: "square.and.arrow.up")
                    Spacer()
                    Label(L.t("Pro"), systemImage: "lock.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.warning)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section("Sobre") {
            LabeledContent("Versão", value: appVersion)
            LabeledContent("Widget", value: L.t("Adicione pela tela inicial"))

            if let url = AppLinks.privacyPolicy {
                Link("Política de privacidade", destination: url)
            }
            if let url = AppLinks.termsOfUse {
                Link("Termos de uso", destination: url)
            }
            if let url = AppLinks.support {
                Link("Suporte", destination: url)
            }
        }
    }

    private func rescheduleAll() {
        for subscription in subscriptions where !subscription.isCancelled {
            NotificationService.shared.scheduleNotification(for: subscription)
        }
    }

    /// Gera (ou descarta) os arquivos conforme a permissão Pro.
    private func refreshExport() {
        guard store.hasProAccess else {
            exportURL = nil
            reportURL = nil
            return
        }
        exportURL = ExportService.subscriptionsCSV(subscriptions)
        reportURL = makeReport()
    }

    /// Arquivo do relatório em PDF pronto para compartilhar; `nil` sem Pro.
    private func makeReport() -> URL? {
        ReportService.monthlyReport(subscriptions)
    }

    /// Muda quando algo relevante das assinaturas muda, refazendo o CSV.
    private var exportSignature: Int {
        var hasher = Hasher()
        for subscription in subscriptions {
            hasher.combine(subscription.id)
            hasher.combine(subscription.name)
            hasher.combine(subscription.cost)
            hasher.combine(subscription.isCancelled)
        }
        return hasher.finalize()
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
