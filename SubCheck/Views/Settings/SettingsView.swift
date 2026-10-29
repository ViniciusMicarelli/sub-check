//
//  SettingsView.swift
//  SubCheck
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var context
    @Query private var subscriptions: [Subscription]

    @AppStorage("appearance") private var appearance: AppearanceOption = .system
    @AppStorage(L.languageKey) private var language: AppLanguage = .system
    @AppStorage("appLockEnabled") private var appLockEnabled = false

    @State private var showEraseConfirmation = false
    @State private var showPaywall = false
    @State private var notificationStatus: String?
    /// Arquivo do CSV pronto para compartilhar; `nil` sem Pro. Refeito
    /// quando o conjunto de assinaturas muda.
    @State private var exportURL: URL?

    private var store = StoreService.shared

    var body: some View {
        NavigationStack {
            Form {
                proSection
                notificationsSection
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
            .onChange(of: store.isPro) { _, _ in refreshExport() }
            .onChange(of: language) { _, newValue in
                L.store(newValue)
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
            Text(
                store.isPro
                    ? L.t("Obrigado por apoiar o SubCheck.")
                    : L.t("Um pagamento único libera todos os recursos para sempre.")
            )
        }
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
                store.isPro
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
                if store.isPro {
                    appLockEnabled = true
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
            exportRow

            Button {
                SampleDataSeeder.seed(in: context)
                Haptics.success()
            } label: {
                Label("Carregar dados de exemplo", systemImage: "wand.and.stars")
            }

            Button(role: .destructive) {
                showEraseConfirmation = true
            } label: {
                Label("Apagar todos os dados", systemImage: "trash")
            }
        } header: {
            Text("Dados")
        } footer: {
            if !store.isPro {
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
        }
    }

    private func rescheduleAll() {
        for subscription in subscriptions where !subscription.isCancelled {
            NotificationService.shared.scheduleNotification(for: subscription)
        }
    }

    /// Gera (ou descarta) o CSV conforme a permissão Pro.
    private func refreshExport() {
        exportURL = store.isPro ? ExportService.subscriptionsCSV(subscriptions) : nil
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
