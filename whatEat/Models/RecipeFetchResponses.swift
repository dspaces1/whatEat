import Foundation

struct RecipeDataResponse: Decodable {
    let recipeData: RecipeData

    private enum CodingKeys: String, CodingKey {
        case recipeData = "recipe_data"
        case recipe
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let recipeData = try container.decodeIfPresent(RecipeData.self, forKey: .recipeData) {
            self.recipeData = recipeData
            return
        }
        if let recipeData = try container.decodeIfPresent(RecipeData.self, forKey: .recipe) {
            self.recipeData = recipeData
            return
        }
        throw DecodingError.keyNotFound(
            CodingKeys.recipeData,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing recipe_data or recipe payload."
            )
        )
    }
}

struct ImportRecipeResponse: Decodable {
    let recipeData: RecipeData?
    let savePayload: RecipeEnvelope?

    private enum CodingKeys: String, CodingKey {
        case recipeData = "recipe_data"
        case savePayload = "save_payload"
    }

    var resolvedRecipeData: RecipeData? {
        recipeData ?? savePayload?.recipe
    }
}

struct RecipeEnvelope: Decodable {
    let recipe: RecipeData
}
