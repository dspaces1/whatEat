import Foundation
import SwiftUI
import Observation

struct RecipeEditorItem: Identifiable, Equatable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func == (lhs: RecipeEditorItem, rhs: RecipeEditorItem) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
@Observable
final class RecipeEditorViewModel {
    enum Mode {
        case create
        case edit(recipe: Recipe)
    }

    let mode: Mode
    var title: String
    var ingredients: [RecipeEditorItem]
    var instructions: [RecipeEditorItem]
    var prepHours: Int
    var prepMinutes: Int
    var caloriesText: String
    var mealType: MealType
    var coverPhotoURL: URL?
    var coverPhotoImage: UIImage?
    var isUploadingCoverPhoto = false
    var isSaving = false
    var errorMessage: String?

    private var coverPhotoUploadTask: Task<Void, Never>?

    init(mode: Mode) {
        let resolvedTitle: String
        var resolvedIngredients: [RecipeEditorItem]
        var resolvedInstructions: [RecipeEditorItem]
        let resolvedPrepHours: Int
        let resolvedPrepMinutes: Int
        let resolvedCaloriesText: String
        let resolvedMealType: MealType
        let resolvedCoverPhotoURL: URL?

        switch mode {
        case .create:
            resolvedTitle = ""
            resolvedIngredients = [RecipeEditorItem(text: "")]
            resolvedInstructions = [RecipeEditorItem(text: "")]
            resolvedPrepHours = 0
            resolvedPrepMinutes = 0
            resolvedCaloriesText = ""
            resolvedMealType = .other
            resolvedCoverPhotoURL = nil
        case .edit(let recipe):
            resolvedTitle = recipe.name
            resolvedIngredients = recipe.ingredients.map { RecipeEditorItem(text: $0.displayText) }
            if resolvedIngredients.isEmpty {
                resolvedIngredients = [RecipeEditorItem(text: "")]
            }
            let instructionTexts = recipe.instructions.map {
                let detail = $0.description.trimmingCharacters(in: .whitespacesAndNewlines)
                return detail.isEmpty ? $0.title : $0.description
            }
            resolvedInstructions = instructionTexts.map { RecipeEditorItem(text: $0) }
            if resolvedInstructions.isEmpty {
                resolvedInstructions = [RecipeEditorItem(text: "")]
            }
            let totalMinutes = RecipeEditorViewModel.parseMinutes(from: recipe.prepTime) ?? 0
            resolvedPrepHours = totalMinutes / 60
            resolvedPrepMinutes = totalMinutes % 60
            resolvedCaloriesText = recipe.calories.map(String.init) ?? ""
            resolvedMealType = recipe.mealType
            resolvedCoverPhotoURL = recipe.imageURL
        }

        self.mode = mode
        title = resolvedTitle
        ingredients = resolvedIngredients
        instructions = resolvedInstructions
        prepHours = resolvedPrepHours
        prepMinutes = resolvedPrepMinutes
        caloriesText = resolvedCaloriesText
        mealType = resolvedMealType
        coverPhotoURL = resolvedCoverPhotoURL
        coverPhotoImage = nil
    }

    var navigationTitle: String {
        switch mode {
        case .create:
            return "New Recipe"
        case .edit:
            return "Edit Recipe"
        }
    }

    var totalPrepMinutes: Int {
        max(0, prepHours * 60 + prepMinutes)
    }

    var formattedPrepTime: String {
        RecipeEditorViewModel.formatMinutes(totalPrepMinutes)
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasRequiredFields: Bool {
        !trimmedTitle.isEmpty
            && !nonEmptyIngredients.isEmpty
            && !nonEmptyInstructions.isEmpty
            && totalPrepMinutes > 0
    }

    var nonEmptyIngredients: [RecipeEditorItem] {
        ingredients.filter { !$0.trimmedText.isEmpty }
    }

    var nonEmptyInstructions: [RecipeEditorItem] {
        instructions.filter { !$0.trimmedText.isEmpty }
    }

    var parsedCalories: Int? {
        let trimmed = caloriesText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }

    var isCoverPhotoReadyForSave: Bool {
        coverPhotoImage == nil || coverPhotoURL != nil
    }

    func handleCoverPhotoSelection(_ image: UIImage, accessToken: String) {
        cancelCoverPhotoUpload()
        coverPhotoImage = image
        coverPhotoURL = nil
        isUploadingCoverPhoto = true
        errorMessage = nil

        coverPhotoUploadTask = Task { [weak self] in
            do {
                let url = try await ImageUploadService.shared.uploadCoverPhoto(image, accessToken: accessToken)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.coverPhotoURL = url
                    self?.isUploadingCoverPhoto = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self?.isUploadingCoverPhoto = false
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func removeCoverPhoto() {
        cancelCoverPhotoUpload()
        coverPhotoImage = nil
        coverPhotoURL = nil
    }

    func makeCreateRequest() -> RecipeCreateRequest {
        RecipeCreateRequest(
            title: trimmedTitle,
            description: nil,
            servings: nil,
            calories: parsedCalories,
            prepTime: nil,
            cookTime: nil,
            prepTimeMinutes: totalPrepMinutes,
            cookTimeMinutes: nil,
            tags: nil,
            cuisine: nil,
            dietaryLabels: nil,
            ingredients: nonEmptyIngredients.map { RecipeIngredientPayload(rawText: $0.trimmedText) },
            steps: nonEmptyInstructions.enumerated().map { index, item in
                RecipeStepPayload(instruction: item.trimmedText, order: index + 1)
            },
            media: coverPhotoURL.map {
                [
                    RecipeMediaPayload(
                        mediaType: "image",
                        url: $0.absoluteString,
                        name: "Cover photo"
                    )
                ]
            },
            metadata: nil
        )
    }

    func makeUpdateRequest() -> RecipeUpdateRequest {
        RecipeUpdateRequest(
            title: trimmedTitle,
            description: nil,
            servings: nil,
            calories: parsedCalories,
            prepTime: nil,
            cookTime: nil,
            prepTimeMinutes: totalPrepMinutes,
            cookTimeMinutes: nil,
            tags: nil,
            cuisine: nil,
            dietaryLabels: nil,
            ingredients: nonEmptyIngredients.map { RecipeIngredientPayload(rawText: $0.trimmedText) },
            steps: nonEmptyInstructions.enumerated().map { index, item in
                RecipeStepPayload(instruction: item.trimmedText, order: index + 1)
            },
            media: coverPhotoURL.map {
                [
                    RecipeMediaPayload(
                        mediaType: "image",
                        url: $0.absoluteString,
                        name: "Cover photo"
                    )
                ]
            },
            metadata: nil
        )
    }

    func makeRecipe(id: String, sourceType: String?) -> Recipe {
        Recipe(
            id: id,
            name: trimmedTitle,
            mealType: mealType,
            prepTime: formattedPrepTime,
            calories: parsedCalories,
            imageURL: coverPhotoURL,
            ingredients: nonEmptyIngredients.map { Ingredient(name: $0.trimmedText, text: $0.trimmedText) },
            instructions: nonEmptyInstructions.enumerated().map { index, item in
                InstructionStep(
                    stepNumber: index + 1,
                    title: "Step \(index + 1)",
                    description: item.trimmedText
                )
            },
            tags: [],
            sourceType: sourceType,
            ownership: RecipeOwnership(isUserOwned: true),
            editableRecipeId: id
        )
    }

    static func formatMinutes(_ minutes: Int) -> String {
        guard minutes > 0 else { return "0 min" }
        let hours = minutes / 60
        let remaining = minutes % 60
        if hours > 0 {
            return remaining > 0 ? "\(hours)h \(remaining)m" : "\(hours)h"
        }
        return "\(remaining) min"
    }

    static func parseMinutes(from value: String) -> Int? {
        let lower = value.lowercased()
        if lower.contains("n/a") {
            return nil
        }
        var total = 0
        let hourPattern = #"(\d+)\s*h"#
        let minutePattern = #"(\d+)\s*m"#
        if let hourMatch = lower.range(of: hourPattern, options: .regularExpression),
           let hours = Int(lower[hourMatch].replacingOccurrences(of: "h", with: "").trimmingCharacters(in: .whitespaces)) {
            total += hours * 60
        }
        if let minuteMatch = lower.range(of: minutePattern, options: .regularExpression),
           let minutes = Int(lower[minuteMatch].replacingOccurrences(of: "m", with: "").trimmingCharacters(in: .whitespaces)) {
            total += minutes
        }
        if total == 0 {
            if let fallback = Int(lower.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return fallback
            }
        }
        return total > 0 ? total : nil
    }

    private func cancelCoverPhotoUpload() {
        coverPhotoUploadTask?.cancel()
        coverPhotoUploadTask = nil
        isUploadingCoverPhoto = false
    }
}
