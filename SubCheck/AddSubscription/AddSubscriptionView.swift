import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var cost: Double? = nil
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var startDate = Date()
    @State private var enableReminders = true
    @State private var daysNoticeBefore = 2
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Detalhes") {
                    TextField("Nome do Serviço (ex: Netflix)", text: $name)
                    
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
                
                Section("Lembrete") {
                    Toggle("Ativar Notificação", isOn: $enableReminders)
                    
                    if enableReminders {
                        Stepper("Avisar \(daysNoticeBefore) dias antes", value: $daysNoticeBefore, in: 1...7)
                    }
                }
            }
            .navigationTitle("Nova Assinatura")
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
        
        let newSubscription = Subscription(
            name: name,
            cost: costValue,
            startDate: startDate,
            frequency: frequency,
            category: SubscriptionManager.shared.categorize(name: name),
            enableReminders: enableReminders,
            daysNoticeBefore: daysNoticeBefore
        )
        
        modelContext.insert(newSubscription)
        
        // Agende a notificação local
        NotificationManager.shared.scheduleNotification(for: newSubscription)
        
        dismiss()
    }
}
