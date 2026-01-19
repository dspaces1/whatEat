import Foundation

struct RecipeIngredientPayload: Encodable {
    let rawText: String

    private enum CodingKeys: String, CodingKey {
        case rawText = "raw_text"
    }
}

struct RecipeStepPayload: Encodable {
    let instruction: String
    let order: Int

    private enum CodingKeys: String, CodingKey {
        case instruction
        case order
    }
}

struct RecipeMediaPayload: Encodable {
    let mediaType: String
    let url: String
    let name: String?

    private enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case url
        case name
    }
}

struct RecipeMetadataPayload: Encodable {
    let mealType: String?

    private enum CodingKeys: String, CodingKey {
        case mealType = "meal_type"
    }
}

struct RecipeCreateRequest: Encodable {
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
    let ingredients: [RecipeIngredientPayload]
    let steps: [RecipeStepPayload]
    let media: [RecipeMediaPayload]?
    let metadata: RecipeMetadataPayload?

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case servings
        case calories
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case tags
        case cuisine
        case dietaryLabels = "dietary_labels"
        case ingredients
        case steps
        case media
        case metadata
    }
}

struct RecipeUpdateRequest: Encodable {
    let title: String?
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
    let ingredients: [RecipeIngredientPayload]?
    let steps: [RecipeStepPayload]?
    let media: [RecipeMediaPayload]?
    let metadata: RecipeMetadataPayload?

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case servings
        case calories
        case prepTime = "prep_time"
        case cookTime = "cook_time"
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case tags
        case cuisine
        case dietaryLabels = "dietary_labels"
        case ingredients
        case steps
        case media
        case metadata
    }
}

struct RecipeCreateResponse: Decodable {
    let id: String
    let title: String
    let createdAt: String?
}

struct RecipeUpdateResponse: Decodable {
    let id: String
    let title: String
    let updatedAt: String?
}
