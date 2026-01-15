import SwiftUI

struct SavedRecipesView: View {
    let savedRecipes: [Recipe]
    
    private let coralColor = Color(red: 0.96, green: 0.58, blue: 0.53)
    private let softBackground = Color(red: 0.97, green: 0.97, blue: 0.99)
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                headerCard
                savedListSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 140) // breathing room for custom tab bar
        }
        .background(softBackground)
        .navigationBarHidden(true)
    }
    
    private var headerCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.91, blue: 0.93),
                            Color(red: 0.96, green: 0.96, blue: 0.99)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MY KITCHEN")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.3)
                            .foregroundColor(coralColor)
                        Text("Saved Recipes")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                    }
                    Spacer()
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.99, green: 0.86, blue: 0.80),
                                    Color(red: 0.94, green: 0.73, blue: 0.69)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                }
                
                Text("A quick glance at all the meals you are keeping handy.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black.opacity(0.45))
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var savedListSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pantry Essentials")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    Text("\(savedRecipes.count) recipes")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black.opacity(0.4))
                }
                Spacer()
                Text("Curated")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(coralColor.opacity(0.1))
                    .foregroundColor(coralColor)
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 16) {
                ForEach(savedRecipes) { recipe in
                    SavedRecipeRow(recipe: recipe)
                }
                
                AddRecipeUpsellCard()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
        )
    }
}

private struct SavedRecipeRow: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            RemoteImageView(
                url: recipe.imageURL,
                placeholderBackground: recipe.mealType.accentColor.opacity(0.15),
                placeholderIconColor: recipe.mealType.accentColor.opacity(0.8),
                placeholderIconFont: .system(size: 26)
            )
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)
                Text("Prep \(recipe.prepTime) • \(recipe.caloriesDisplay)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black.opacity(0.45))
                
                Text(recipe.mealType.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(recipe.mealType.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(recipe.mealType.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            Image(systemName: "square.and.pencil")
                .foregroundColor(.black.opacity(0.3))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }
}

private struct AddRecipeUpsellCard: View {
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                Text("Add New Recipe")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(red: 0.96, green: 0.58, blue: 0.53))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundColor(Color(red: 0.96, green: 0.58, blue: 0.53).opacity(0.6))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SavedRecipesView(savedRecipes: MockRecipeData.recipes)
}
