import Foundation
import Observation

@MainActor
@Observable
final class SavedRecipesStore {
    struct SavedRecipeItem: Identifiable {
        let id: String
        let savedAt: String?
        let sourceRecipeId: String?
        let dailyPlanItemId: String?
        var recipe: Recipe
    }

    enum SaveSource {
        case dailyPlanItem(id: String)
        case recipe(id: String)
        case share(token: String)

        var request: SaveRecipeRequest {
            switch self {
            case .dailyPlanItem(let id):
                return SaveRecipeRequest(sourceType: "daily_plan_item", sourceId: id)
            case .recipe(let id):
                return SaveRecipeRequest(sourceType: "recipe", sourceId: id)
            case .share(let token):
                return SaveRecipeRequest(sourceType: "share", sourceId: token)
            }
        }
    }

    var savedRecipes: [SavedRecipeItem] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?
    var hasLoaded = false
    var pagination: SavedRecipesPagination?

    private var saveIdByRecipeId: [String: String] = [:]
    private var checkedIngredientsByRecipeId: [String: Set<String>] = [:]
    private var currentPage = 1
    private var pageLimit = 20
    private var hasReachedEndWithoutPagination = false

    func loadSavedRecipesIfNeeded(authManager: AuthenticationManager) async {
        guard !hasLoaded else { return }
        await loadSavedRecipes(authManager: authManager, page: 1, limit: pageLimit, force: false)
    }

    func loadSavedRecipes(
        authManager: AuthenticationManager,
        page: Int = 1,
        limit: Int = 20,
        force: Bool = false
    ) async {
        let isFirstPage = page <= 1
        if isFirstPage {
            guard !isLoading else { return }
            if hasLoaded && !force { return }
            isLoading = true
        } else {
            guard !isLoadingMore else { return }
            isLoadingMore = true
        }

        var didLoad = false
        defer {
            if isFirstPage {
                isLoading = false
            } else {
                isLoadingMore = false
            }
            if didLoad {
                if isFirstPage {
                    hasLoaded = true
                }
            }
        }

        do {
            let accessToken = try await authManager.getValidAccessToken()
            let response: SavedRecipesResponse = try await APIService.shared.getAuthenticated(
                path: "/recipe-saves",
                queryItems: [
                    URLQueryItem(name: "page", value: "\(page)"),
                    URLQueryItem(name: "limit", value: "\(limit)")
                ],
                accessToken: accessToken
            )
            let items = response.recipeSaves.map { payload -> SavedRecipeItem in
                let mealType = RecipeMapper.mealType(for: payload.recipe)
                let recipe = RecipeMapper.buildRecipe(from: payload.recipe, mealType: mealType)
                return SavedRecipeItem(
                    id: payload.id,
                    savedAt: payload.savedAt,
                    sourceRecipeId: payload.sourceRecipeId,
                    dailyPlanItemId: payload.dailyPlanItemId,
                    recipe: recipe
                )
            }
            if isFirstPage {
                savedRecipes = items
                rebuildIndex()
            } else {
                appendSavedRecipes(items)
            }
            pagination = response.pagination
            currentPage = response.pagination?.page ?? page
            pageLimit = response.pagination?.limit ?? limit
            if response.pagination == nil {
                hasReachedEndWithoutPagination = items.count < limit
            } else {
                hasReachedEndWithoutPagination = false
            }
            errorMessage = nil
            didLoad = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isSaved(recipeId: String) -> Bool {
        saveIdByRecipeId[recipeId] != nil
    }

    func saveId(for recipeId: String) -> String? {
        saveIdByRecipeId[recipeId]
    }

    func save(
        recipe: Recipe,
        source: SaveSource,
        authManager: AuthenticationManager
    ) async {
        guard !isSaved(recipeId: recipe.id) else { return }

        do {
            let accessToken = try await authManager.getValidAccessToken()
            let response: SaveRecipeResponse = try await APIService.shared.postAuthenticated(
                path: "/recipe-saves",
                body: source.request,
                accessToken: accessToken
            )
            let resolvedRecipeId = response.recipeId ?? response.sourceRecipeId ?? recipe.id
            let savedRecipe = makeSavedRecipe(
                from: recipe,
                savedRecipeId: resolvedRecipeId,
                sourceTypeOverride: "user"
            )
            let item = SavedRecipeItem(
                id: response.id,
                savedAt: response.createdAt,
                sourceRecipeId: response.sourceRecipeId ?? recipe.id,
                dailyPlanItemId: response.dailyPlanItemId,
                recipe: savedRecipe
            )
            upsertSavedRecipe(item, insertAtTop: true)
            errorMessage = nil
        } catch {
            if let apiError = error as? APIError,
               case .httpError(let statusCode) = apiError,
               statusCode == 409 {
                await loadSavedRecipes(authManager: authManager, page: 1, limit: 20, force: true)
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func ensureEditableRecipeId(
        for recipe: Recipe,
        authManager: AuthenticationManager
    ) async throws -> String {
        if recipe.isUserOwned {
            return recipe.id
        }

        if let editableRecipeId = recipe.editableRecipeId, !editableRecipeId.isEmpty {
            return editableRecipeId
        }

        if let existing = savedRecipes.first(where: { $0.sourceRecipeId == recipe.id }) {
            return existing.recipe.id
        }

        let accessToken = try await authManager.getValidAccessToken()
        let response: SaveRecipeResponse = try await APIService.shared.postAuthenticated(
            path: "/recipe-saves",
            body: SaveSource.recipe(id: recipe.id).request,
            accessToken: accessToken
        )
        let resolvedRecipeId = response.recipeId ?? response.sourceRecipeId ?? recipe.id
        let savedRecipe = makeSavedRecipe(
            from: recipe,
            savedRecipeId: resolvedRecipeId,
            sourceTypeOverride: "user"
        )
        let item = SavedRecipeItem(
            id: response.id,
            savedAt: response.createdAt,
            sourceRecipeId: response.sourceRecipeId ?? recipe.id,
            dailyPlanItemId: response.dailyPlanItemId,
            recipe: savedRecipe
        )
        upsertSavedRecipe(item, insertAtTop: true)
        return resolvedRecipeId
    }

    func updateRecipe(_ recipe: Recipe, sourceRecipeId: String? = nil) {
        if let index = savedRecipes.firstIndex(where: { $0.recipe.id == recipe.id }) {
            savedRecipes[index].recipe = recipe
            rebuildIndex()
            return
        }
        if let sourceRecipeId,
           let index = savedRecipes.firstIndex(where: { $0.sourceRecipeId == sourceRecipeId }) {
            let item = savedRecipes[index]
            savedRecipes[index] = SavedRecipeItem(
                id: item.id,
                savedAt: item.savedAt,
                sourceRecipeId: item.sourceRecipeId,
                dailyPlanItemId: item.dailyPlanItemId,
                recipe: recipe
            )
            rebuildIndex()
        }
    }

    func refreshAfterRecipeMutation(
        recipe: Recipe,
        authManager: AuthenticationManager
    ) async {
        await loadSavedRecipes(authManager: authManager, page: 1, limit: pageLimit, force: true)
    }

    func loadMoreSavedRecipes(authManager: AuthenticationManager) async {
        guard canLoadMore else { return }
        let nextPage = currentPage + 1
        await loadSavedRecipes(authManager: authManager, page: nextPage, limit: pageLimit, force: true)
    }

    var canLoadMore: Bool {
        if let pagination {
            return pagination.page < pagination.totalPages
        }
        if hasReachedEndWithoutPagination {
            return false
        }
        return savedRecipes.count >= pageLimit && !savedRecipes.isEmpty
    }

    func unsave(recipe: Recipe, authManager: AuthenticationManager) async {
        guard let saveId = saveIdByRecipeId[recipe.id] else { return }

        do {
            let accessToken = try await authManager.getValidAccessToken()
            try await APIService.shared.deleteAuthenticated(
                path: "/recipe-saves/\(saveId)",
                accessToken: accessToken
            )
            removeSavedRecipe(saveId: saveId)
            errorMessage = nil
        } catch {
            if let apiError = error as? APIError,
               case .httpError(let statusCode) = apiError,
               statusCode == 404 {
                removeSavedRecipe(saveId: saveId)
                return
            }
            errorMessage = error.localizedDescription
        }
    }

    func isIngredientChecked(recipeId: String, key: String) -> Bool {
        checkedIngredientsByRecipeId[recipeId]?.contains(key) ?? false
    }

    func toggleIngredientCheck(recipeId: String, key: String) {
        var set = checkedIngredientsByRecipeId[recipeId] ?? []
        if set.contains(key) {
            set.remove(key)
        } else {
            set.insert(key)
        }
        checkedIngredientsByRecipeId[recipeId] = set
    }

    func resetIngredientChecks(recipeId: String) {
        checkedIngredientsByRecipeId[recipeId] = []
    }

    func reset() {
        savedRecipes = []
        isLoading = false
        isLoadingMore = false
        errorMessage = nil
        hasLoaded = false
        pagination = nil
        saveIdByRecipeId = [:]
        checkedIngredientsByRecipeId = [:]
        currentPage = 1
        pageLimit = 20
        hasReachedEndWithoutPagination = false
    }

    private func rebuildIndex() {
        var updated: [String: String] = [:]
        for item in savedRecipes {
            updated[item.recipe.id] = item.id
            if let sourceRecipeId = item.sourceRecipeId {
                updated[sourceRecipeId] = item.id
            }
        }
        saveIdByRecipeId = updated
    }

    private func upsertSavedRecipe(_ item: SavedRecipeItem, insertAtTop: Bool) {
        if let index = savedRecipes.firstIndex(where: { $0.id == item.id }) {
            savedRecipes[index] = item
        } else if insertAtTop {
            savedRecipes.insert(item, at: 0)
        } else {
            savedRecipes.append(item)
        }
        rebuildIndex()
    }

    private func appendSavedRecipes(_ items: [SavedRecipeItem]) {
        for item in items {
            if let index = savedRecipes.firstIndex(where: { $0.id == item.id }) {
                savedRecipes[index] = item
            } else {
                savedRecipes.append(item)
            }
        }
        rebuildIndex()
    }

    private func removeSavedRecipe(saveId: String) {
        savedRecipes.removeAll { $0.id == saveId }
        rebuildIndex()
    }

    private func makeSavedRecipe(
        from recipe: Recipe,
        savedRecipeId: String,
        sourceTypeOverride: String? = nil
    ) -> Recipe {
        Recipe(
            id: savedRecipeId,
            name: recipe.name,
            mealType: recipe.mealType,
            prepTime: recipe.prepTime,
            calories: recipe.calories,
            imageURL: recipe.imageURL,
            ingredients: recipe.ingredients,
            instructions: recipe.instructions,
            tags: recipe.tags,
            sourceType: sourceTypeOverride ?? recipe.sourceType,
            ownership: RecipeOwnership(isUserOwned: true),
            editableRecipeId: savedRecipeId
        )
    }
}

#if DEBUG
@MainActor
extension SavedRecipesStore {
    static func preview() -> SavedRecipesStore {
        let store = SavedRecipesStore()
        store.savedRecipes = MockRecipeData.recipes.prefix(3).enumerated().map { index, recipe in
            SavedRecipeItem(
                id: "preview-\(index)",
                savedAt: nil,
                sourceRecipeId: recipe.id,
                dailyPlanItemId: nil,
                recipe: recipe
            )
        }
        store.hasLoaded = true
        store.rebuildIndex()
        return store
    }
}
#endif
