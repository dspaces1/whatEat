import Foundation

struct SavedRecipesResponse: Decodable {
    let recipeSaves: [SavedRecipePayload]
    let pagination: SavedRecipesPagination?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        let listKeys = ["recipe_saves", "recipeSaves", "items", "results"]
        let paginationKeys = ["pagination", "meta"]

        if let recipeSaves = decodeList(from: container, keys: listKeys) {
            self.recipeSaves = recipeSaves
            self.pagination = decodePagination(from: container, keys: paginationKeys)
            return
        }

        if let recipeSaves = decodeList(from: container, keys: ["data"]) {
            self.recipeSaves = recipeSaves
            self.pagination = decodePagination(from: container, keys: paginationKeys)
            return
        }

        if let dataContainer = try? container.nestedContainer(
            keyedBy: DynamicCodingKey.self,
            forKey: DynamicCodingKey.key("data")
        ) {
            if let recipeSaves = decodeList(from: dataContainer, keys: listKeys) {
                self.recipeSaves = recipeSaves
                self.pagination = decodePagination(from: dataContainer, keys: paginationKeys)
                    ?? decodePagination(from: container, keys: paginationKeys)
                return
            }
        }

        if let list = try? decoder.singleValueContainer().decode([SavedRecipePayload].self) {
            self.recipeSaves = list
            self.pagination = nil
            return
        }

        throw DecodingError.keyNotFound(
            DynamicCodingKey.key("recipe_saves"),
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing recipe_saves payload."
            )
        )
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    static func key(_ value: String) -> DynamicCodingKey {
        DynamicCodingKey(stringValue: value)!
    }
}

private func decodeList(
    from container: KeyedDecodingContainer<DynamicCodingKey>,
    keys: [String]
) -> [SavedRecipePayload]? {
    for key in keys {
        let codingKey = DynamicCodingKey.key(key)
        if let value = try? container.decodeIfPresent([SavedRecipePayload].self, forKey: codingKey) {
            return value
        }
        if let lossy = try? container.decodeIfPresent(
            LossyDecodableArray<SavedRecipePayload>.self,
            forKey: codingKey
        ) {
            return lossy.values
        }
    }
    return nil
}

private func decodePagination(
    from container: KeyedDecodingContainer<DynamicCodingKey>,
    keys: [String]
) -> SavedRecipesPagination? {
    for key in keys {
        if let value = try? container.decodeIfPresent(
            SavedRecipesPagination.self,
            forKey: DynamicCodingKey.key(key)
        ) {
            return value
        }
    }
    return nil
}

private struct LossyDecodableArray<Element: Decodable>: Decodable {
    let values: [Element]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var items: [Element] = []
        while !container.isAtEnd {
            if let value = try? container.decode(Element.self) {
                items.append(value)
            } else {
                _ = try? container.decode(IgnoredDecodable.self)
            }
        }
        values = items
    }
}

private struct IgnoredDecodable: Decodable {}

struct SavedRecipePayload: Decodable, Identifiable {
    let id: String
    let savedAt: String?
    let sourceRecipeId: String?
    let dailyPlanItemId: String?
    let recipe: RecipeData

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        id = try decodeRequiredString(from: container, keys: ["id"])
        savedAt = decodeOptionalString(from: container, keys: ["saved_at", "savedAt"])
        sourceRecipeId = decodeOptionalString(from: container, keys: ["source_recipe_id", "sourceRecipeId"])
        dailyPlanItemId = decodeOptionalString(from: container, keys: ["daily_plan_item_id", "dailyPlanItemId"])

        if let recipe = decodeOptional(RecipeData.self, from: container, keys: ["recipe_data", "recipeData", "recipe"]) {
            self.recipe = recipe
            return
        }

        throw DecodingError.keyNotFound(
            DynamicCodingKey.key("recipe_data"),
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing recipe or recipe_data payload."
            )
        )
    }
}

private func decodeOptionalString(
    from container: KeyedDecodingContainer<DynamicCodingKey>,
    keys: [String]
) -> String? {
    for key in keys {
        if let value = try? container.decodeIfPresent(String.self, forKey: DynamicCodingKey.key(key)) {
            return value
        }
    }
    return nil
}

private func decodeRequiredString(
    from container: KeyedDecodingContainer<DynamicCodingKey>,
    keys: [String]
) throws -> String {
    for key in keys {
        if let value = try? container.decodeIfPresent(String.self, forKey: DynamicCodingKey.key(key)) {
            return value
        }
    }
    throw DecodingError.keyNotFound(
        DynamicCodingKey.key(keys.first ?? "unknown"),
        DecodingError.Context(
            codingPath: container.codingPath,
            debugDescription: "Missing required string payload."
        )
    )
}

private func decodeOptional<T: Decodable>(
    _ type: T.Type,
    from container: KeyedDecodingContainer<DynamicCodingKey>,
    keys: [String]
) -> T? {
    for key in keys {
        if let value = try? container.decodeIfPresent(T.self, forKey: DynamicCodingKey.key(key)) {
            return value
        }
    }
    return nil
}

struct SavedRecipesPagination: Decodable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
}

struct SaveRecipeRequest: Encodable {
    let sourceType: String
    let sourceId: String

    private enum CodingKeys: String, CodingKey {
        case sourceType = "source_type"
        case sourceId = "source_id"
    }
}

struct SaveRecipeResponse: Decodable {
    let id: String
    let recipeId: String?
    let recipeTitle: String?
    let sourceRecipeId: String?
    let dailyPlanItemId: String?
    let createdAt: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case recipeId
        case recipeTitle
        case sourceRecipeId
        case dailyPlanItemId
        case createdAt
        case recipeSave = "recipe_save"
        case data
    }

    private struct Payload: Decodable {
        let id: String
        let recipeId: String?
        let recipeTitle: String?
        let sourceRecipeId: String?
        let dailyPlanItemId: String?
        let createdAt: String?
    }

    private struct DataWrapper: Decodable {
        let recipeSave: Payload?

        private enum CodingKeys: String, CodingKey {
            case recipeSave = "recipe_save"
        }
    }

    init(from decoder: Decoder) throws {
        if let payload = try? Payload(from: decoder) {
            self.init(payload: payload)
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let payload = try container.decodeIfPresent(Payload.self, forKey: .recipeSave) {
            self.init(payload: payload)
            return
        }
        if let payload = try container.decodeIfPresent(Payload.self, forKey: .data) {
            self.init(payload: payload)
            return
        }
        if let wrapper = try? container.decodeIfPresent(DataWrapper.self, forKey: .data),
           let payload = wrapper.recipeSave {
            self.init(payload: payload)
            return
        }

        throw DecodingError.keyNotFound(
            CodingKeys.id,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Missing recipe save payload."
            )
        )
    }

    private init(payload: Payload) {
        id = payload.id
        recipeId = payload.recipeId
        recipeTitle = payload.recipeTitle
        sourceRecipeId = payload.sourceRecipeId
        dailyPlanItemId = payload.dailyPlanItemId
        createdAt = payload.createdAt
    }
}
