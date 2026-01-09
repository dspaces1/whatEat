import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    
    @State private var checkedIngredients: Set<UUID> = []
    @State private var isBookmarked: Bool = false
    
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
                VStack(alignment: .leading, spacing: 28) {
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
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isBookmarked.toggle()
                    }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isBookmarked ? coralColor : .primary)
                }
            }
        }
    }
    
    // MARK: - Hero Image
    
    private var heroImage: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        recipe.mealType.accentColor.opacity(0.3),
                        recipe.mealType.accentColor.opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 280)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(recipe.mealType.accentColor.opacity(0.4))
            )
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
                        checkedIngredients.removeAll()
                    }
                } label: {
                    Text("Reset")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(coralColor)
                }
            }
            
            // Ingredient list
            VStack(spacing: 14) {
                ForEach(recipe.ingredients) { ingredient in
                    ingredientRow(ingredient)
                }
            }
        }
    }
    
    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if checkedIngredients.contains(ingredient.id) {
                    checkedIngredients.remove(ingredient.id)
                } else {
                    checkedIngredients.insert(ingredient.id)
                }
            }
        } label: {
            HStack(spacing: 14) {
                // Checkbox
                RoundedRectangle(cornerRadius: 4)
                    .stroke(checkedIngredients.contains(ingredient.id) ? coralColor : Color.gray.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Group {
                            if checkedIngredients.contains(ingredient.id) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(coralColor)
                            }
                        }
                    )
                
                Text(ingredient.displayText)
                    .font(.system(size: 16))
                    .foregroundColor(checkedIngredients.contains(ingredient.id) ? .secondary : .primary)
                    .strikethrough(checkedIngredients.contains(ingredient.id), color: .secondary)
                
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
            VStack(spacing: 24) {
                ForEach(recipe.instructions) { step in
                    instructionRow(step)
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
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: MockRecipeData.recipes[0])
    }
}
