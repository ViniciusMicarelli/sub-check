//
//  BillsView.swift
//  SubCheck
//
//  Aba Contas: o salário líquido contra assinaturas e contas da casa. Cada
//  conta (água, luz, aluguel…) vence num dia fixo; no vencimento a pessoa
//  informa o valor e marca como paga. Dá para navegar pelos meses e ver tudo em
//  lista, em calendário ou como evolução.
//

import SwiftData
import SwiftUI

/// Pedido para abrir o formulário de conta nova.
struct BillAddRequest: Identifiable {
    let id = UUID()
    let preset: BillCategory?
}

private enum BillsMode: String, CaseIterable, Identifiable {
    case list, calendar, evolution
    var id: String { rawValue }
    var title: String {
        switch self {
        case .list: L.t("Lista")
        case .calendar: L.t("Calendário")
        case .evolution: L.t("Evolução")
        }
    }
}

struct BillsView: View {

    @Environment(\.modelContext) private var context

    @Query(sort: \Bill.name) private var bills: [Bill]
    @Query private var allEntries: [BillEntry]
    @Query private var subscriptions: [Subscription]

    @AppStorage(SalaryStore.amountKey) private var salary = 0.0
    @AppStorage(SalaryStore.dayKey) private var salaryDay = 5

    private var router = AppRouter.shared
    private var store = StoreService.shared

    @State private var selectedEntry: BillEntry?
    @State private var editingBill: Bill?
    @State private var addRequest: BillAddRequest?
    @State private var showSalary = false
    @State private var showPaywall = false
    @State private var monthOffset = 0
    @State private var confirmBulk = false
    @State private var mode: BillsMode = .list
    #if DEBUG
    @State private var debugDetail: Bill?
    #endif

    /// Quantos meses à frente dá para olhar (previsão).
    private let maxMonthsAhead = 3

    // MARK: - Mês selecionado

    private var currentMonth: Date { BillSchedule.monthStart(of: Date()) }

    private var month: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: currentMonth) ?? currentMonth
    }

    /// O mês mais antigo com alguma conta registrada (limite do "voltar").
    private var earliestMonth: Date {
        let fromEntries = allEntries.map(\.monthStart).min()
        let fromBills = bills.map { BillSchedule.monthStart(of: $0.createdAt) }.min()
        return [fromEntries, fromBills, currentMonth].compactMap { $0 }.min() ?? currentMonth
    }

    private var canGoBack: Bool { month > earliestMonth }
    private var canGoForward: Bool { monthOffset < maxMonthsAhead }

    private var occurrences: [BillOccurrence] {
        BillCalendar.occurrences(bills: bills, entries: allEntries, month: month)
    }

    private var plan: MonthPlan {
        MonthPlan.make(salary: salary, subscriptions: subscriptions, bills: bills, entries: allEntries, month: month)
    }

    private var navigation: MonthNavigation {
        MonthNavigation(
            canGoBack: canGoBack,
            canGoForward: canGoForward,
            isCurrent: monthOffset == 0,
            back: { withAnimation(.snappy) { monthOffset -= 1 } },
            forward: { withAnimation(.snappy) { monthOffset += 1 } },
            today: { withAnimation(.snappy) { monthOffset = 0 } }
        )
    }

    private var toInform: [BillOccurrence] { occurrences.filter { [.dueToday, .overdue].contains($0.status) } }
    private var upcoming: [BillOccurrence] { occurrences.filter { $0.status == .upcoming } }
    private var paid: [BillOccurrence] {
        occurrences.filter { $0.status == .paid }
            .sorted { ($0.paidAt ?? $0.dueDate) > ($1.paidAt ?? $1.dueDate) }
    }

    /// Vencidas ou de hoje que dá para marcar como pagas de uma vez.
    private var bulkPayable: [BillOccurrence] { BillLedger.bulkPayable(occurrences) }
    private var bulkTotal: Double { bulkPayable.reduce(0) { $0 + $1.amount } }

    private var isSalaryDay: Bool { salary > 0 && BillLedger.isSalaryDay(salaryDay) }

    private var activeBillCount: Int { bills.filter(\.isActive).count }

    private var canAddMore: Bool {
        store.hasProAccess || activeBillCount < StoreService.freeBillLimit
    }

    // MARK: - Tela

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    MonthSummaryCard(plan: plan, salaryDay: salaryDay, month: month, navigation: navigation) {
                        showSalary = true
                    }

                    if bills.isEmpty {
                        emptyState
                    } else {
                        Picker("Visualização", selection: $mode) {
                            ForEach(BillsMode.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)

                        switch mode {
                        case .list: listContent
                        case .calendar: calendarContent
                        case .evolution: evolutionContent
                        }
                    }
                }
                .padding(Spacing.lg)
                .padding(.bottom, 80)
            }
            .background(Color.appBackground)
            .navigationTitle("Contas")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        startAdding(preset: nil)
                    } label: {
                        Label("Nova conta", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $addRequest) { AddBillView(preset: $0.preset) }
            .sheet(item: $editingBill) { AddBillView(bill: $0) }
            .sheet(item: $selectedEntry) { BillEntrySheet(entry: $0) }
            .sheet(isPresented: $showSalary) { SalarySheet() }
            #if DEBUG
            .sheet(item: $debugDetail) { bill in
                NavigationStack { BillDetailView(bill: bill) }
            }
            #endif
            .sheet(isPresented: $showPaywall) {
                ProView(reason: L.t("Você atingiu o limite de %lld contas.", StoreService.freeBillLimit))
            }
            .onAppear {
                BillLedger.ensureEntries(for: bills, in: context)
                openDebugSheet()
            }
            // Tocar na notificação abre direto o valor da conta.
            .onChange(of: router.billToOpen, initial: true) { _, id in
                guard let id else { return }
                openEntry(for: id)
            }
        }
    }

    // MARK: - Lista

    @ViewBuilder
    private var listContent: some View {
        if occurrences.isEmpty {
            Text("Nenhuma conta neste mês.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .frame(maxWidth: .infinity)
                .cardSurface()
        } else {
            if monthOffset == 0, !bulkPayable.isEmpty {
                bulkCard
            }
            if !toInform.isEmpty {
                section(L.t("Para informar"), items: toInform, highlight: true)
            }
            if !upcoming.isEmpty {
                section(monthOffset > 0 ? L.t("Previstas") : L.t("Próximas"), items: upcoming)
            }
            if !paid.isEmpty {
                section(monthOffset == 0 ? L.t("Pagas este mês") : L.t("Pagas"), items: paid)
            }
        }
    }

    /// "Marcar tudo como pago": destaque no dia do salário, discreto nos outros.
    private var bulkCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(
                isSalaryDay ? L.t("Hoje é dia do salário") : L.t("Contas vencidas sem baixa"),
                systemImage: isSalaryDay ? "banknote.fill" : "checklist"
            )
            .font(.headline)
            .foregroundStyle(Color.textPrimary)

            Text(L.t("Marcar %lld conta(s) (%@) como pagas de uma vez? Cada uma usa o valor que já tem.",
                     bulkPayable.count, Money.format(bulkTotal)))
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)

            Button {
                confirmBulk = true
            } label: {
                Text("Marcar todas como pagas")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.brandGradient, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .fill(isSalaryDay ? Color.brand.opacity(0.10) : Color.elevatedBackground)
        )
        .confirmationDialog(
            L.t("Marcar %lld conta(s) como pagas?", bulkPayable.count),
            isPresented: $confirmBulk,
            titleVisibility: .visible
        ) {
            Button("Marcar todas como pagas") {
                let result = BillLedger.markAllPaid(bulkPayable, in: context)
                if result.count > 0 {
                    Haptics.success()
                    BillLedger.refreshSurfaces(in: context)
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Dá para desfazer em cada conta.")
        }
    }

    private func section(_ title: String, items: [BillOccurrence], highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                if highlight {
                    Text("\(items.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.warning, in: Capsule())
                }
            }
            .padding(.horizontal, Spacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    Button {
                        Haptics.impact(.light)
                        select(item)
                    } label: {
                        BillRow(occurrence: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu { menu(for: item) }

                    if index < items.count - 1 {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .cardSurface(padding: Spacing.md)
            .overlay {
                if highlight {
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(Color.warning.opacity(0.5), lineWidth: 1.5)
                }
            }
        }
    }

    /// Linha salva abre o valor; previsão (mês futuro) abre a conta para editar.
    private func select(_ item: BillOccurrence) {
        if let entry = item.entry {
            selectedEntry = entry
        } else if let bill = bills.first(where: { $0.id == item.billID }) {
            editingBill = bill
        }
    }

    @ViewBuilder
    private func menu(for item: BillOccurrence) -> some View {
        if let entry = item.entry {
            Button {
                selectedEntry = entry
            } label: {
                Label(entry.isPaid ? "Editar valor" : "Informar valor", systemImage: "pencil")
            }
        }
        if let bill = bills.first(where: { $0.id == item.billID }) {
            Button {
                editingBill = bill
            } label: {
                Label("Editar conta", systemImage: "slider.horizontal.3")
            }
        }
        if let entry = item.entry {
            if entry.isPaid {
                Button {
                    BillLedger.unpay(entry, in: context)
                    BillLedger.refreshSurfaces(in: context)
                } label: {
                    Label("Desmarcar pagamento", systemImage: "arrow.uturn.backward")
                }
            } else {
                Button(role: .destructive) {
                    BillLedger.skip(entry, in: context)
                    BillLedger.refreshSurfaces(in: context)
                } label: {
                    Label("Pular este mês", systemImage: "forward.end")
                }
            }
        }
    }

    // MARK: - Calendário e evolução

    private var calendarContent: some View {
        BillCalendarView(
            month: month,
            occurrences: occurrences,
            charges: SubscriptionCalendar.charges(of: subscriptions, inMonth: month),
            salary: salary,
            salaryDay: salaryDay
        ) { select($0) }
    }

    private var evolutionContent: some View {
        let totals = BillEvolution.totals(bills: bills, entries: allEntries, endingAt: month)
        return BillEvolutionView(
            month: month,
            totals: totals,
            changes: BillEvolution.changes(occurrences: occurrences, entries: allEntries, month: month),
            salary: salary
        )
    }

    // MARK: - Vazio

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            EmptyStateView(
                icon: "wallet.pass",
                title: L.t("Nenhuma conta ainda"),
                message: L.t("Cadastre água, luz, aluguel… No dia do vencimento você informa o valor e marca como paga.")
            )

            Text("Comece por uma destas")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.textSecondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: Spacing.sm)], spacing: Spacing.sm) {
                ForEach([BillCategory.water, .electricity, .gas, .internet, .rent, .condo, .phone, .school]) { category in
                    Button {
                        Haptics.impact(.light)
                        startAdding(preset: category)
                    } label: {
                        Label(category.displayName, systemImage: category.icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(category.color)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm + 2)
                            .frame(maxWidth: .infinity)
                            .background(category.color.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .cardSurface()
    }

    // MARK: - Ações

    private func startAdding(preset: BillCategory?) {
        guard canAddMore else {
            showPaywall = true
            return
        }
        addRequest = BillAddRequest(preset: preset)
    }

    /// `-debugSheet entry|add|salary|detail` e `-debugMode calendar|evolution`
    /// ao lançar no simulador abrem a tela direto.
    private func openDebugSheet() {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "debugMode"), let m = BillsMode(rawValue: raw) { mode = m }
        if let raw = UserDefaults.standard.string(forKey: "debugMonthOffset"), let offset = Int(raw) { monthOffset = offset }
        guard let which = UserDefaults.standard.string(forKey: "debugSheet") else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            switch which {
            case "entry": selectedEntry = occurrences.first(where: { [.dueToday, .overdue].contains($0.status) })?.entry ?? occurrences.first?.entry
            case "add": addRequest = BillAddRequest(preset: .water)
            case "salary": showSalary = true
            case "detail": debugDetail = bills.first { $0.name == "Conta de luz" }
            default: break
            }
        }
        #endif
    }

    private func openEntry(for billID: UUID) {
        defer { router.billToOpen = nil }
        // Vindo de uma notificação: volta para o mês atual, em lista.
        monthOffset = 0
        mode = .list
        BillLedger.ensureEntries(for: bills, in: context)

        let descriptor = FetchDescriptor<BillEntry>(
            predicate: #Predicate { $0.billID == billID && !$0.isPaid && !$0.isSkipped },
            sortBy: [SortDescriptor(\.dueDate, order: .reverse)]
        )
        if let entry = (try? context.fetch(descriptor))?.first {
            selectedEntry = entry
        }
    }
}
