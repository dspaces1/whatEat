import SwiftUI

struct RecipeCardView: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 16) {
            RemoteImageView(url: recipe.imageURL)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
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
