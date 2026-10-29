import Foundation

/// Como o ícone de uma assinatura deve ser desenhado.
///
/// Guardado em `Subscription.iconRaw` (texto) para que a mesma informação
/// seja lida pelo app e pela extensão de widget.
enum SubscriptionIcon: Hashable {

    /// Logo de marca empacotado no app (ver `BrandIconCatalog`).
    case brand(String)
    /// SF Symbol.
    case symbol(String)
    /// Imagem baixada a partir de um endereço informado pelo usuário.
    case remote(URL)

    // MARK: - Persistência

    private enum Prefix {
        static let brand = "brand:"
        static let symbol = "sf:"
        static let remote = "url:"
    }

    var rawValue: String {
        switch self {
        case .brand(let id):    Prefix.brand + id
        case .symbol(let name): Prefix.symbol + name
        case .remote(let url):  Prefix.remote + url.absoluteString
        }
    }

    init?(rawValue: String) {
        if rawValue.hasPrefix(Prefix.brand) {
            let id = String(rawValue.dropFirst(Prefix.brand.count))
            guard !id.isEmpty else { return nil }
            self = .brand(id)
        } else if rawValue.hasPrefix(Prefix.symbol) {
            let name = String(rawValue.dropFirst(Prefix.symbol.count))
            guard !name.isEmpty else { return nil }
            self = .symbol(name)
        } else if rawValue.hasPrefix(Prefix.remote),
                  let url = URL(string: String(rawValue.dropFirst(Prefix.remote.count))) {
            self = .remote(url)
        } else {
            return nil
        }
    }

    // MARK: - Conveniência

    var brandID: String? {
        if case .brand(let id) = self { return id }
        return nil
    }

    var remoteURL: URL? {
        if case .remote(let url) = self { return url }
        return nil
    }

    /// Nome amigável para exibir na interface.
    var displayName: String {
        switch self {
        case .brand(let id):
            BrandIconCatalog.icon(id: id)?.name ?? id.capitalized
        case .symbol:
            L.t("icon.category")
        case .remote(let url):
            url.host() ?? url.absoluteString
        }
    }
}
