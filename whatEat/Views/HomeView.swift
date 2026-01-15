import SwiftUI

struct HomeView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @State private var showProfile = false
    @State private var viewModel = HomeViewModel()
    
    private let coralColor = Color(red: 0.96, green: 0.58, blue: 0.53)
    
    var body: some View {
        NavigationStack {
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
                    LazyVStack(spacing: 0) {
                        if viewModel.isLoading && viewModel.isEmpty {
                            ProgressView()
                                .padding(.top, 40)
                        } else if viewModel.hasLoaded && viewModel.isEmpty {
                            emptyStateView
                        } else {
                            let mealTypes = MealType.allCases.filter { mealType in
                                mealType != .other || !viewModel.suggestions(for: .other).isEmpty
                            }

                            ForEach(mealTypes) { mealType in
                                mealSection(for: mealType, suggestions: viewModel.suggestions(for: mealType))
                            }
                        }
                    }
                    .padding(.bottom, 100) // Space for tab bar
                }
                .refreshable {
                    await viewModel.refreshSuggestions(authManager: authManager)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showProfile) {
                ProfileView()
                    .environment(authManager)
            }
            .task {
                await viewModel.loadDailySuggestions(authManager: authManager)
            }
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
    private func mealSection(
        for mealType: MealType,
        suggestions: [HomeViewModel.HomeSuggestion]
    ) -> some View {
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

            if suggestions.isEmpty {
                Text("No recipes available right now.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            } else {
                // Recipe cards
                LazyVStack(spacing: 0) {
                    ForEach(suggestions) { suggestion in
                        VStack(spacing: 0) {
                            NavigationLink(destination: RecipeDetailView(recipe: suggestion.recipe)) {
                                RecipeCardView(recipe: suggestion.recipe)
                                    .padding(.horizontal, 20)
                            }
                            .buttonStyle(.plain)

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

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("No recipes yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)

            Text("Check back later or refresh for a fresh set of ideas.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
        .padding(.horizontal, 24)
    }
}

#Preview {
    HomeView()
        .environment(AuthenticationManager())
}
