//
//  ReportView.swift
//  SubCheck
//
//  View for subscription reports
//

import SwiftUI
import Charts

struct ReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]
    
    @State private var selectedPeriod: Period = .current
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    enum Period {
        case current
        case month(Int)
        case year(Int)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Seleção de Período
                    PeriodSelectorView(period: $selectedPeriod, month: $selectedMonth, year: $selectedYear)
                    
                    // MARK: - Resumo do Período Selecionado
                    PeriodSummaryView(
                        subscriptions: subscriptions,
                        period: selectedPeriod,
                        month: selectedMonth,
                        year: selectedYear
                    )
                    
                    // MARK: - Gastos por Categoria
                    if !subscriptions.isEmpty {
                        CategoryDistributionChartView(subscriptions: subscriptions)
                    }
                    
                    // MARK: - Evolução Temporal
                    if selectedPeriod == .current {
                        TimeSeriesChartView(subscriptions: subscriptions)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Relatório")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Gerar Relatório PDF") {
                        generatePDFReport()
                    }
                }
            }
        }
    }
    
    private func generatePDFReport() {
        // Implementação futura
    }
}

struct PeriodSelectorView: View {
    @Binding var period: ReportView.Period
    @Binding var month: Int
    @Binding var year: Int
    
    var body: some View {
        Form {
            Section("Período") {
                Picker("Período", selection: $period) {
                    Text("Atual").tag(ReportView.Period.current)
                    ForEach(0...12) { m in
                        Text("Mês \(m + 1)").tag(ReportView.Period.month(m))
                    }
                    ForEach(2020...Calendar.current.component(.year, from: Date()) + 1) { y in
                        Text("Ano \(y)").tag(ReportView.Period.year(y))
                    }
                }
            }
        }
        .padding()
        .background(Color.secondarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PeriodSummaryView: View {
    let subscriptions: [Subscription]
    let period: ReportView.Period
    let month: Int
    let year: Int
    
    var totalMonthlyExpense: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyCost }
    }
    
    var subscriptionCount: Int {
        subscriptions.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gasto Mensal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "%.2f", totalMonthlyExpense), format: .currency(code: "BRL"))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(subscriptionCount) ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Assinaturas")
                        .font(.callout)
                        .fontWeight(.bold)
                }
            }
            
            // Subscriptions
            if !subscriptions.isEmpty {
                ForEach(subscriptions) { subscription in
                    SubscriptionRowView(subscription: subscription)
                }
            }
        }
        .padding(20)
        .background(Color.ultraDark)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct CategoryDistributionChartView: View {
    let subscriptions: [Subscription]
    
    private var categoryData: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: subscriptions, by: { categoryForSubscription($0) })
        return grouped.map { (key, items) in
            (category: key, amount: items.reduce(0) { $0 + $1.monthlyCost })
        }.sorted { $0.amount > $1.amount }
    }
    
    private func categoryForSubscription(_ subscription: Subscription) -> String {
        SubscriptionManager.shared.categorize(name: subscription.name)
    }
    
    var body: some View {
        Chart(categoryData, id: \.category) { item in
            SectorMark(
                angle: .value("Gasto", item.amount),
                innerRadius: .ratio(0.65),
                angularInset: 2.0
            )
            .cornerRadius(6)
            .foregroundStyle(by: .value("Categoria", item.category))
        }
        .frame(height: 200)
        .chartLegend(position: .bottom, alignment: .center, spacing: 12)
        .padding(.vertical, 8)
    }
}

struct TimeSeriesChartView: View {
    let subscriptions: [Subscription]
    
    private func generateTimeSeriesData() -> [(date: Date, amount: Double)] {
        // Gera dados mensais para o período selecionado
        // Implementação simplificada
        return []
    }
    
    var body: some View {
        let data = generateTimeSeriesData()
        
        Chart(data, id: \.date) { item in
            BarMark(x: .value("Mês", item.date), y: .value("Gasto", item.amount))
                .foregroundStyle(Color.accentColor)
        }
        .frame(height: 200)
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)
                    .foregroundStyle(categoryColor(for: subscription.category))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(subscription.cost, format: .currency(code: subscription.currencyCode))
                    .font(.subheadline)
                    .bold()
                
                Text(subscription.frequency.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.secondarySystemGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "entretenimento": return .purple
        case "trabalho": return .blue
        case "saúde": return .green
        case "utilitários": return .orange
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    ReportView()
}
