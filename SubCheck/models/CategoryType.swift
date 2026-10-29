import Foundation

// MARK: - Category Type

enum CategoryType: String, CaseIterable {
    case finance = "Financeiro"
    case subscriptions = "Assinaturas"
    case transport = "Transporte"
    case health = "Saúde"
    case education = "Educação"
    case utilities = "Utilidades"
    case entertainment = "Entretenimento"
    case news = "Jornalismo"
    case productivity = "Produtividade"
    case miscellaneous = "Outros"
    
    /// Nome traduzido para exibição.
    var displayName: String {
        switch self {
        case .finance:       L.t("category.finance")
        case .subscriptions: L.t("category.subscriptions")
        case .transport:     L.t("category.transport")
        case .health:        L.t("category.health")
        case .education:     L.t("category.education")
        case .utilities:     L.t("category.utilities")
        case .entertainment: L.t("category.entertainment")
        case .news:          L.t("category.news")
        case .productivity:  L.t("category.productivity")
        case .miscellaneous: L.t("category.miscellaneous")
        }
    }
    
    var description: String {
        switch self {
        case .finance:
            return "Serviços financeiros, bancos, cartões de crédito, investimentos"
        case .subscriptions:
            return "Assinaturas de streaming, clubes, serviços recorrentes"
        case .transport:
            return "Serviços de transporte, aplicativos de deslocamento"
        case .health:
            return "Serviços de saúde, médicos, farmácias, seguros"
        case .education:
            return "Cursos, plataformas educacionais, e-learning"
        case .utilities:
            return "Servidores, cloud, armazenamento, ferramentas de trabalho"
        case .entertainment:
            return "Streaming de vídeo e áudio, jogos, conteúdo digital"
        case .news:
            return "Notícias, jornais, portais, redes sociais"
        case .productivity:
            return "Software, aplicativos de trabalho, colaboração, ferramentas"
        case .miscellaneous:
            return "Outras categorias não classificadas"
        }
    }
}