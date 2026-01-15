import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    struct HomeSuggestion: Identifiable {
        let id: String
        let recipe: Recipe
        let rank: Int?
    }

    var suggestionsByMeal: [MealType: [HomeSuggestion]] = [:]
    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?
    var hasLoaded = false

    var isEmpty: Bool {
        suggestionsByMeal.values.allSatisfy { $0.isEmpty }
    }

    func loadDailySuggestions(authManager: AuthenticationManager) async {
        guard !isLoading, !hasLoaded else { return }
        isLoading = true
        defer {
            isLoading = false
            hasLoaded = true
        }

        do {
            let accessToken = try await authManager.getValidAccessToken()
            let response: DailySuggestionsResponse = try await APIService.shared.getAuthenticated(
                path: "/daily/suggestions",
                accessToken: accessToken
            )
            suggestionsByMeal = mapSuggestions(response.suggestions)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshSuggestions(authManager: AuthenticationManager, countPerMeal: Int = 2) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let accessToken = try await authManager.getValidAccessToken()
            let clampedCount = min(max(countPerMeal, 1), 5)
            let response: DailyRefreshResponse = try await APIService.shared.getAuthenticated(
                path: "/daily/refresh",
                queryItems: [URLQueryItem(name: "count_per_meal", value: "\(clampedCount)")],
                accessToken: accessToken
            )
            suggestionsByMeal = mapBuckets(response.suggestions)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func suggestions(for mealType: MealType) -> [HomeSuggestion] {
        suggestionsByMeal[mealType] ?? []
    }

    private func mapSuggestions(_ suggestions: [DailySuggestion]) -> [MealType: [HomeSuggestion]] {
        var grouped: [MealType: [HomeSuggestion]] = [:]

        for suggestion in suggestions {
            let mealType = mealType(for: suggestion.recipeData)
            let recipe = buildRecipe(from: suggestion.recipeData, mealType: mealType)
            let item = HomeSuggestion(id: suggestion.id, recipe: recipe, rank: suggestion.rank)
            grouped[mealType, default: []].append(item)
        }

        return sortGroupedSuggestions(grouped)
    }

    private func mapBuckets(_ buckets: [String: [DailySuggestion]]) -> [MealType: [HomeSuggestion]] {
        var grouped: [MealType: [HomeSuggestion]] = [:]

        for (key, suggestions) in buckets {
            let mealType = MealType(apiValue: key) ?? .other
            let items = suggestions.map { suggestion -> HomeSuggestion in
                let recipe = buildRecipe(from: suggestion.recipeData, mealType: mealType)
                return HomeSuggestion(id: suggestion.id, recipe: recipe, rank: suggestion.rank)
            }
            grouped[mealType] = items
        }

        return sortGroupedSuggestions(grouped)
    }

    private func sortGroupedSuggestions(
        _ grouped: [MealType: [HomeSuggestion]]
    ) -> [MealType: [HomeSuggestion]] {
        var sorted = grouped
        for key in sorted.keys {
            sorted[key] = sorted[key]?.sorted {
                ($0.rank ?? Int.max, $0.id) < ($1.rank ?? Int.max, $1.id)
            }
        }
        return sorted
    }

    private func mealType(for recipe: RecipeData) -> MealType {
        if let metadataMeal = recipe.metadata?.mealType,
           let mealType = MealType(apiValue: metadataMeal) {
            return mealType
        }

        if let tags = recipe.tags {
            for tag in tags {
                if let mealType = MealType(apiValue: tag) {
                    return mealType
                }
            }
        }

        return .other
    }

    private func buildRecipe(from recipe: RecipeData, mealType: MealType) -> Recipe {
        let prepTime = formattedTime(
            prepTime: recipe.prepTime,
            cookTime: recipe.cookTime,
            prepMinutes: recipe.prepTimeMinutes,
            cookMinutes: recipe.cookTimeMinutes
        )
        let ingredients = mapIngredients(recipe.ingredients)
        let instructions = mapSteps(recipe.steps)
        let imageURL = recipe.media?.first?.url

        return Recipe(
            id: recipe.id,
            name: recipe.title,
            mealType: mealType,
            prepTime: prepTime,
            calories: recipe.calories,
            imageURL: imageURL,
            ingredients: ingredients,
            instructions: instructions
        )
    }

    private func formattedTime(
        prepTime: String?,
        cookTime: String?,
        prepMinutes: Int?,
        cookMinutes: Int?
    ) -> String {
        if let prepTime, !prepTime.isEmpty {
            return prepTime
        }
        if let cookTime, !cookTime.isEmpty {
            return cookTime
        }
        if let prepMinutes, let cookMinutes {
            return formatMinutes(prepMinutes + cookMinutes)
        }
        if let prepMinutes {
            return formatMinutes(prepMinutes)
        }
        if let cookMinutes {
            return formatMinutes(cookMinutes)
        }
        return "N/A"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        guard minutes > 0 else { return "N/A" }
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 {
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
        return "\(remaining) min"
    }

    private func mapIngredients(_ ingredients: [RecipeIngredient]?) -> [Ingredient] {
        guard let ingredients else { return [] }

        return ingredients.map { ingredient in
            if let text = ingredient.text, !text.isEmpty {
                return Ingredient(name: text, text: text)
            }

            let amountParts = [ingredient.quantity, ingredient.amount, ingredient.unit]
                .compactMap { part -> String? in
                    guard let part else { return nil }
                    let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                    return trimmed.isEmpty ? nil : trimmed
                }
            let amountText = amountParts.isEmpty ? nil : amountParts.joined(separator: " ")
            let name = ingredient.name ?? ""

            if name.isEmpty, let amountText {
                return Ingredient(name: "", amount: nil, text: amountText)
            }

            return Ingredient(name: name.isEmpty ? "Ingredient" : name, amount: amountText)
        }
    }

    private func mapSteps(_ steps: [RecipeStep]?) -> [InstructionStep] {
        guard let steps else { return [] }
        let indexedSteps = steps.enumerated().map { (index: $0.offset, step: $0.element) }
        let sortedSteps = indexedSteps.sorted { lhs, rhs in
            switch (lhs.step.order, rhs.step.order) {
            case let (left?, right?):
                return left == right ? lhs.index < rhs.index : left < right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.index < rhs.index
            }
        }

        return sortedSteps.enumerated().map { offset, entry in
            let stepNumber = offset + 1
            let title = entry.step.title?.isEmpty == false ? entry.step.title! : "Step \(stepNumber)"
            let detail = entry.step.detail ?? entry.step.text ?? ""
            let description = detail.isEmpty ? "Instructions coming soon." : detail

            return InstructionStep(stepNumber: stepNumber, title: title, description: description)
        }
    }
}
