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

    /// Marca sem logo livre: círculo na cor da marca com um SF Symbol.
    fileprivate static func tile(
        _ id: String,
        _ name: String,
        _ hex: String,
        symbol: String,
        aliases: [String] = []
    ) -> BrandIcon {
        BrandIcon(id: id, name: name, hex: hex, asset: nil, symbol: symbol, aliases: aliases)
    }

    /// Usa o logo de outra marca (ex.: Apple One com o logo da Apple).
    fileprivate static func shared(
        _ id: String,
        _ name: String,
        _ hex: String,
        asset: String,
        symbol: String,
        aliases: [String] = []
    ) -> BrandIcon {
        BrandIcon(id: id, name: name, hex: hex, asset: asset, symbol: symbol, aliases: aliases)
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

        // Mais da Apple e da Microsoft/Google (antes das marcas genéricas)
        .shared("appleone", "Apple One", "FA243C", asset: "apple", symbol: "apple.logo",
              aliases: ["apple one"]),
        .shared("appledeveloper", "Apple Developer", "0D96F6", asset: "apple", symbol: "hammer.fill",
              aliases: ["apple developer", "developer program", "apple dev"]),
        .logo("applearcade", "Apple Arcade", "000000", symbol: "gamecontroller.fill",
              aliases: ["apple arcade"]),
        .logo("applepodcasts", "Apple Podcasts", "9933CC", symbol: "mic.fill",
              aliases: ["apple podcasts"]),
        .logo("applenews", "Apple News+", "FD415E", symbol: "newspaper.fill",
              aliases: ["apple news", "news+"]),
        .logo("appstore", "App Store", "0D96F6", symbol: "a.circle.fill",
              aliases: ["app store"]),
        .tile("applefitness", "Apple Fitness+", "FA243C", symbol: "figure.run",
              aliases: ["apple fitness", "fitness+"]),
        .tile("applebooks", "Apple Books", "FF9500", symbol: "books.vertical.fill",
              aliases: ["apple books"]),
        .tile("testflight", "TestFlight", "0D96F6", symbol: "paperplane.fill",
              aliases: ["testflight"]),
        .tile("onedrive", "OneDrive", "0078D4", symbol: "cloud.fill",
              aliases: ["onedrive", "one drive"]),
        .tile("googleone", "Google One", "4285F4", symbol: "cloud.fill",
              aliases: ["google one"]),
        .tile("outlook", "Outlook", "0078D4", symbol: "envelope.fill",
              aliases: ["outlook"]),
        .tile("teams", "Microsoft Teams", "6264A7", symbol: "person.2.fill",
              aliases: ["teams", "microsoft teams"]),
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
               aliases: ["new york times", "ny times", "nytimes"]),

        // MARK: - Mais marcas — IA
        .logo("openai", "OpenAI", "412991", symbol: "sparkles",
              aliases: ["openai", "openai api", "sora", "gpt"]),
        .tile("grok", "Grok (xAI)", "000000", symbol: "sparkle",
              aliases: ["grok", "xai", "x premium", "x.ai"]),
        .tile("mistral", "Mistral AI", "FA520F", symbol: "wind",
              aliases: ["mistral", "le chat", "mistral ai"]),
        .tile("copilot", "Microsoft Copilot", "0F6CBD", symbol: "sparkles",
              aliases: ["copilot", "microsoft copilot"]),
        .tile("lovable", "Lovable", "FF4D6D", symbol: "heart.fill",
              aliases: ["lovable"]),
        .logo("replit", "Replit", "F26207", symbol: "chevron.left.forwardslash.chevron.right",
              aliases: ["replit"]),
        .logo("vercel", "Vercel", "000000", symbol: "triangle.fill",
              aliases: ["vercel", "v0", "v0.dev"]),
        .logo("poe", "Poe", "5D5CDE", symbol: "bubble.left.fill",
              aliases: ["poe"]),
        .tile("runway", "Runway", "000000", symbol: "film.fill",
              aliases: ["runway", "runwayml"]),
        .tile("leonardoai", "Leonardo.Ai", "6D28D9", symbol: "paintbrush.fill",
              aliases: ["leonardo", "leonardo ai"]),
        .tile("ideogram", "Ideogram", "F97316", symbol: "textformat",
              aliases: ["ideogram"]),
        .tile("kling", "Kling AI", "1D4ED8", symbol: "video.fill",
              aliases: ["kling"]),
        .tile("notebooklm", "NotebookLM", "1A73E8", symbol: "book.fill",
              aliases: ["notebooklm", "notebook lm"]),

        // MARK: - Mais marcas — Criação
        .tile("dazzcam", "Dazz Cam", "E11D48", symbol: "camera.fill",
              aliases: ["dazz", "dazz cam", "dazzcam"]),
        .tile("capcut", "CapCut", "000000", symbol: "scissors",
              aliases: ["capcut", "cap cut"]),
        .logo("vsco", "VSCO", "000000", symbol: "camera.filters",
              aliases: ["vsco"]),
        .logo("lightroom", "Adobe Lightroom", "31A8FF", symbol: "camera.aperture",
              aliases: ["lightroom", "adobe lightroom"]),
        .logo("photoshop", "Adobe Photoshop", "31A8FF", symbol: "photo.fill",
              aliases: ["photoshop", "adobe photoshop"]),
        .logo("sketch", "Sketch", "F7B500", symbol: "pencil.and.ruler.fill",
              aliases: ["sketch"]),
        .logo("framer", "Framer", "0055FF", symbol: "square.on.square",
              aliases: ["framer"]),
        .logo("webflow", "Webflow", "146EF5", symbol: "globe",
              aliases: ["webflow"]),
        .tile("facetune", "Facetune", "00B2FF", symbol: "face.smiling.fill",
              aliases: ["facetune"]),
        .tile("snapseed", "Snapseed", "23A455", symbol: "leaf.fill",
              aliases: ["snapseed"]),
        .tile("picsart", "Picsart", "C209C1", symbol: "paintpalette.fill",
              aliases: ["picsart"]),

        // MARK: - Mais marcas — Streaming
        .logo("plex", "Plex", "EBAF00", symbol: "play.rectangle.fill",
              aliases: ["plex"]),
        .logo("mubi", "MUBI", "000000", symbol: "film",
              aliases: ["mubi"]),
        .tile("starplus", "Star+", "5B2EFF", symbol: "star.fill",
              aliases: ["star+", "star plus", "starplus"]),
        .tile("telecine", "Telecine", "E50914", symbol: "film.stack.fill",
              aliases: ["telecine"]),
        .tile("peacock", "Peacock", "000000", symbol: "tv.fill",
              aliases: ["peacock"]),
        .logo("napster", "Napster", "2259FF", symbol: "headphones",
              aliases: ["napster"]),
        .logo("pandora", "Pandora", "224099", symbol: "music.note",
              aliases: ["pandora"]),
        .logo("vimeo", "Vimeo", "1AB7EA", symbol: "play.circle.fill",
              aliases: ["vimeo"]),
        .logo("patreon", "Patreon", "000000", symbol: "heart.circle.fill",
              aliases: ["patreon"]),
        .logo("kickstream", "Kick", "53FC19", symbol: "bolt.fill",
              aliases: ["kick", "kick.com"]),

        // MARK: - Mais marcas — Jogos
        .logo("nintendo", "Nintendo Switch", "E60012", symbol: "gamecontroller.fill",
              aliases: ["nintendo", "nintendo switch online", "switch online"]),
        .logo("roblox", "Roblox", "000000", symbol: "cube.fill",
              aliases: ["roblox", "robux"]),
        .logo("riotgames", "Riot Games", "EB0029", symbol: "shield.fill",
              aliases: ["riot", "riot games", "valorant", "league of legends", "lol"]),
        .logo("electronicarts", "EA Play", "000000", symbol: "gamecontroller",
              aliases: ["ea", "ea play", "ea sports", "electronic arts"]),
        .logo("battlenet", "Battle.net", "4381C3", symbol: "gamecontroller.fill",
              aliases: ["battle.net", "blizzard", "battlenet"]),
        .logo("nvidia", "GeForce NOW", "76B900", symbol: "display",
              aliases: ["nvidia", "geforce", "geforce now"]),
        .logo("ubisoft", "Ubisoft+", "000000", symbol: "gamecontroller.fill",
              aliases: ["ubisoft", "ubisoft+"]),
        .tile("gamepass", "Xbox Game Pass", "107C10", symbol: "gamecontroller.fill",
              aliases: ["game pass", "gamepass", "xbox game pass"]),
        .tile("minecraft", "Minecraft", "62B47A", symbol: "cube.fill",
              aliases: ["minecraft", "realms"]),
        .tile("fortnite", "Fortnite", "9D4DFF", symbol: "gamecontroller.fill",
              aliases: ["fortnite", "v-bucks", "vbucks"]),

        // MARK: - Mais marcas — Produtividade
        .logo("todoist", "Todoist", "E44332", symbol: "checkmark.circle.fill",
              aliases: ["todoist"]),
        .logo("evernote", "Evernote", "00A82D", symbol: "note.text",
              aliases: ["evernote"]),
        .logo("obsidian", "Obsidian", "7C3AED", symbol: "diamond.fill",
              aliases: ["obsidian"]),
        .logo("trello", "Trello", "0052CC", symbol: "rectangle.split.3x1.fill",
              aliases: ["trello"]),
        .logo("asana", "Asana", "F06A6A", symbol: "circle.grid.3x3.fill",
              aliases: ["asana"]),
        .logo("clickup", "ClickUp", "7B68EE", symbol: "checkmark.seal.fill",
              aliases: ["clickup"]),
        .logo("airtable", "Airtable", "18BFFF", symbol: "tablecells.fill",
              aliases: ["airtable"]),
        .logo("zapier", "Zapier", "FF4F00", symbol: "bolt.fill",
              aliases: ["zapier"]),
        .logo("grammarly", "Grammarly", "027E6F", symbol: "textformat.abc",
              aliases: ["grammarly"]),
        .logo("mega", "MEGA", "D9272E", symbol: "externaldrive.fill",
              aliases: ["mega", "mega.nz"]),
        .logo("proton", "Proton", "6D4AFF", symbol: "lock.shield.fill",
              aliases: ["proton", "proton mail", "protonmail", "proton vpn", "protonvpn"]),

        // MARK: - Mais marcas — Dev
        .logo("netlify", "Netlify", "00C7B7", symbol: "network",
              aliases: ["netlify"]),
        .logo("cloudflare", "Cloudflare", "F38020", symbol: "cloud.fill",
              aliases: ["cloudflare"]),
        .logo("digitalocean", "DigitalOcean", "0080FF", symbol: "drop.fill",
              aliases: ["digitalocean", "digital ocean"]),
        .logo("jetbrains", "JetBrains", "000000", symbol: "curlybraces",
              aliases: ["jetbrains", "intellij", "pycharm", "webstorm"]),
        .logo("postman", "Postman", "FF6C37", symbol: "paperplane.fill",
              aliases: ["postman"]),
        .logo("docker", "Docker", "2496ED", symbol: "shippingbox.fill",
              aliases: ["docker"]),
        .logo("godaddy", "GoDaddy", "1BDBDB", symbol: "globe",
              aliases: ["godaddy", "go daddy"]),
        .logo("namecheap", "Namecheap", "DE3723", symbol: "globe",
              aliases: ["namecheap"]),
        .tile("aws", "Amazon Web Services", "FF9900", symbol: "cloud.fill",
              aliases: ["aws", "amazon web services"]),

        // MARK: - Mais marcas — Saúde
        .logo("garmin", "Garmin", "000000", symbol: "applewatch",
              aliases: ["garmin", "garmin connect"]),
        .logo("fitbit", "Fitbit", "00B0B9", symbol: "heart.fill",
              aliases: ["fitbit"]),
        .logo("peloton", "Peloton", "181A1D", symbol: "figure.indoor.cycle",
              aliases: ["peloton"]),
        .logo("komoot", "Komoot", "6AA127", symbol: "map.fill",
              aliases: ["komoot"]),
        .logo("alltrails", "AllTrails", "142800", symbol: "figure.hiking",
              aliases: ["alltrails"]),
        .tile("smartfit", "Smart Fit", "FFCC00", symbol: "dumbbell.fill",
              aliases: ["smart fit", "smartfit", "bio ritmo", "bioritmo"]),
        .tile("wellhub", "Wellhub (Gympass)", "FF5A5F", symbol: "figure.strengthtraining.traditional",
              aliases: ["wellhub", "gympass"]),
        .tile("myfitnesspal", "MyFitnessPal", "0066EE", symbol: "fork.knife",
              aliases: ["myfitnesspal", "my fitness pal"]),
        .tile("calm", "Calm", "3D9BE9", symbol: "moon.stars.fill",
              aliases: ["calm"]),

        // MARK: - Mais marcas — Compras
        .logo("amazon", "Amazon", "FF9900", symbol: "shippingbox.fill",
              aliases: ["amazon", "amazon prime", "prime"]),
        .logo("mercadopago", "Mercado Pago", "00B1EA", symbol: "creditcard.fill",
              aliases: ["mercado pago"]),
        .tile("mercadolivre", "Mercado Livre", "FFE600", symbol: "cart.fill",
              aliases: ["mercado livre", "mercadolivre", "meli"]),
        .tile("magalu", "Magalu", "0086FF", symbol: "bag.fill",
              aliases: ["magalu", "magazine luiza"]),
        .tile("rappi", "Rappi", "FF441F", symbol: "bicycle",
              aliases: ["rappi", "rappi prime"]),
        .logo("ubereats", "Uber Eats", "06C167", symbol: "takeoutbag.and.cup.and.straw.fill",
              aliases: ["uber eats", "ubereats"]),
        .logo("doordash", "DoorDash", "FF3008", symbol: "takeoutbag.and.cup.and.straw.fill",
              aliases: ["doordash"]),
        .logo("deliveroo", "Deliveroo", "00CCBC", symbol: "bicycle",
              aliases: ["deliveroo"]),
        .logo("starbucks", "Starbucks", "006241", symbol: "cup.and.saucer.fill",
              aliases: ["starbucks"]),
        .logo("mcdonalds", "McDonald's", "FBC817", symbol: "fork.knife",
              aliases: ["mcdonalds", "mcdonald's", "mc donalds"]),

        // MARK: - Mais marcas — Transporte
        .tile("cabify", "Cabify", "7145D6", symbol: "car.fill",
              aliases: ["cabify"]),
        .tile("99", "99", "FFC800", symbol: "car.fill",
              aliases: ["99", "99pop", "99 taxi"]),
        .logo("lyft", "Lyft", "FF00BF", symbol: "car.fill",
              aliases: ["lyft"]),

        // MARK: - Mais marcas — Viagem
        .logo("airbnb", "Airbnb", "FF5A5F", symbol: "house.fill",
              aliases: ["airbnb"]),
        .logo("tripadvisor", "Tripadvisor", "34E0A1", symbol: "airplane",
              aliases: ["tripadvisor", "trip advisor"]),

        // MARK: - Mais marcas — Finanças
        .logo("paypal", "PayPal", "003087", symbol: "creditcard.fill",
              aliases: ["paypal"]),
        .logo("wise", "Wise", "9FE870", symbol: "arrow.left.arrow.right",
              aliases: ["wise", "transferwise"]),
        .logo("revolut", "Revolut", "191C1F", symbol: "creditcard.fill",
              aliases: ["revolut"]),
        .logo("binance", "Binance", "F0B90B", symbol: "bitcoinsign.circle.fill",
              aliases: ["binance"]),
        .logo("coinbase", "Coinbase", "0052FF", symbol: "bitcoinsign.circle.fill",
              aliases: ["coinbase"]),
        .tile("itau", "Itaú", "EC7000", symbol: "building.columns.fill",
              aliases: ["itau", "itaú"]),
        .tile("bradesco", "Bradesco", "CC092F", symbol: "building.columns.fill",
              aliases: ["bradesco"]),
        .tile("bancointer", "Banco Inter", "FF7A00", symbol: "building.columns.fill",
              aliases: ["inter", "banco inter"]),
        .tile("c6bank", "C6 Bank", "242424", symbol: "creditcard.fill",
              aliases: ["c6", "c6 bank"]),
        .tile("santander", "Santander", "EC0000", symbol: "building.columns.fill",
              aliases: ["santander"]),

        // MARK: - Mais marcas — Telecom
        .tile("vivo", "Vivo", "660099", symbol: "simcard.fill",
              aliases: ["vivo", "vivo fibra", "vivo easy"]),
        .tile("claro", "Claro", "E02020", symbol: "simcard.fill",
              aliases: ["claro", "claro tv", "net claro"]),
        .tile("timbrasil", "TIM", "0033A0", symbol: "simcard.fill",
              aliases: ["tim", "tim brasil"]),
        .tile("oi", "Oi", "FFD200", symbol: "simcard.fill",
              aliases: ["oi", "oi fibra"]),

        // MARK: - Mais marcas — Aprendizado
        .logo("skillshare", "Skillshare", "00FF84", symbol: "graduationcap.fill",
              aliases: ["skillshare"]),
        .logo("khanacademy", "Khan Academy", "14BF96", symbol: "graduationcap.fill",
              aliases: ["khan", "khan academy"]),
        .logo("codecademy", "Codecademy", "1F4056", symbol: "chevron.left.forwardslash.chevron.right",
              aliases: ["codecademy"]),
        .logo("datacamp", "DataCamp", "03EF62", symbol: "chart.bar.fill",
              aliases: ["datacamp"]),
        .logo("pluralsight", "Pluralsight", "F15B2A", symbol: "play.square.fill",
              aliases: ["pluralsight"]),
        .logo("leetcode", "LeetCode", "FFA116", symbol: "curlybraces",
              aliases: ["leetcode"]),
        .logo("scribd", "Scribd", "1E7B85", symbol: "book.fill",
              aliases: ["scribd", "everand"]),
        .logo("wattpad", "Wattpad", "FF500A", symbol: "book.closed.fill",
              aliases: ["wattpad"]),
        .tile("babbel", "Babbel", "FF6E3C", symbol: "character.bubble.fill",
              aliases: ["babbel"]),
        .tile("kindle", "Kindle Unlimited", "FF9900", symbol: "book.fill",
              aliases: ["kindle", "kindle unlimited"]),
        .tile("storytel", "Storytel", "FF5A00", symbol: "headphones",
              aliases: ["storytel"]),

        // MARK: - Mais marcas — Social
        .logo("tinder", "Tinder", "FF6B6B", symbol: "flame.fill",
              aliases: ["tinder"]),
        .tile("bumble", "Bumble", "FFC629", symbol: "hexagon.fill",
              aliases: ["bumble"]),
        .tile("hinge", "Hinge", "000000", symbol: "heart.fill",
              aliases: ["hinge"]),
        .logo("viber", "Viber", "7360F2", symbol: "phone.bubble.fill",
              aliases: ["viber"]),
        .tile("linkedin", "LinkedIn Premium", "0A66C2", symbol: "briefcase.fill",
              aliases: ["linkedin", "linkedin premium"])
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
