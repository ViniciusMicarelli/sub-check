import SwiftUI
import SwiftData

// MARK: - Edit Subscription View
struct EditSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss

    let initialSubscription: Subscription

    @State private var name: String
    @State private var cost: Double?
    @State private var frequency: RecurrenceFrequency
    @State private var startDate: Date
    @State private var enableReminders: Bool
    @State private var daysNoticeBefore: Int

    init(initialSubscription: Subscription) {
        self.initialSubscription = initialSubscription
        _name = State(initialValue: initialSubscription.name)
        _cost = State(initialValue: initialSubscription.cost)
        _frequency = State(initialValue: initialSubscription.frequency)
        _startDate = State(initialValue: initialSubscription.startDate)
        _enableReminders = State(initialValue: initialSubscription.enableReminders)
        _daysNoticeBefore = State(initialValue: initialSubscription.daysNoticeBefore)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes") {
                    TextField("Nome do Serviço", text: $name)

                    TextField("Valor", value: $cost, format: .currency(code: "BRL"))
                        #if os(iOS) || os(visionOS)
                        .keyboardType(.decimalPad)
                        #endif

                    Picker("Frequência", selection: $frequency) {
                        ForEach(RecurrenceFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    DatePicker("Data do 1º Pagamento", selection: $startDate, displayedComponents: .date)
                }

                Section("Lembretes") {
                    Toggle("Ativar Notificação", isOn: $enableReminders)

                    if enableReminders {
                        Stepper("Avisar \(daysNoticeBefore) dias antes", value: $daysNoticeBefore, in: 1...7)
                    }
                }
            }
            .navigationTitle("Editar Assinatura")
            #if os(iOS) || os(visionOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        saveSubscription()
                    }
                    .disabled(name.isEmpty || cost == nil)
                }
            }
        }
    }

    private func saveSubscription() {
        guard let costValue = cost else { return }

        initialSubscription.name = name
        initialSubscription.cost = costValue
        initialSubscription.startDate = startDate
        initialSubscription.frequency = frequency
        initialSubscription.enableReminders = enableReminders
        initialSubscription.daysNoticeBefore = daysNoticeBefore
        initialSubscription.category = SubscriptionManager.shared.categorize(name: name)
        NotificationManager.shared.scheduleNotification(for: initialSubscription)

        dismiss()
    }
}
