import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.gray.opacity(0.5))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(recipe.prepTime) • \(recipe.caloriesDisplay)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RecipeCardView(recipe: MockRecipeData.recipes[0])
        .padding()
}
