//
//  CurrencyField.swift
//  SubCheck
//
//  Campo de valor em dinheiro: o teclado é só numérico e o texto já vem
//  mascarado com duas casas decimais (digitar 1-2-3-4-5 vira "123,45").
//  A barra do teclado tem um botão "OK" que o fecha, e arrastar a lista
//  também fecha. Substitui os `TextField(value:format:)` soltos.
//

import SwiftUI
import UIKit

/// Regra de máscara, pura para teste.
enum CurrencyMask {

    /// Quantidade máxima de dígitos (999 bilhões com centavos).
    static let maxDigits = 12

    /// Só os dígitos de um texto qualquer, sem zeros à esquerda.
    static func digits(from text: String) -> String {
        let only = text.filter(\.isASCII).filter(\.isNumber)
        let trimmed = only.drop(while: { $0 == "0" })
        return String(trimmed.prefix(maxDigits))
    }

    static func value(fromDigits digits: String, fractionDigits: Int = 2) -> Double {
        (Double(digits) ?? 0) / pow(10, Double(fractionDigits))
    }

    static func digits(from value: Double, fractionDigits: Int = 2) -> String {
        guard value > 0 else { return "" }
        return String(Int((value * pow(10, Double(fractionDigits))).rounded()))
    }

    /// "12345" → "123,45" (ou "123.45" em inglês). Vazio fica vazio, para o
    /// texto de exemplo aparecer.
    static func display(digits: String, fractionDigits: Int = 2, locale: Locale = L.current) -> String {
        guard !digits.isEmpty else { return "" }
        return value(fromDigits: digits, fractionDigits: fractionDigits)
            .formatted(.number.precision(.fractionLength(fractionDigits)).locale(locale))
    }
}

struct CurrencyField: UIViewRepresentable {

    let placeholder: String
    @Binding var value: Double
    var textStyle: UIFont.TextStyle = .body
    var weight: UIFont.Weight = .regular
    var alignment: NSTextAlignment = .right
    var autoFocus = false
    /// 2 para dinheiro; 4 para cotações (5,3412).
    var fractionDigits = 2

    init(
        _ placeholder: String = "0,00",
        value: Binding<Double>,
        textStyle: UIFont.TextStyle = .body,
        weight: UIFont.Weight = .regular,
        alignment: NSTextAlignment = .right,
        autoFocus: Bool = false,
        fractionDigits: Int = 2
    ) {
        self.fractionDigits = fractionDigits
        self.placeholder = placeholder
        self._value = value
        self.textStyle = textStyle
        self.weight = weight
        self.alignment = alignment
        self.autoFocus = autoFocus
    }

    /// Para valores opcionais: zero vira `nil` (campo vazio).
    init(
        _ placeholder: String = "0,00",
        optional value: Binding<Double?>,
        textStyle: UIFont.TextStyle = .body,
        weight: UIFont.Weight = .regular,
        alignment: NSTextAlignment = .right,
        autoFocus: Bool = false,
        fractionDigits: Int = 2
    ) {
        self.init(
            placeholder,
            value: Binding(
                get: { value.wrappedValue ?? 0 },
                set: { value.wrappedValue = $0 > 0 ? $0 : nil }
            ),
            textStyle: textStyle, weight: weight, alignment: alignment, autoFocus: autoFocus,
            fractionDigits: fractionDigits
        )
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.keyboardType = .numberPad
        field.delegate = context.coordinator
        field.textAlignment = alignment
        field.adjustsFontForContentSizeCategory = true
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.inputAccessoryView = context.coordinator.makeToolbar(for: field)
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        if autoFocus {
            DispatchQueue.main.async { field.becomeFirstResponder() }
        }
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.parent = self
        field.font = UIFont.monospacedDigitSystemFont(
            ofSize: UIFont.preferredFont(forTextStyle: textStyle).pointSize, weight: weight
        )
        field.placeholder = placeholder
        field.textAlignment = alignment
        field.textColor = .label

        // Só reescreve o texto quando o valor mudou por fora, para não
        // atrapalhar a digitação.
        let current = CurrencyMask.value(fromDigits: context.coordinator.digits, fractionDigits: fractionDigits)
        if abs(current - value) > pow(10, -Double(fractionDigits)) / 2 {
            context.coordinator.digits = CurrencyMask.digits(from: value, fractionDigits: fractionDigits)
        }
        let shown = CurrencyMask.display(digits: context.coordinator.digits, fractionDigits: fractionDigits)
        if field.text != shown { field.text = shown }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CurrencyField
        var digits: String

        init(_ parent: CurrencyField) {
            self.parent = parent
            self.digits = CurrencyMask.digits(from: parent.value, fractionDigits: parent.fractionDigits)
        }

        func makeToolbar(for field: UITextField) -> UIToolbar {
            let bar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
            let done = UIBarButtonItem(
                title: L.t("OK"), style: .done, target: self, action: #selector(dismiss)
            )
            bar.items = [UIBarButtonItem(systemItem: .flexibleSpace), done]
            bar.sizeToFit()
            return bar
        }

        @objc func dismiss() {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
            )
        }

        /// Cada toque no teclado vira só dígitos, e o texto é refeito com a máscara.
        @objc func changed(_ field: UITextField) {
            digits = CurrencyMask.digits(from: field.text ?? "")
            field.text = CurrencyMask.display(digits: digits, fractionDigits: parent.fractionDigits)
            parent.value = CurrencyMask.value(fromDigits: digits, fractionDigits: parent.fractionDigits)
        }
    }
}
