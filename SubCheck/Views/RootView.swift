//
//  RootView.swift
//  SubCheck
//

import SwiftUI

struct RootView: View {

    enum Tab: Hashable {
        case dashboard, subscriptions, categories, history, settings
    }

    @State private var selection: Tab = .dashboard
    @AppStorage("appearance") private var appearance: AppearanceOption = .system

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
    }
}
