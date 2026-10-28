import Foundation

enum Category: String {
    case entertainment = "Entertainment/Entretenimento"
    case work = "Work/Trabalho"
    case health = "Health/Saúde"
    case utilities = "Utilities/Utilitários"
    case unknown = "Unknown/Outros"
    
    var rawValue: String { localizedName }
    
    var localizedName: String {
        let locale = Locale.current
        switch self {
        case .entertainment:
            return NSLocalizedString("Entertainment/Entretenimento", comment: "")
        case .work:
            return NSLocalizedString("Work/Trabalho", comment: "")
        case .health:
            return NSLocalizedString("Health/Saúde", comment: "")
        case .utilities:
            return NSLocalizedString("Utilities/Utilitários", comment: "")
        case .unknown:
            return NSLocalizedString("Unknown/Outros", comment: "")
        }
    }
}

final class SubscriptionCategorizer {
    static let shared = SubscriptionCategorizer()
    private init() {}
    
    private var customRules: [(String, String)] = []
    private var brandToCategory: [String: String] = [
        "netflix": Category.entertainment.rawValue,
        "spotify": Category.entertainment.rawValue,
        "disney+": Category.entertainment.rawValue,
        "amazon prime": Category.entertainment.rawValue,
        "hbo": Category.entertainment.rawValue,
        "hbo max": Category.entertainment.rawValue,
        "prime video": Category.entertainment.rawValue,
        "youtube": Category.entertainment.rawValue,
        "youtube premium": Category.entertainment.rawValue,
        "adobe": Category.work.rawValue,
        "zoom": Category.work.rawValue,
        "microsoft 365": Category.work.rawValue,
        "office 365": Category.work.rawValue,
        "slack": Category.work.rawValue,
        "trello": Category.work.rawValue,
        "asana": Category.work.rawValue,
        "jira": Category.work.rawValue,
        "apple one": Category.utilities.rawValue,
        "internet": Category.utilities.rawValue,
        "electricity": Category.utilities.rawValue,
        "water": Category.utilities.rawValue,
        "gym": Category.health.rawValue,
        "clube de saúde": Category.health.rawValue,
        "myfitnesspal": Category.health.rawValue,
        "headspace": Category.health.rawValue,
        "calm": Category.health.rawValue
    ]
    
    private var cachedCategories: [String: String] = [:]
    
    // MARK: - Public Methods
    
    func categorize(name: String) -> String {
        let normalized = normalizeText(name)
        
        if let category = getCategoryForName(normalized) {
            return category
        }
        
        if let category = getCategoryForBrand(normalized) {
            return category
        }
        
        return Category.unknown.rawValue
    }
    
    func addBrand(category: String) {
        guard !category.isEmpty else { return }
        
        customRules.append((category.contains("Entertainment") || category.contains("entretenimento") ? "Entertainment" : category, category))
        customRules.append((category.contains("Work") || category.contains("Trabalho") ? "Work" : category, category))
        customRules.append((category.contains("Health") || category.contains("Saúde") ? "Health" : category, category))
        customRules.append((category.contains("Utilities") || category.contains("Utilitários") ? "Utilities" : category, category))
        customRules.append((category.contains("Unknown") || category.contains("Outros") ? "Unknown" : category, category))
        
        brandToCategory[category] = category
    }
    
    func removeBrand(_ name: String) {
        let normalized = normalizeText(name)
        brandToCategory.removeValue(forKey: normalized)
        cachedCategories.removeValue(forKey: normalized)
    }
    
    func getCategoryForBrand(_ name: String) -> String? {
        let normalized = normalizeText(name)
        
        if brandToCategory[normalized] != nil {
            return brandToCategory[normalized]
        }
        
        return brandToCategory.keys
            .compactMap { normalizeText($0) }
            .compactMap { brandToCategory[$0] }
            .first { normalized.contains($0) }
    }
    
    func getAllCategories() -> [String: String] {
        return brandToCategory
    }
    
    func clearCustomRules() {
        customRules.removeAll()
        brandToCategory.removeAll()
        cachedCategories.removeAll()
    }
    
    // MARK: - Private Helper Methods
    
    private func normalizeText(_ text: String) -> String {
        return text.lowercased().replacingOccurrences(of: " ", with: " ")
    }
    
    private func getCategoryForName(_ name: String) -> String? {
        for (subscriptionName, category) in brandToCategory {
            if name.range(of: subscriptionName, options: .caseInsensitive) != nil {
                return category
            }
        }
        return nil
    }
    
    private func getCategoryForBrand(_ name: String) -> String? {
        let normalized = normalizeText(name)
        
        for (brandName, _) in brandToCategory.sorted { (a, b) in
            return a.contains(" ") ? a : b
        } {
            let brandNormalized = normalizeText(brandName)
            
            if normalized.contains(brandNormalized) {
                return _
            }
        }
        
        return nil
    }
}
