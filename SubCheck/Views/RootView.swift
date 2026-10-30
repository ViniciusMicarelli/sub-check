//
//  RootView.swift
//  SubCheck
//

import SwiftUI
import SwiftData

struct RootView: View {

    enum Tab: Hashable {
        case dashboard, subscriptions, categories, history, settings
    }

    @State private var selection: Tab = .dashboard
    @AppStorage("appearance") private var appearance: AppearanceOption = .system
    @AppStorage(L.languageKey) private var language: AppLanguage = .system
    @AppStorage("appLockEnabled") private var appLockEnabled = false

    /// Destrava a tela de bloqueio depois do Face ID.
    @State private var isLocked = false
    /// Assinatura aberta a partir do link de um widget.
    @State private var linkedSubscription: LinkedSubscription?
    @Environment(\.scenePhase) private var scenePhase

    private var store = StoreService.shared

    var body: some View {
        TabView(selection: $selection) {
            DashboardView()
                .tabItem { Label("Resumo", systemImage: "chart.pie.fill") }
                .tag(Tab.dashboard)

            SubscriptionsView()
                .tabItem { Label("Assinaturas", systemImage: "list.bullet.rectangle.portrait.fill") }
                .tag(Tab.subscriptions)

            CategoriesView()
                .tabItem { Label("Categorias", systemImage: "square.grid.2x2.fill") }
                .tag(Tab.categories)

            HistoryView()
                .tabItem { Label("Histórico", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(.brand)
        .preferredColorScheme(appearance.colorScheme)
        // A troca de idioma reavalia as `LocalizedStringKey` sem reiniciar o app.
        .environment(\.locale, language.locale ?? Locale.current)
        .id(language)
        .onOpenURL(perform: handle)
        .sheet(item: $linkedSubscription) { linked in
            LinkedSubscriptionView(link: linked)
        }
        .overlay {
            if isLocked {
                AppLockView { isLocked = false }
                    .transition(.opacity)
            }
        }
        .animation(.snappy, value: isLocked)
        .onAppear(perform: lockIfNeeded)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { lockIfNeeded() }
        }
    }

    // MARK: - Bloqueio

    /// Trava na abertura e ao voltar do segundo plano; só vale para o Pro.
    private func lockIfNeeded() {
        guard appLockEnabled, store.hasProAccess else { return }
        isLocked = true
    }

    // MARK: - Links dos widgets

    private func handle(_ url: URL) {
        guard url.scheme == WidgetLink.scheme else { return }

        switch url.host() {
        case "subscription":
            guard let raw = url.pathComponents.dropFirst().first,
                  let id = UUID(uuidString: raw) else { return }
            linkedSubscription = LinkedSubscription(id: id)

        case "subscriptions": selection = .subscriptions
        case "categories":    selection = .categories
        case "history":       selection = .history
        case "settings":      selection = .settings
        default:              selection = .dashboard
        }
    }
}

// MARK: - Link direto para uma assinatura

/// Identificador vindo do widget; embrulhado para virar `Identifiable` no sheet.
struct LinkedSubscription: Identifiable {
    let id: UUID
}

/// Abre a assinatura tocada no widget: o link traz apenas o identificador,
/// então a busca acontece aqui.
struct LinkedSubscriptionView: View {

    @Environment(\.dismiss) private var dismiss

    let link: LinkedSubscription

    @Query private var matches: [Subscription]

    init(link: LinkedSubscription) {
        self.link = link
        // O `#Predicate` não aceita acessar `link.id` direto; a cópia local
        // deixa a expressão capturar um valor simples.
        let id = link.id
        _matches = Query(filter: #Predicate<Subscription> { $0.id == id })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let subscription = matches.first {
                    SubscriptionDetailView(subscription: subscription)
                } else {
                    EmptyStateView(
                        icon: "questionmark.circle",
                        title: L.t("Assinatura não encontrada"),
                        message: L.t("Ela pode ter sido excluída.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}
