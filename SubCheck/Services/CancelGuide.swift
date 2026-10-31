//
//  CancelGuide.swift
//  SubCheck
//
//  Leva direto à página de cancelamento do serviço quando a marca é
//  conhecida; do contrário abre uma busca. Os endereços pertencem às
//  empresas e podem mudar, então a busca é sempre o plano B.
//

import Foundation

enum CancelGuide {

    /// Páginas de gerenciamento/cancelamento por id de marca do catálogo.
    private static let direct: [String: String] = [
        "netflix": "https://www.netflix.com/cancelplan",
        "spotify": "https://www.spotify.com/account/subscription/",
        "youtube": "https://www.youtube.com/paid_memberships",
        "youtubemusic": "https://www.youtube.com/paid_memberships",
        "crunchyroll": "https://www.crunchyroll.com/acct/membership",
        "github": "https://github.com/settings/billing",
        "githubcopilot": "https://github.com/settings/billing",
        "dropbox": "https://www.dropbox.com/account/plan",
        // Assinaturas compradas pela App Store ficam todas no mesmo lugar.
        "apple": "https://apps.apple.com/account/subscriptions",
        "applemusic": "https://apps.apple.com/account/subscriptions",
        "appletv": "https://apps.apple.com/account/subscriptions",
        "icloud": "https://apps.apple.com/account/subscriptions",
        // Google One, Gemini e afins são geridos no Google Play.
        "google": "https://play.google.com/store/account/subscriptions",
        "googledrive": "https://play.google.com/store/account/subscriptions",
        "googlephotos": "https://play.google.com/store/account/subscriptions",
        "googlegemini": "https://play.google.com/store/account/subscriptions"
    ]

    /// Página de cancelamento (conhecida) ou busca "como cancelar X".
    static func url(for subscription: Subscription) -> URL? {
        if let brand = BrandIconCatalog.match(name: subscription.name),
           let address = direct[brand.id],
           let url = URL(string: address) {
            return url
        }
        return searchURL(for: subscription.name)
    }

    /// `true` quando o link vai direto à página do serviço.
    static func isDirect(_ subscription: Subscription) -> Bool {
        guard let brand = BrandIconCatalog.match(name: subscription.name) else { return false }
        return direct[brand.id] != nil
    }

    private static func searchURL(for name: String) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: L.t("como cancelar assinatura %@", name))
        ]
        return components?.url
    }
}
