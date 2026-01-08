import Foundation

struct MockRecipeData {
    static let recipes: [Recipe] = [
        // Breakfast (1 item)
        Recipe(
            id: UUID(),
            name: "Potato & Herb Hash",
            mealType: .breakfast,
            prepTime: "25 min",
            calories: 320,
            imageName: "potato_hash"
        ),
        
        // Lunch (2 items)
        Recipe(
            id: UUID(),
            name: "Spicy Thai Chicken",
            mealType: .lunch,
            prepTime: "15 min",
            calories: 450,
            imageName: "thai_chicken"
        ),
        Recipe(
            id: UUID(),
            name: "Pan-Seared Salmon",
            mealType: .lunch,
            prepTime: "25 min",
            calories: 380,
            imageName: "salmon"
        ),
        
        // Dinner (2 items)
        Recipe(
            id: UUID(),
            name: "Mushroom Risotto",
            mealType: .dinner,
            prepTime: "40 min",
            calories: 520,
            imageName: "risotto"
        ),
        Recipe(
            id: UUID(),
            name: "Beef Wellington",
            mealType: .dinner,
            prepTime: "1h 10m",
            calories: 680,
            imageName: "beef_wellington"
        ),
        
        // Dessert (1 item)
        Recipe(
            id: UUID(),
            name: "Choco Lava Cake",
            mealType: .dessert,
            prepTime: "30 min",
            calories: 410,
            imageName: "lava_cake"
        )
    ]
    
    static func recipes(for mealType: MealType) -> [Recipe] {
        recipes.filter { $0.mealType == mealType }
    }
}
