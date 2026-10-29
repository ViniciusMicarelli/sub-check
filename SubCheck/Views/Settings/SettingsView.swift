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

    @State private var showEraseConfirmation = false
    @State private var notificationStatus: String?

    var body: some View {
        NavigationStack {
            Form {
                notificationsSection
                appearanceSection
                dataSection
                aboutSection
            }
            .navigationTitle("Ajustes")
            .confirmationDialog(
                "Apagar todos os dados?",
                isPresented: $showEraseConfirmation,
                titleVisibility: .visible
            ) {
                Button("Apagar tudo", role: .destructive) {
                    Haptics.warning()
                    SampleDataSeeder.eraseAll(in: context)
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
                    notificationStatus = granted ? "Ativadas" : "Negadas"
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
            LabeledContent("Widget", value: "Adicione pela tela inicial")
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
