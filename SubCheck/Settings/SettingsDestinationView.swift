//
//  SettingsView.swift
//  SubCheck
//
//  Settings and preferences view
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appearance) private var appearance
    
    @State private var isDarkMode = true
    @State private var isAnonymous = false
    @State private var autoBackup: String = "daily"
    @State private var pushNotifications: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Aparência") {
                    Toggle("Modo Escuro", isOn: $isDarkMode)
                    
                    LabeledContent("Tema", value: appearance.name)
                }
                
                Section("Privacidade") {
                    Toggle("Modo Anônimo", isOn: $isAnonymous)
                    
                    Text("Sua atividade não será rastreada quando anonimizado.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Backup") {
                    Picker("Frequência de Backup", selection: $autoBackup) {
                        Text("Diário").tag("daily")
                        Text("Semanal").tag("weekly")
                        Text("Mensal").tag("monthly")
                    }
                }
                
                Section("Notificações") {
                    Toggle("Notificações Push", isOn: $pushNotifications)
                    
                    LabeledContent("Descrições em Notificações", value: DescriptionLimitView(limit: 50))
                }
                
                Section("Sobre") {
                    Text("Versão")
                        .font(.headline)
                    
                    Text("1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    Button("Ver Changelog") {
                        // Open changelog
                    }
                    
                    Button("Avalie o App") {
                        // Open App Store
                    }
                }
            }
            .navigationTitle("Configurações")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        saveSettings()
                    }
                }
            }
        }
    }
    
    private func saveSettings() {
        // Salvar configurações no UserDefaults ou CoreData
    }
}

struct DescriptionLimitView: View {
    let limit: Int
    
    var body: some View {
        HStack {
            Text("Caracteres")
                .font(.caption)
            
            Spacer()
            
            Stepper("\(limit)", value: Binding(
                store: _limit,
                get: { $0 },
                set: { $0 = max(10, min(500, $0)) }
            ), in: 10...500)
            
            Text("max")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    @State private var limit: Int = 50
}

#Preview {
    SettingsView()
}
