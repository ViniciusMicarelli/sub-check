//
//  AppLinks.swift
//  SubCheck
//
//  Endereços públicos exigidos pela App Store. Preencha antes de publicar:
//  enquanto forem `nil`, os links ficam ocultos nas Ajustes em vez de abrir
//  uma página quebrada.
//

import Foundation

enum AppLinks {
    /// Política de privacidade (obrigatória no App Store Connect).
    static let privacyPolicy: URL? = nil
    /// Termos de uso (recomendado para apps com compra dentro do app).
    static let termsOfUse: URL? = nil
    /// Página de suporte (obrigatória no App Store Connect).
    static let support: URL? = nil
}
