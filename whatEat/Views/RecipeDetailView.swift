import SwiftUI

struct RecipeDetailView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(SavedRecipesStore.self) private var savedRecipesStore
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe
    let showsEditButton: Bool
    
    @State private var showUnsaveConfirmation = false
    @State private var isBookmarkBusy = false
    
    private let coralColor = Color(red: 0.96, green: 0.58, blue: 0.53)
    private let softGreen = Color(red: 0.56, green: 0.82, blue: 0.67)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Image with overlapping stats card
                ZStack(alignment: .bottom) {
                    heroImage
                    statsCard
                        .offset(y: 40)
                }
                .padding(.bottom, 40)
                
                // Content
                VStack(alignment: .leading, spacing: 24) {
                    recipeTitle
                    ingredientsSection
                    instructionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    if showsEditButton {
                        Button {
                            // TODO: Hook up edit flow.
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }

                    Button {
                        guard !isBookmarkBusy else { return }
                        if isBookmarked {
                            showUnsaveConfirmation = true
                        } else {
                            Task {
                                await handleSave()
                            }
                        }
                    } label: {
                        ZStack {
                            if isBookmarkBusy {
                                ProgressView()
                                    .tint(coralColor)
                            } else {
                                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isBookmarked ? coralColor : .primary)
                            }
                        }
                    }
                    .disabled(isBookmarkBusy)
                }
            }
        }
        .alert("Remove bookmark?", isPresented: $showUnsaveConfirmation) {
            Button("Remove", role: .destructive) {
                Task {
                    await handleUnsaveAndDismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove this recipe from saved?")
        }
    }
    
    // MARK: - Hero Image
    
    private var heroImage: some View {
        ZStack {
            RemoteImageView(
                url: recipe.imageURL,
                contentMode: .fill,
                showsPlaceholderIcon: true,
                placeholderBackground: recipe.mealType.accentColor.opacity(0.2),
                placeholderIconFont: .system(size: 48)
            )
            .frame(height: 280)
            .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.05),
                    Color.black.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Stats Card
    
    private var statsCard: some View {
        HStack(spacing: 0) {
            // Time
            VStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 20))
                    .foregroundColor(softGreen)
                
                Text("TIME")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                
                Text(recipe.prepTime)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 60)
            
            // Calories
            VStack(spacing: 6) {
                Image(systemName: "flame")
                    .font(.system(size: 20))
                    .foregroundColor(softGreen)
                
                Text("CALORIES")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
                
                Text(recipe.caloriesDisplay)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 4)
        )
        .padding(.horizontal, 40)
    }

    // MARK: - Title

    private var recipeTitle: some View {
        Text(recipe.name)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.primary)
            .lineLimit(3)
            .truncationMode(.tail)
    }
    
    // MARK: - Ingredients Section
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(coralColor)
                        .frame(width: 4, height: 24)
                    
                    Text("Ingredients")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        savedRecipesStore.resetIngredientChecks(recipeId: recipe.id)
                    }
                } label: {
                    Text("Reset")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(coralColor)
                }
            }
            
            // Ingredient list
            if recipe.ingredients.isEmpty {
                Text("Ingredients will appear here once available.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 14) {
                    ForEach(recipe.ingredients) { ingredient in
                        ingredientRow(ingredient)
                    }
                }
            }
        }
    }
    
    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                savedRecipesStore.toggleIngredientCheck(
                    recipeId: recipe.id,
                    key: ingredient.cacheKey
                )
            }
        } label: {
            HStack(spacing: 14) {
                // Checkbox
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isIngredientChecked(ingredient) ? coralColor : Color.gray.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Group {
                            if isIngredientChecked(ingredient) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(coralColor)
                            }
                        }
                    )
                
                Text(ingredient.displayText)
                    .font(.system(size: 16))
                    .foregroundColor(isIngredientChecked(ingredient) ? .secondary : .primary)
                    .strikethrough(isIngredientChecked(ingredient), color: .secondary)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(coralColor)
                    .frame(width: 4, height: 24)
                
                Text("Instructions")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Steps
            if recipe.instructions.isEmpty {
                Text("Instructions will appear here once available.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 24) {
                    ForEach(recipe.instructions) { step in
                        instructionRow(step)
                    }
                }
            }
        }
    }
    
    private func instructionRow(_ step: InstructionStep) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(softGreen.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Text("\(step.stepNumber)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(softGreen)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(step.description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var isBookmarked: Bool {
        savedRecipesStore.isSaved(recipeId: recipe.id)
    }

    private func isIngredientChecked(_ ingredient: Ingredient) -> Bool {
        savedRecipesStore.isIngredientChecked(recipeId: recipe.id, key: ingredient.cacheKey)
    }

    private func handleSave() async {
        guard !isBookmarkBusy else { return }
        isBookmarkBusy = true
        defer { isBookmarkBusy = false }
        await savedRecipesStore.save(
            recipe: recipe,
            source: .recipe(id: recipe.id),
            authManager: authManager
        )
    }

    private func handleUnsaveAndDismiss() async {
        guard !isBookmarkBusy else { return }
        isBookmarkBusy = true
        defer {
            isBookmarkBusy = false
            dismiss()
        }
        await savedRecipesStore.unsave(recipe: recipe, authManager: authManager)
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: MockRecipeData.recipes[0], showsEditButton: false)
    }
    .environment(AuthenticationManager())
    .environment(SavedRecipesStore.preview())
}
