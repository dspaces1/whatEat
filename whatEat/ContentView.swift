import SwiftUI

struct ContentView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var selectedTab: AppTab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView()
                    .environment(authManager)
            }
            
            Tab("Import", systemImage: "square.and.arrow.down.on.square.fill", value: .importRecipe) {
                ImportRecipePlaceholderView()
            }
            
            Tab("Saved", systemImage: "heart.fill", value: .saved) {
                SavedRecipesView(savedRecipes: MockRecipeData.recipes)
            }
        }
    }
}

enum AppTab: Hashable {
    case home
    case importRecipe
    case saved
}

#Preview {
    ContentView()
        .environment(AuthenticationManager())
}
