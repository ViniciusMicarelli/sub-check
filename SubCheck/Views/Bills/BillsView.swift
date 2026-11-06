//
//  BillsView.swift
//  SubCheck
//
//  Aba Contas: o salário líquido contra assinaturas e contas da casa. Cada
//  conta (água, luz, aluguel…) vence num dia fixo; no vencimento a pessoa
//  informa o valor e marca como paga.
//

import SwiftData
import SwiftUI

/// Pedido para abrir o formulário de conta nova.
struct BillAddRequest: Identifiable {
    let id = UUID()
    let preset: BillCategory?
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
    /// Quem pede uma conta nova (com ou sem categoria sugerida). Por item, o
    /// sheet sempre abre com o preset certo.
    @State private var addRequest: BillAddRequest?
    @State private var showSalary = false
    #if DEBUG
    @State private var debugDetail: Bill?
    #endif
    @State private var showPaywall = false

    // MARK: - Dados do mês

    private var month: Date { BillSchedule.monthStart(of: Date()) }

    private var monthEntries: [BillEntry] {
        allEntries.filter { $0.monthStart == month && !$0.isSkipped }
    }

    private var history: [UUID: [Double]] {
        BillPlanning.history(of: allEntries, before: month)
    }

    private var plan: MonthPlan {
        MonthPlan.make(salary: salary, subscriptions: subscriptions, bills: bills, entries: allEntries)
    }

    private func status(_ entry: BillEntry) -> BillStatus {
        BillMath.status(isPaid: entry.isPaid, dueDate: entry.dueDate)
    }

    private var toInform: [BillEntry] {
        monthEntries
            .filter { [.dueToday, .overdue].contains(status($0)) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var upcoming: [BillEntry] {
        monthEntries.filter { status($0) == .upcoming }.sorted { $0.dueDate < $1.dueDate }
    }

    private var paid: [BillEntry] {
        monthEntries.filter(\.isPaid).sorted { ($0.paidAt ?? $0.dueDate) > ($1.paidAt ?? $1.dueDate) }
    }

    private var activeBillCount: Int { bills.filter(\.isActive).count }

    private var canAddMore: Bool {
        store.hasProAccess || activeBillCount < StoreService.freeBillLimit
    }

    private func estimate(for entry: BillEntry) -> Double {
        BillMath.estimate(
            expected: bills.first { $0.id == entry.billID }?.expectedAmount ?? 0,
            previous: history[entry.billID] ?? []
        )
    }

    // MARK: - Tela

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    MonthSummaryCard(plan: plan, salaryDay: salaryDay) { showSalary = true }

                    if bills.isEmpty {
                        emptyState
                    } else {
                        if !toInform.isEmpty {
                            section(L.t("Para informar"), entries: toInform, highlight: true)
                        }
                        if !upcoming.isEmpty {
                            section(L.t("Próximas"), entries: upcoming)
                        }
                        if !paid.isEmpty {
                            section(L.t("Pagas este mês"), entries: paid)
                        }
                        if monthEntries.isEmpty {
                            Text("Nenhuma conta neste mês.")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                                .frame(maxWidth: .infinity)
                                .cardSurface()
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

    // MARK: - Seções

    private func section(_ title: String, entries: [BillEntry], highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                if highlight {
                    Text("\(entries.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.warning, in: Capsule())
                }
            }
            .padding(.horizontal, Spacing.xs)

            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    Button {
                        Haptics.impact(.light)
                        selectedEntry = entry
                    } label: {
                        BillRow(entry: entry, estimate: estimate(for: entry))
                    }
                    .buttonStyle(.plain)
                    .contextMenu { menu(for: entry) }

                    if index < entries.count - 1 {
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

    @ViewBuilder
    private func menu(for entry: BillEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            Label(entry.isPaid ? L.t("Editar valor") : L.t("Informar valor"), systemImage: "pencil")
        }
        if let bill = bills.first(where: { $0.id == entry.billID }) {
            Button {
                editingBill = bill
            } label: {
                Label("Editar conta", systemImage: "slider.horizontal.3")
            }
        }
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

    /// `-debugSheet entry|add|salary` ao lançar no simulador abre a tela direto.
    private func openDebugSheet() {
        #if DEBUG
        guard let which = UserDefaults.standard.string(forKey: "debugSheet") else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.5))
            switch which {
            case "entry": selectedEntry = toInform.first ?? monthEntries.first
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
