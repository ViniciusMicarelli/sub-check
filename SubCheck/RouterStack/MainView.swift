//
//  MainView.swift
//  SubCheck
//
//  Main view that routes to destinations
//

import SwiftUI

// MARK: - MainView

struct MainView: View {
    @EnvironmentObject var router: NavigationRouter
    
    var body: some View {
        ZStack {
            Group {
                switch router.currentPath {
                case "dashboard":
                    DashboardDestinationView()
                case "subscriptions":
                    SubscriptionsDestinationView()
                case "add-subscription":
                    AddSubscriptionDestinationView()
                case "edit-subscription":
                    EditSubscriptionDestinationView()
                case "settings":
                    SettingsDestinationView()
                case "history":
                        HistoryDestinationView()
                case "report":
                    ReportDestinationView()
                default:
                    DashboardDestinationView()
                }
            }
            .modifier(router.presentationType.destinationModifier)
            .environmentObject(router)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if router.hasBackButton {
                    ToolbarItem(placement: .navigation) {
                        Button("← Voltar") {
                            router.navigateBack()
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarFrame) {
                    Menu {
                        Button("Dashboard") {
                            router.navigate(to: "dashboard")
                        }
                        Button("Assinaturas") {
                            router.navigate(to: "subscriptions")
                        }
                        Button("Configurações") {
                            router.navigate(to: "settings")
                        }
                    } label: {
                        Image(systemName: "chevron.up.chevron.down")
                    }
                }
                
                // Dismiss on tap gesture
                if router.presentationType == .sheet {
                    Button("✕") {
                        router.dismissSheet()
                    }
                    .font(.title2)
                    .foregroundColor(.primary)
                }
            }
        }
        .ignoresSafeArea(safeAreas: [.top, .bottom])
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .environmentObject(NavigationRouter())
}
