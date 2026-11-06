//
//  Bill.swift
//  SubCheck
//
//  Conta recorrente da casa (água, luz, aluguel…). Diferente de uma assinatura,
//  o valor muitas vezes muda todo mês: a pessoa informa o valor no vencimento.
//  `Bill` é a conta; `BillEntry` é cada mês dela.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Bill {
    // CloudKit exige valor padrão em toda propriedade (iCloud em Ajustes).
    var id: UUID = UUID()
    var name: String = ""
    var categoryRaw: String = BillCategory.other.rawValue
    /// Dia do mês em que vence (1…31). Em meses curtos vence no último dia.
    var dueDay: Int = 1
    /// `true` para valor fixo (aluguel); `false` quando varia (luz, água).
    var isFixed: Bool = false
    /// Valor fixo ou estimativa. 0 = sem estimativa.
    var expectedAmount: Double = 0
    var isActive: Bool = true
    var remindersEnabled: Bool = true
    /// Dias de antecedência do aviso. 0 = no próprio dia.
    var reminderDaysBefore: Int = 1
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String,
        category: BillCategory = .other,
        dueDay: Int,
        isFixed: Bool = false,
        expectedAmount: Double = 0,
        remindersEnabled: Bool = true,
        reminderDaysBefore: Int = 1
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.dueDay = min(max(dueDay, 1), 31)
        self.isFixed = isFixed
        self.expectedAmount = max(expectedAmount, 0)
        self.remindersEnabled = remindersEnabled
        self.reminderDaysBefore = min(max(reminderDaysBefore, 0), 7)
    }

    var category: BillCategory {
        get { BillCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
}

/// Um mês de uma conta: quando vence e quanto foi (ou será) o valor.
@Model
final class BillEntry {
    var id: UUID = UUID()
    /// Referência solta (não é relationship): o histórico sobrevive à exclusão
    /// da conta, como em `PaymentRecord`.
    var billID: UUID = UUID()
    var billName: String = ""
    var categoryRaw: String = BillCategory.other.rawValue
    /// Primeiro dia do mês a que a conta pertence.
    var monthStart: Date = Date()
    var dueDate: Date = Date()
    /// 0 enquanto a pessoa ainda não informou (conta variável).
    var amount: Double = 0
    var isPaid: Bool = false
    var paidAt: Date?
    /// "Pular este mês": a linha fica (para não ser recriada), mas some das
    /// listas e das somas.
    var isSkipped: Bool = false

    init(
        id: UUID = UUID(),
        billID: UUID,
        billName: String,
        categoryRaw: String,
        monthStart: Date,
        dueDate: Date,
        amount: Double = 0,
        isPaid: Bool = false,
        paidAt: Date? = nil
    ) {
        self.id = id
        self.billID = billID
        self.billName = billName
        self.categoryRaw = categoryRaw
        self.monthStart = monthStart
        self.dueDate = dueDate
        self.amount = amount
        self.isPaid = isPaid
        self.paidAt = paidAt
    }

    var category: BillCategory { BillCategory(rawValue: categoryRaw) ?? .other }
}

enum BillCategory: String, CaseIterable, Identifiable, Codable {
    case water, electricity, gas, internet, phone, rent, condo, tax, school, health, card, other

    var id: String { rawValue }

    var displayName: String { L.t("bill.category.\(rawValue)") }

    var icon: String {
        switch self {
        case .water: "drop.fill"
        case .electricity: "bolt.fill"
        case .gas: "flame.fill"
        case .internet: "wifi"
        case .phone: "phone.fill"
        case .rent: "house.fill"
        case .condo: "building.2.fill"
        case .tax: "doc.text.fill"
        case .school: "graduationcap.fill"
        case .health: "cross.case.fill"
        case .card: "creditcard.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .water: Color(red: 0.16, green: 0.55, blue: 0.96)
        case .electricity: Color(red: 0.96, green: 0.65, blue: 0.13)
        case .gas: Color(red: 0.93, green: 0.40, blue: 0.20)
        case .internet: Color(red: 0.45, green: 0.35, blue: 0.95)
        case .phone: Color(red: 0.20, green: 0.70, blue: 0.62)
        case .rent: Color(red: 0.36, green: 0.40, blue: 0.86)
        case .condo: Color(red: 0.55, green: 0.45, blue: 0.80)
        case .tax: Color(red: 0.55, green: 0.55, blue: 0.62)
        case .school: Color(red: 0.90, green: 0.35, blue: 0.55)
        case .health: Color(red: 0.91, green: 0.26, blue: 0.29)
        case .card: Color(red: 0.55, green: 0.30, blue: 0.85)
        case .other: Color(red: 0.50, green: 0.52, blue: 0.60)
        }
    }

    /// Sugestão de tipo: água e luz mudam todo mês; aluguel e plano não.
    var isUsuallyVariable: Bool {
        switch self {
        case .water, .electricity, .gas, .card, .phone: true
        default: false
        }
    }
}
