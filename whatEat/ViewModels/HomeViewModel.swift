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
            switch response.suggestions {
            case .list(let suggestions):
                suggestionsByMeal = mapSuggestions(suggestions)
            case .buckets(let buckets):
                suggestionsByMeal = mapBuckets(buckets)
            }
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
            let mealType = RecipeMapper.mealType(for: suggestion.recipeData)
            let recipe = RecipeMapper.buildRecipe(from: suggestion.recipeData, mealType: mealType)
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
                let recipe = RecipeMapper.buildRecipe(from: suggestion.recipeData, mealType: mealType)
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

}
