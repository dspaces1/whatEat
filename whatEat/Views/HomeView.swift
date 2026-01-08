import SwiftUI

struct HomeView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var showProfile = false
    
    private let coralColor = Color(red: 0.96, green: 0.58, blue: 0.53)
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Divider gradient line
            LinearGradient(
                colors: [
                    coralColor.opacity(0.8),
                    coralColor.opacity(0.4),
                    coralColor.opacity(0.1)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 2)
            .padding(.horizontal, 16)
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(MealType.allCases) { mealType in
                        mealSection(for: mealType)
                    }
                }
                .padding(.bottom, 100) // Space for tab bar
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environment(authManager)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MY KITCHEN")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.5)
                    .foregroundColor(coralColor)
                
                Text("Cookbook")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Profile button
            Button {
                showProfile = true
            } label: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.85, blue: 0.82),
                                Color(red: 0.94, green: 0.78, blue: 0.74)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    // MARK: - Meal Section
    
    @ViewBuilder
    private func mealSection(for mealType: MealType) -> some View {
        let recipes = MockRecipeData.recipes(for: mealType)
        
        if !recipes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                // Section header with colored indicator
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(mealType.accentColor)
                        .frame(width: 4, height: 20)
                    
                    Text(mealType.displayName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                
                // Recipe cards
                VStack(spacing: 0) {
                    ForEach(recipes) { recipe in
                        VStack(spacing: 0) {
                            RecipeCardView(recipe: recipe)
                                .padding(.horizontal, 20)
                            
                            // Divider after each card
                            Divider()
                                .padding(.horizontal, 20)
                                .padding(.leading, 96) // Align with text, after image
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(AuthenticationManager())
}
