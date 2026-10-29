//
//  SubscriptionCategorizer.swift
//  SubCheck
//
//  Lightweight keyword based categorizer used to auto-detect a category
//  from the service name entered by the user.
//

import Foundation

enum SubscriptionCategorizer {

    /// Ordered so the most specific categories are matched first.
    private static let rules: [(CategoryType, [String])] = [
        (.entertainment, ["netflix", "spotify", "disney", "hbo", "max", "prime video",
                          "youtube", "apple music", "apple tv", "deezer", "globoplay",
                          "paramount", "crunchyroll", "twitch", "xbox", "playstation",
                          "steam", "game pass", "deezer"]),
        (.news, ["folha", "globo", "estadão", "estadao", "uol", "nytimes", "new york times",
                 "economist", "medium", "substack", "valor"]),
        (.productivity, ["notion", "slack", "figma", "adobe", "microsoft", "office", "365",
                         "github", "linear", "todoist", "evernote", "canva", "miro", "asana"]),
        (.utilities, ["icloud", "google one", "dropbox", "aws", "azure", "digitalocean",
                      "vercel", "heroku", "1password", "nordvpn", "expressvpn", "surfshark"]),
        (.health, ["gym", "academia", "smart fit", "unimed", "seguro", "plano de saude",
                   "farmacia", "farmácia", "wellhub", "gympass", "totalpass"]),
        (.education, ["coursera", "udemy", "alura", "duolingo", "skillshare", "udacity",
                      "platzi", "khan", "domestika"]),
        (.transport, ["uber", "99", "lyft", "sem parar", "veloe", "combustivel",
                      "combustível", "estacionamento", "posto"]),
        (.finance, ["nubank", "banco", "inter", "c6", "itau", "itaú", "bradesco",
                    "santander", "cartao", "cartão", "investimento", "picpay"]),
        (.subscriptions, ["assinatura", "clube", "subscription", "plano", "membership"])
    ]

    /// Returns the matched category, or `.miscellaneous` when nothing matches.
    static func categorize(name: String) -> CategoryType {
        let needle = name.lowercased()
        guard !needle.isEmpty else { return .miscellaneous }

        for (category, keywords) in rules
        where keywords.contains(where: { needle.contains($0) }) {
            return category
        }
        return .miscellaneous
    }

    /// Convenience returning the raw value stored on `Subscription.category`.
    static func categorizeRawValue(name: String) -> String {
        categorize(name: name).rawValue
    }
}
