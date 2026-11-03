//
//  AppLinks.swift
//  SubCheck
//
//  Endereços públicos exigidos pela App Store. Servidos pelo GitHub Pages a
//  partir da pasta `docs/` deste repositório. Publique a pasta (Settings >
//  Pages > Branch: main /docs) para que os links funcionem.
//

import Foundation

enum AppLinks {
    /// Páginas publicadas no GitHub Pages (pasta `docs/`).
    private static let base = "https://viniciusmicarelli.github.io/sub-check"

    /// Política de privacidade (obrigatória no App Store Connect).
    static let privacyPolicy: URL? = URL(string: "\(base)/privacy.html")
    /// Termos de uso (recomendado para apps com compra dentro do app).
    static let termsOfUse: URL? = URL(string: "\(base)/terms.html")
    /// Página de suporte (obrigatória no App Store Connect).
    static let support: URL? = URL(string: "\(base)/support.html")
}
