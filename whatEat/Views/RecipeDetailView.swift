import SwiftUI

struct RecipeDetailView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(SavedRecipesStore.self) private var savedRecipesStore
    @Environment(\.dismiss) private var dismiss

    let recipe: Recipe
    let showsEditButton: Bool
    
    @State private var showUnsaveConfirmation = false
    @State private var isBookmarkBusy = false
    @State private var isPreparingEdit = false
    @State private var editErrorMessage: String?
    @State private var editorRecipe: Recipe?
    @State private var showEditor = false
    @State private var currentRecipe: Recipe
    
    private let coralColor = Color(red: 0.96, green: 0.58, blue: 0.53)
    private let softGreen = Color(red: 0.56, green: 0.82, blue: 0.67)

    init(recipe: Recipe, showsEditButton: Bool) {
        self.recipe = recipe
        self.showsEditButton = showsEditButton
        _currentRecipe = State(initialValue: recipe)
    }
    
    var body: some View {
        let base = AnyView(
            content
                .background(Color(.systemBackground))
                .navigationTitle(currentRecipe.name)
                .navigationBarTitleDisplayMode(.inline)
        )

        let withToolbar = AnyView(
            base.toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarButtons
                }
            }
        )

        let withAlerts = AnyView(
            withToolbar
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
                .navigationDestination(isPresented: $showEditor) {
                    if let recipe = editorRecipe {
                        RecipeEditorView(mode: .edit(recipe: recipe))
                    }
                }
                .alert("Unable to edit", isPresented: editAlertBinding) {
                    Button("OK", role: .cancel) {
                        editErrorMessage = nil
                    }
                } message: {
                    Text(editErrorMessage ?? "Something went wrong.")
                }
        )

        return AnyView(
            withAlerts.onChange(of: showEditor) { _, newValue in
                if !newValue {
                    editorRecipe = nil
                    refreshCurrentRecipe()
                }
            }
        )
    }

    private var content: some View {
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
    }

    private var toolbarButtons: some View {
        HStack(spacing: 16) {
            if showsEditButton {
                Button {
                    beginEdit()
                } label: {
                    if isPreparingEdit {
                        ProgressView()
                            .tint(coralColor)
                    } else {
                        Image(systemName: "pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .disabled(isPreparingEdit)
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

    private var editAlertBinding: Binding<Bool> {
        Binding(
            get: { editErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    editErrorMessage = nil
                }
            }
        )
    }

    private func refreshCurrentRecipe() {
        if let updated = savedRecipesStore.savedRecipes.first(where: { $0.recipe.id == currentRecipe.id })?.recipe {
            currentRecipe = updated
        } else if let updated = savedRecipesStore.savedRecipes.first(where: { $0.sourceRecipeId == currentRecipe.id })?.recipe {
            currentRecipe = updated
        }
    }
    
    // MARK: - Hero Image
    
    private var heroImage: some View {
        ZStack {
            RemoteImageView(
                url: currentRecipe.imageURL,
                contentMode: .fill,
                showsPlaceholderIcon: true,
                placeholderBackground: currentRecipe.mealType.accentColor.opacity(0.2),
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
                
                Text(currentRecipe.prepTime)
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
                
                Text(currentRecipe.caloriesDisplay)
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
        Text(currentRecipe.name)
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
                        savedRecipesStore.resetIngredientChecks(recipeId: currentRecipe.id)
                    }
                } label: {
                    Text("Reset")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(coralColor)
                }
            }
            
            // Ingredient list
            if currentRecipe.ingredients.isEmpty {
                Text("Ingredients will appear here once available.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 14) {
                    ForEach(currentRecipe.ingredients) { ingredient in
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
                    recipeId: currentRecipe.id,
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
            if currentRecipe.instructions.isEmpty {
                Text("Instructions will appear here once available.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 24) {
                    ForEach(currentRecipe.instructions) { step in
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
        savedRecipesStore.isSaved(recipeId: currentRecipe.id)
    }

    private func isIngredientChecked(_ ingredient: Ingredient) -> Bool {
        savedRecipesStore.isIngredientChecked(recipeId: currentRecipe.id, key: ingredient.cacheKey)
    }

    private func handleSave() async {
        guard !isBookmarkBusy else { return }
        isBookmarkBusy = true
        defer { isBookmarkBusy = false }
        await savedRecipesStore.save(
            recipe: currentRecipe,
            source: .recipe(id: currentRecipe.id),
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
        await savedRecipesStore.unsave(recipe: currentRecipe, authManager: authManager)
    }

    private func beginEdit() {
        guard !isPreparingEdit else { return }
        editErrorMessage = nil
        editorRecipe = currentRecipe
        showEditor = true
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: MockRecipeData.recipes[0], showsEditButton: false)
    }
    .environment(AuthenticationManager())
    .environment(SavedRecipesStore.preview())
}
