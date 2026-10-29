import Foundation

/// Uma marca conhecida que já vem com o app.
struct BrandIcon: Identifiable, Hashable {

    /// Identificador estável (também usado como chave de persistência).
    let id: String
    /// Nome exibido na interface.
    let name: String
    /// Cor da marca em hexadecimal (`RRGGBB`). `nil` usa a cor da categoria.
    let hex: String?
    /// Nome do imageset empacotado em `BrandIcons.xcassets`. `nil` quando só
    /// existe um SF Symbol disponível.
    let asset: String?
    /// SF Symbol usado quando não há logo empacotado.
    let symbol: String
    /// Palavras-chave extras (minúsculas) para detectar o serviço pelo nome.
    let aliases: [String]

    /// Ícone persistível correspondente.
    var icon: SubscriptionIcon { .brand(id) }

    /// `true` quando existe um logo empacotado para esta marca.
    var hasLogo: Bool { asset != nil }

    fileprivate static func logo(
        _ id: String,
        _ name: String,
        _ hex: String,
        symbol: String,
        aliases: [String] = []
    ) -> BrandIcon {
        BrandIcon(id: id, name: name, hex: hex, asset: id, symbol: symbol, aliases: aliases)
    }

    fileprivate static func glyph(
        _ id: String,
        _ name: String,
        symbol: String,
        aliases: [String] = []
    ) -> BrandIcon {
        BrandIcon(id: id, name: name, hex: nil, asset: nil, symbol: symbol, aliases: aliases)
    }
}

/// Catálogo de marcas e ícones genéricos usados para sugerir um ícone a partir
/// do nome da assinatura. A ordem importa: marcas mais específicas vêm antes
/// das genéricas (ex.: `applemusic` antes de `apple`).
enum BrandIconCatalog {

    static let all: [BrandIcon] = [

        // MARK: - Apple
        .logo("applemusic", "Apple Music", "FA243C", symbol: "music.note",
              aliases: ["apple music"]),
        .logo("appletv", "Apple TV+", "000000", symbol: "play.tv.fill",
              aliases: ["apple tv", "apple tv plus", "tv+"]),
        .logo("applepay", "Apple Pay", "000000", symbol: "creditcard.fill",
              aliases: ["apple pay"]),
        .logo("icloud", "iCloud+", "3693F3", symbol: "icloud.fill",
              aliases: ["icloud", "icloud plus"]),
        .logo("apple", "Apple", "000000", symbol: "apple.logo",
              aliases: ["apple one", "applecare"]),

        // MARK: - Google
        .logo("youtubemusic", "YouTube Music", "FF0000", symbol: "music.note",
              aliases: ["youtube music", "yt music"]),
        .logo("youtube", "YouTube", "FF0000", symbol: "play.rectangle.fill"),
        .logo("googlechrome", "Google Chrome", "4285F4", symbol: "globe",
              aliases: ["chrome", "google chrome"]),
        .logo("googlecalendar", "Google Calendar", "4285F4", symbol: "calendar",
              aliases: ["google calendar"]),
        .logo("googledrive", "Google Drive", "4285F4", symbol: "folder.fill",
              aliases: ["google drive"]),
        .logo("googlephotos", "Google Photos", "4285F4", symbol: "photo.on.rectangle",
              aliases: ["google photos"]),
        .logo("googlegemini", "Gemini", "8E75B2", symbol: "sparkles",
              aliases: ["gemini", "google gemini"]),
        .logo("google", "Google One", "4285F4", symbol: "g.circle.fill",
              aliases: ["google one", "google workspace"]),

        // MARK: - Streaming e música
        .logo("netflix", "Netflix", "E50914", symbol: "play.tv.fill"),
        .logo("spotify", "Spotify", "1ED760", symbol: "music.note"),
        .logo("hbo", "HBO Max", "000000", symbol: "play.tv.fill",
              aliases: ["hbo max", "hbo"]),
        .logo("max", "Max", "525252", symbol: "play.tv.fill"),
        .logo("crunchyroll", "Crunchyroll", "FF5E00", symbol: "play.tv.fill"),
        .logo("deezer", "Deezer", "A238FF", symbol: "music.note"),
        .logo("tidal", "Tidal", "000000", symbol: "music.note"),
        .logo("soundcloud", "SoundCloud", "FF5500", symbol: "waveform",
              aliases: ["sound cloud"]),
        .logo("twitch", "Twitch", "9146FF", symbol: "video.fill"),
        .logo("paramountplus", "Paramount+", "0064FF", symbol: "mountain.2.fill",
              aliases: ["paramount", "paramount plus"]),
        .logo("audible", "Audible", "F8991C", symbol: "headphones"),
        .glyph("disneyplus", "Disney+", symbol: "sparkles",
               aliases: ["disney plus", "disney"]),
        .glyph("primevideo", "Prime Video", symbol: "play.rectangle.fill",
               aliases: ["amazon prime", "amazon prime video", "prime video"]),
        .glyph("globoplay", "Globoplay", symbol: "play.tv.fill",
               aliases: ["globo play"]),
        .glyph("hulu", "Hulu", symbol: "play.tv.fill"),

        // MARK: - IA
        .logo("trae", "Trae", "32F08C", symbol: "sparkles",
              aliases: ["trae", "trae ai"]),
        .logo("claude", "Claude", "D97757", symbol: "sparkles",
              aliases: ["claude", "claude ai"]),
        .logo("anthropic", "Anthropic", "191919", symbol: "sparkles"),
        .logo("perplexity", "Perplexity", "1FB8CD", symbol: "magnifyingglass",
              aliases: ["perplexity", "perplexity ai"]),
        .logo("huggingface", "Hugging Face", "FFD21E", symbol: "face.smiling",
              aliases: ["hugging face", "huggingface"]),
        .logo("cursor", "Cursor", "000000", symbol: "cursorarrow.rays",
              aliases: ["cursor", "cursor ai"]),
        .logo("githubcopilot", "GitHub Copilot", "000000", symbol: "chevron.left.forwardslash.chevron.right",
              aliases: ["copilot", "github copilot"]),
        .logo("ollama", "Ollama", "000000", symbol: "terminal.fill"),
        .logo("deepseek", "DeepSeek", "5786FE", symbol: "sparkles",
              aliases: ["deep seek", "deepseek"]),
        .logo("qwen", "Qwen", "6950EF", symbol: "sparkles"),
        .logo("windsurf", "Windsurf", "0B100F", symbol: "wind",
              aliases: ["windsurf", "codeium"]),
        .logo("elevenlabs", "ElevenLabs", "000000", symbol: "waveform",
              aliases: ["eleven labs", "elevenlabs"]),
        .logo("suno", "Suno", "000000", symbol: "music.note",
              aliases: ["suno", "suno ai"]),
        .logo("meta", "Meta AI", "0467DF", symbol: "infinity",
              aliases: ["meta ai", "llama"]),
        .logo("raycast", "Raycast", "FF6363", symbol: "command"),
        .glyph("chatgpt", "ChatGPT", symbol: "sparkles",
               aliases: ["chatgpt", "chat gpt", "openai", "gpt"]),
        .glyph("midjourney", "Midjourney", symbol: "photo.artframe"),

        // MARK: - Produtividade e software
        .logo("notion", "Notion", "000000", symbol: "doc.text.fill"),
        .logo("figma", "Figma", "F24E1E", symbol: "paintpalette.fill"),
        .logo("github", "GitHub", "181717", symbol: "chevron.left.forwardslash.chevron.right"),
        .logo("dropbox", "Dropbox", "0061FF", symbol: "shippingbox.fill"),
        .logo("linear", "Linear", "5E6AD2", symbol: "chart.line.uptrend.xyaxis"),
        .logo("arc", "Arc", "FCBFBD", symbol: "globe",
              aliases: ["arc browser"]),
        .logo("brave", "Brave", "FB542B", symbol: "shield.fill",
              aliases: ["brave browser"]),
        .logo("zoom", "Zoom", "0B5CFF", symbol: "video.fill"),
        .glyph("slack", "Slack", symbol: "number.square.fill"),
        .glyph("adobecc", "Adobe Creative Cloud", symbol: "photo.on.rectangle.angled",
               aliases: ["creative cloud", "adobe", "photoshop", "lightroom"]),
        .glyph("canva", "Canva", symbol: "paintpalette.fill"),

        // MARK: - Segurança e utilidades
        .logo("1password", "1Password", "145FE4", symbol: "lock.fill",
              aliases: ["1password", "one password"]),
        .logo("nordvpn", "NordVPN", "4687FF", symbol: "lock.shield.fill",
              aliases: ["nord vpn", "nordvpn"]),
        .logo("bitwarden", "Bitwarden", "175DDC", symbol: "lock.fill"),
        .logo("dashlane", "Dashlane", "0E353D", symbol: "lock.fill"),
        .logo("expressvpn", "ExpressVPN", "DA3940", symbol: "lock.shield.fill",
              aliases: ["express vpn"]),
        .logo("surfshark", "Surfshark", "1EBFBF", symbol: "lock.shield.fill"),

        // MARK: - Educação
        .logo("duolingo", "Duolingo", "58CC02", symbol: "graduationcap.fill"),
        .logo("udemy", "Udemy", "A435F0", symbol: "graduationcap.fill"),
        .logo("coursera", "Coursera", "0056D2", symbol: "graduationcap.fill"),

        // MARK: - Jogos
        .logo("playstation", "PlayStation", "0070D1", symbol: "gamecontroller.fill",
              aliases: ["playstation", "ps plus", "psn"]),
        .logo("steam", "Steam", "000000", symbol: "gamecontroller.fill"),
        .logo("epicgames", "Epic Games", "313131", symbol: "gamecontroller.fill",
              aliases: ["epic games", "epic"]),
        .glyph("xbox", "Xbox", symbol: "gamecontroller.fill",
               aliases: ["xbox", "game pass"]),

        // MARK: - Compras, transporte e finanças
        .logo("uber", "Uber", "000000", symbol: "car.fill",
              aliases: ["uber", "uber eats", "uber one"]),
        .logo("ifood", "iFood", "EA1D2C", symbol: "fork.knife",
              aliases: ["ifood", "i food"]),
        .logo("shopee", "Shopee", "EE4D2D", symbol: "bag.fill"),
        .logo("aliexpress", "AliExpress", "FF4747", symbol: "bag.fill",
              aliases: ["aliexpress", "ali express"]),
        .logo("waze", "Waze", "33CCFF", symbol: "location.fill"),
        .logo("nubank", "Nubank", "820AD1", symbol: "creditcard.fill",
              aliases: ["nubank", "nu bank"]),
        .logo("picpay", "PicPay", "21C25E", symbol: "creditcard.fill",
              aliases: ["picpay", "pic pay"]),

        // MARK: - Redes sociais e comunicação
        .logo("whatsapp", "WhatsApp", "25D366", symbol: "message.fill",
              aliases: ["whatsapp", "whats app"]),
        .logo("telegram", "Telegram", "26A5E4", symbol: "paperplane.fill"),
        .logo("instagram", "Instagram", "FF0069", symbol: "camera.fill",
              aliases: ["instagram", "insta"]),
        .logo("facebook", "Facebook", "0866FF", symbol: "person.2.fill"),
        .logo("x", "X (Twitter)", "000000", symbol: "xmark",
              aliases: ["twitter", "twitter blue", "x premium", "twitter premium"]),
        .logo("tiktok", "TikTok", "000000", symbol: "music.note",
              aliases: ["tiktok", "tik tok"]),
        .logo("pinterest", "Pinterest", "BD081C", symbol: "pin.fill"),
        .logo("reddit", "Reddit", "FF4500", symbol: "bubble.left.and.bubble.right.fill"),
        .logo("discord", "Discord", "5865F2", symbol: "gamecontroller.fill",
              aliases: ["discord", "discord nitro"]),
        .logo("threads", "Threads", "000000", symbol: "at"),
        .logo("bluesky", "Bluesky", "1185FE", symbol: "cloud.fill",
              aliases: ["bluesky", "blue sky"]),
        .logo("snapchat", "Snapchat", "FFFC00", symbol: "camera.fill",
              aliases: ["snapchat", "snap chat"]),

        // MARK: - Saúde, notícias e conteúdo
        .logo("strava", "Strava", "FC4C02", symbol: "figure.run"),
        .logo("headspace", "Headspace", "F47D31", symbol: "brain.head.profile"),
        .logo("medium", "Medium", "000000", symbol: "text.alignleft"),
        .logo("substack", "Substack", "FF6719", symbol: "envelope.fill"),
        .glyph("microsoft365", "Microsoft 365", symbol: "square.grid.2x2.fill",
               aliases: ["microsoft", "office 365", "microsoft 365"]),
        .glyph("nytimes", "The New York Times", symbol: "newspaper.fill",
               aliases: ["new york times", "ny times", "nytimes"])
    ]

    // MARK: - Índice

    private static let index: [String: BrandIcon] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    /// Busca um ícone pelo identificador salvo na assinatura.
    static func icon(id: String) -> BrandIcon? { index[id] }

    // MARK: - Detecção automática

    /// Marca correspondente ao nome informado, ou `nil` se nenhuma casar.
    static func match(name: String) -> BrandIcon? {
        let needle = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return nil }

        let tokens = Set(
            needle.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
        )

        for brand in all {
            if tokens.contains(brand.id) { return brand }

            let matchedAlias = brand.aliases.contains { alias in
                alias.contains(" ") ? needle.contains(alias) : tokens.contains(alias)
            }
            if matchedAlias { return brand }

            let brandName = brand.name.lowercased()
            if brandName.contains(" ") ? needle.contains(brandName) : tokens.contains(brandName) {
                return brand
            }
        }
        return nil
    }

    /// Filtra o catálogo para a busca do seletor de ícones.
    static func search(_ query: String) -> [BrandIcon] {
        let needle = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return all }

        return all.filter { brand in
            brand.name.lowercased().contains(needle)
                || brand.id.contains(needle)
                || brand.aliases.contains { $0.contains(needle) }
        }
    }
}
