import Foundation

struct DailySuggestionsResponse: Decodable {
    let suggestions: DailySuggestionsPayload
    let run: DailyRun?
}

enum DailySuggestionsPayload: Decodable {
    case list([DailySuggestion])
    case buckets([String: [DailySuggestion]])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let buckets = try? container.decode([String: [DailySuggestion]].self) {
            self = .buckets(buckets)
        } else if let list = try? container.decode([DailySuggestion].self) {
            self = .list(list)
        } else {
            self = .buckets([:])
        }
    }
}

struct DailySuggestion: Decodable, Identifiable {
    let id: String
    let userId: String?
    let recipeData: RecipeData
    let generatedAt: String?
    let expiresAt: String?
    let savedRecipeId: String?
    let runId: String?
    let triggerSource: String?
    let rank: Int?
}

struct DailyRun: Decodable {
    let id: String
    let status: String
    let triggerSource: String?
    let createdAt: String?
}

struct DailyRefreshResponse: Decodable {
    let suggestions: [String: [DailySuggestion]]
}

struct RecipeData: Decodable {
    let id: String
    let title: String
    let description: String?
    let servings: Int?
    let calories: Int?
    let prepTime: String?
    let cookTime: String?
    let prepTimeMinutes: Int?
    let cookTimeMinutes: Int?
    let tags: [String]?
    let cuisine: String?
    let dietaryLabels: [String]?
    let ingredients: [RecipeIngredient]?
    let steps: [RecipeStep]?
    let media: [RecipeMedia]?
    let metadata: RecipeMetadata?
}

struct RecipeMedia: Decodable {
    let url: URL?
    let isGenerated: Bool?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let urlString = try container.decodeIfPresent(String.self, forKey: .url)
        url = urlString.flatMap { URL(string: $0) }
        isGenerated = try container.decodeIfPresent(Bool.self, forKey: .isGenerated)
    }

    private enum CodingKeys: String, CodingKey {
        case url
        case isGenerated
    }
}

struct RecipeMetadata: Decodable {
    let mealType: String?
}

struct RecipeIngredient: Decodable {
    let name: String?
    let amount: String?
    let unit: String?
    let quantity: String?
    let rawText: String?
    let text: String?

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let textValue = try? single.decode(String.self) {
            name = nil
            amount = nil
            unit = nil
            quantity = nil
            rawText = textValue
            text = textValue
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        amount = RecipeIngredient.decodeFlexibleString(from: container, forKey: .amount)
        unit = try container.decodeIfPresent(String.self, forKey: .unit)
        quantity = RecipeIngredient.decodeFlexibleString(from: container, forKey: .quantity)
        rawText = try container.decodeIfPresent(String.self, forKey: .rawText)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? rawText
    }

    private static func decodeFlexibleString(
        from container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> String? {
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            return stringValue
        }
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: key) {
            return String(intValue)
        }
        if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: key) {
            return String(doubleValue)
        }
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case amount
        case unit
        case quantity
        case rawText
        case text
    }
}

struct RecipeStep: Decodable {
    let title: String?
    let detail: String?
    let text: String?
    let instruction: String?
    let order: Int?

    init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let textValue = try? single.decode(String.self) {
            title = nil
            detail = nil
            text = textValue
            instruction = nil
            order = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        detail = try container.decodeIfPresent(String.self, forKey: .detail)
        instruction = try container.decodeIfPresent(String.self, forKey: .instruction)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? instruction
        if let orderValue = try container.decodeIfPresent(Int.self, forKey: .order) {
            order = orderValue
        } else {
            order = try container.decodeIfPresent(Int.self, forKey: .stepNumber)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case detail = "description"
        case text
        case instruction
        case order
        case stepNumber
    }
}
