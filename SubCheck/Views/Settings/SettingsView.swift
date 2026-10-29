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

    @State private var showEraseConfirmation = false
    @State private var notificationStatus: String?

    var body: some View {
        NavigationStack {
            Form {
                notificationsSection
                appearanceSection
                languageSection
                currencySection
                dataSection
                aboutSection
            }
            .navigationTitle("Ajustes")
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
        Section("Dados") {
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

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
