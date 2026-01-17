import Foundation

struct RecipeMapper {
    static func mealType(for recipe: RecipeData) -> MealType {
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

    static func buildRecipe(from recipe: RecipeData, mealType: MealType) -> Recipe {
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
            instructions: instructions,
            tags: recipe.tags ?? [],
            sourceType: recipe.sourceType
        )
    }

    private static func formattedTime(
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

    private static func formatMinutes(_ minutes: Int) -> String {
        guard minutes > 0 else { return "N/A" }
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 {
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
        return "\(remaining) min"
    }

    private static func mapIngredients(_ ingredients: [RecipeIngredient]?) -> [Ingredient] {
        guard let ingredients else { return [] }

        return ingredients.map { ingredient in
            if let text = ingredient.text, !text.isEmpty {
                let cleaned = normalizedText(text)
                return Ingredient(name: cleaned, text: cleaned)
            }

            let amountParts = [ingredient.quantity, ingredient.amount, ingredient.unit]
                .compactMap { part -> String? in
                    guard let part else { return nil }
                    let trimmed = normalizedText(part)
                    return trimmed.isEmpty ? nil : trimmed
                }
            let amountText = amountParts.isEmpty ? nil : amountParts.joined(separator: " ")
            let name = normalizedText(ingredient.name ?? "")

            if name.isEmpty, let amountText {
                return Ingredient(name: "", amount: nil, text: amountText)
            }

            return Ingredient(name: name.isEmpty ? "Ingredient" : name, amount: amountText)
        }
    }

    private static func mapSteps(_ steps: [RecipeStep]?) -> [InstructionStep] {
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
            let fallbackTitle = "Step \(stepNumber)"
            let titleValue = entry.step.title?.isEmpty == false ? entry.step.title! : fallbackTitle
            let title = normalizedText(titleValue)
            let detail = entry.step.detail ?? entry.step.text ?? ""
            let cleanedDetail = normalizedText(detail)

            return InstructionStep(
                stepNumber: stepNumber,
                title: title.isEmpty ? fallbackTitle : title,
                description: cleanedDetail.isEmpty ? "Instructions coming soon." : cleanedDetail
            )
        }
    }

    private static func normalizedText(_ value: String) -> String {
        let replaced = value
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\u{00D0}", with: "-")
            .replacingOccurrences(of: "\u{00D1}", with: "-")
        let parts = replaced.split(whereSeparator: { $0.isWhitespace })
        return parts.joined(separator: " ")
    }
}
