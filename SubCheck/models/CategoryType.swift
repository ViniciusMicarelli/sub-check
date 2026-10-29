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
    
    var displayName: String {
        switch self {
        case .finance:
            return "Financeiro"
        case .subscriptions:
            return "Assinaturas"
        case .transport:
            return "Transporte"
        case .health:
            return "Saúde"
        case .education:
            return "Educação"
        case .utilities:
            return "Utilidades"
        case .entertainment:
            return "Entretenimento"
        case .news:
            return "Jornalismo"
        case .productivity:
            return "Produtividade"
        case .miscellaneous:
            return "Outros"
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