import SwiftUI
import SwiftData
import Charts
import WidgetKit

// MARK: - 1. Dashboard de Alta Fidelidade com Swift Charts

struct EnhancedDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    
    @State private var isAddingSubscription = false
    @State private var selectedCategory: String? = nil
    
    // Gastos totais calculados
    private var totalMonthlyExpense: Double {
        subscriptions.reduce(0) { $0 + $1.monthlyCost }
    }
    
    private var totalYearlyExpense: Double {
        totalMonthlyExpense * 12
    }
    
    // Próxima cobrança iminente
    private var nextUpcomingSubscription: Subscription? {
        subscriptions.min(by: { $0.nextBillingDate < $1.nextBillingDate })
    }
    
    // Dados agrupados por Categoria para o Gráfico de Rosca
    private var categoryExpenses: [(category: String, amount: Double)] {
        let grouped = Dictionary(grouping: subscriptions, by: { $0.category })
        return grouped.map { (key, items) in
            (category: key, amount: items.reduce(0) { $0 + $1.monthlyCost })
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // MARK: Hero Summary Card
                    HeroMetricCard(
                        monthlyTotal: totalMonthlyExpense,
                        yearlyTotal: totalYearlyExpense,
                        subscriptionCount: subscriptions.count,
                        upcoming: nextUpcomingSubscription
                    )
                    
                    // MARK: Gráfico de Distribuição (Swift Charts)
                    if !subscriptions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Distribuição por Categoria")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Chart(categoryExpenses, id: \.category) { item in
                                SectorMark(
                                    angle: .value("Gasto", item.amount),
                                    innerRadius: .ratio(0.65),
                                    angularInset: 2.0
                                )
                                .cornerRadius(6)
                                .foregroundStyle(by: .value("Categoria", item.category))
                            }
                            .frame(height: 180)
                            .chartLegend(position: .bottom, alignment: .center, spacing: 12)
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    
                    // MARK: Seção de Assinaturas Ativas
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Assinaturas Ativas")
                                .font(.title3)
                                .bold()
                            
                            Spacer()
                            
                            Button {
                                isAddingSubscription = true
                            } label: {
                                Label("Nova", systemImage: "plus.circle.fill")
                                    .font(.subheadline)
                                    .bold()
                            }
                        }
                        
                        if subscriptions.isEmpty {
                            ContentUnavailableView(
                                "Nenhuma assinatura",
                                systemImage: "creditcard.and.123",
                                description: Text("Adicione suas assinaturas para controlar renovações e gastos.")
                            )
                            .padding(.top, 20)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(subscriptions) { sub in
                                    SubscriptionCardView(subscription: sub)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SubCheck")
            .sheet(isPresented: $isAddingSubscription) {
                AddSubscriptionView()
            }
        }
    }
}

// MARK: - 2. Componentes de UI Refinados

struct HeroMetricCard: View {
    let monthlyTotal: Double
    let yearlyTotal: Double
    let subscriptionCount: Int
    let upcoming: Subscription?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL MENSAL")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Text(monthlyTotal, format: .currency(code: "BRL"))
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(subscriptionCount) ativas")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
            }
            
            Divider()
                .overlay(.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Projeção Anual")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(yearlyTotal, format: .currency(code: "BRL"))
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                if let upcoming = upcoming {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Próxima: \(upcoming.name)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(upcoming.nextBillingDate.formatted(.dateTime.day().month()))
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.indigo],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct SubscriptionCardView: View {
    let subscription: Subscription
    
    var body: some View {
        HStack(spacing: 14) {
            // Ícone Categoria / Status
            ZStack {
                Circle()
                    .fill(categoryColor(for: subscription.category).opacity(0.15))
                    .frame(width: 46, height: 46)
                
                Image(systemName: categoryIcon(for: subscription.category))
                    .foregroundStyle(categoryColor(for: subscription.category))
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.body)
                    .bold()
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Text(subscription.category)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(subscription.nextBillingDate.formatted(date: .numeric, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(subscription.cost, format: .currency(code: subscription.currencyCode))
                    .font(.callout)
                    .bold()
                    .foregroundStyle(.primary)
                
                Text(subscription.frequency.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Entretenimento": return .purple
        case "Trabalho": return .blue
        case "Saúde": return .green
        case "Utilitários": return .orange
        default: return .gray
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Entretenimento": return "tv.fill"
        case "Trabalho": return "briefcase.fill"
        case "Saúde": return "heart.fill"
        case "Utilitários": return "bolt.fill"
        default: return "creditcard.fill"
        }
    }
}

// MARK: - 3. Extension de Widget (WidgetKit + SwiftData)

struct SubscriptionEntry: TimelineEntry {
    let date: Date
    let monthlyTotal: Double
    let upcomingSubscription: Subscription?
}

struct SubCheckWidgetProvider: TimelineProvider {
    typealias Entry = SubscriptionEntry
    
    func placeholder(in context: Context) -> SubscriptionEntry {
        SubscriptionEntry(
            date: Date(),
            monthlyTotal: 149.90,
            upcomingSubscription: Subscription(name: "Netflix", cost: 55.90)
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SubscriptionEntry) -> Void) {
        completion(placeholder(in: context))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SubscriptionEntry>) -> Void) {
        Task { @MainActor in
            let container = try? ModelContainer(for: Subscription.self)
            let descriptor = FetchDescriptor<Subscription>()
            let subs = (try? container?.mainContext.fetch(descriptor)) ?? []
            
            let total = subs.reduce(0) { $0 + $1.monthlyCost }
            let upcoming = subs.min(by: { $0.nextBillingDate < $1.nextBillingDate })
            
            let entry = SubscriptionEntry(date: Date(), monthlyTotal: total, upcomingSubscription: upcoming)
            
            // Atualiza a cada 4 horas
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct SubCheckWidgetEntryView: View {
    var entry: SubCheckWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "creditcard.fill")
                        .foregroundStyle(.blue)
                    Text("SubCheck")
                        .font(.caption)
                        .bold()
                }
                
                Spacer()
                
                Text(entry.monthlyTotal, format: .currency(code: "BRL"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.8)
                
                Text("Gasto Mensal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .containerBackground(for: .widget) { Color(.systemBackground) }
            
        case .systemMedium:
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GASTO MENSAL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    Text(entry.monthlyTotal, format: .currency(code: "BRL"))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                
                Divider()
                
                if let upcoming = entry.upcomingSubscription {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PRÓXIMO VENCIMENTO")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        
                        Text(upcoming.name)
                            .font(.headline)
                        
                        Text("\(upcoming.cost.formatted(.currency(code: "BRL"))) • \(upcoming.nextBillingDate.formatted(.dateTime.day().month()))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                } else {
                    Text("Sem cobranças próximas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .containerBackground(for: .widget) { Color(.systemBackground) }
            
        default:
            Text("SubCheck Widget")
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
    }
}

@main
struct SubCheckWidget: Widget {
    let kind: String = "SubCheckWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubCheckWidgetProvider()) { entry in
            SubCheckWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Resumo do SubCheck")
        .description("Acompanhe o total mensal e a próxima cobrança diretamente da sua tela inicial.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}