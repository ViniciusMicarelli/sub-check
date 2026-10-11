import SwiftUI

struct DashboardView: View {
    var body: some View {
        TabView {
            DashboardTabView()
                .tabItem { Label("Dashboard", systemImage: "chart.pie") }
            SubscriptionsTabView()
                .tabItem { Label("Assinaturas", systemImage: "creditcard") }
        }
    }
}

// MARK: - SubscriptionManager
class SubscriptionManager {
    static let shared = SubscriptionManager()
    private init() {}

    private var categoryRules: [(String, String)] = [
        ("Netflix", "Entretenimento"),
        ("Spotify", "Entretenimento"),
        ("Disney+", "Entretenimento"),
        ("Amazon Prime", "Entretenimento"),
        ("Adobe", "Trabalho"),
        ("Zoom", "Trabalho"),
        ("Microsoft 365", "Trabalho"),
        ("Apple One", "Utilitários"),
        ("Electricity", "Utilitários"),
        ("Internet", "Utilitários"),
        ("Netflix Health", "Saúde"),
        ("Gym Pass", "Saúde"),
        ("MyFitnessPal", "Saúde")
    ]

    func categorize(name: String) -> String {
        for (subscriptionName, category) in categoryRules {
            if name.range(of: subscriptionName, options: .caseInsensitive) != nil {
                return category
            }
        }
        return "Outros"
    }
}
