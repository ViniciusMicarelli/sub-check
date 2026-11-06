//
//  RootView.swift
//  SubCheck
//

import SwiftUI
import SwiftData

struct RootView: View {

    @Bindable private var router = AppRouter.shared
    @AppStorage("appearance") private var appearance: AppearanceOption = .system
    @AppStorage(L.languageKey) private var language: AppLanguage = .system
    @AppStorage("appLockEnabled") private var appLockEnabled = false
    @AppStorage(OnboardingView.doneKey) private var onboardingDone = false

    /// Destrava a tela de bloqueio depois do Face ID.
    @State private var isLocked = false
    /// Assinatura aberta a partir do link de um widget.
    @State private var linkedSubscription: LinkedSubscription?
    @Environment(\.scenePhase) private var scenePhase
    private var saveReporter = SaveReporter.shared

    private var store = StoreService.shared

    var body: some View {
        TabView(selection: $router.tab) {
            DashboardView()
                .tabItem { Label("Resumo", systemImage: "chart.pie.fill") }
                .tag(AppTab.dashboard)

            SubscriptionsView()
                .tabItem { Label("Assinaturas", systemImage: "list.bullet.rectangle.portrait.fill") }
                .tag(AppTab.subscriptions)

            BillsView()
                .tabItem { Label("Contas", systemImage: "wallet.pass.fill") }
                .tag(AppTab.bills)

            CategoriesView()
                .tabItem { Label("Categorias", systemImage: "square.grid.2x2.fill") }
                .tag(AppTab.categories)

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(.brand)
        .id(language)
        .fullScreenCover(isPresented: Binding(
            get: { !onboardingDone },
            set: { _ in }
        )) {
            OnboardingView()
        }
        .preferredColorScheme(appearance.colorScheme)
        // A troca de idioma reavalia as `LocalizedStringKey` sem reiniciar o app.
        .environment(\.locale, language.locale ?? Locale.current)
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
        .alert(
            L.t("Não foi possível salvar"),
            isPresented: Binding(
                get: { saveReporter.failure != nil },
                set: { if !$0 { saveReporter.failure = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(L.t("Suas últimas alterações podem não ter sido gravadas. Feche e abra o SubCheck de novo. Se continuar, libere espaço no aparelho."))
        }
        #if DEBUG
        // `-startTab bills` ao lançar no simulador abre direto na aba.
        .onAppear {
            switch UserDefaults.standard.string(forKey: "startTab") {
            case "bills": router.tab = .bills
            case "subscriptions": router.tab = .subscriptions
            case "categories": router.tab = .categories
            case "settings": router.tab = .settings
            default: break
            }
        }
        #endif
        .onChange(of: onboardingDone) { _, done in
            guard done else { return }
            Task { await NotificationService.shared.requestAuthorization() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { lockIfNeeded() }
            if phase == .active {
                store.refreshClock()
                refreshLiveActivity()
            }
        }
    }

    // MARK: - Ilha Dinâmica

    /// Ao voltar para o app, realinha a Live Activity com as assinaturas e
    /// recria a que já está velha (o iOS derruba a atividade após ~8h).
    private func refreshLiveActivity() {
        guard onboardingDone else { return }
        let context = SharedModelContainer.shared.mainContext
        let all = (try? context.fetch(FetchDescriptor<Subscription>())) ?? []
        LiveActivityService.shared.syncAll(with: all)

        // Virou o mês? Cada conta ganha a linha do novo mês.
        let bills = (try? context.fetch(FetchDescriptor<Bill>())) ?? []
        BillLedger.ensureEntries(for: bills, in: context)
        BillLedger.rescheduleNotifications(in: context)
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

        case "subscriptions": router.tab = .subscriptions
        case "bills":         router.tab = .bills
        case "categories":    router.tab = .categories
        case "history", "settings": router.tab = .settings
        default:              router.tab = .dashboard
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
