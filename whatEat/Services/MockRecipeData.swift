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
            imageName: "potato_hash",
            ingredients: [
                Ingredient(name: "large potatoes, diced", amount: "2"),
                Ingredient(name: "tbsp olive oil", amount: "1"),
                Ingredient(name: "tsp dried rosemary", amount: "1"),
                Ingredient(name: "tsp paprika", amount: "1/2"),
                Ingredient(name: "Salt and pepper to taste"),
                Ingredient(name: "Fresh parsley for garnish")
            ],
            instructions: [
                InstructionStep(stepNumber: 1, title: "Prep the potatoes", description: "Wash and dice the potatoes into small cubes. Pat them dry with a paper towel to remove excess moisture."),
                InstructionStep(stepNumber: 2, title: "Season", description: "In a large bowl, toss the potato cubes with olive oil, rosemary, paprika, salt, and pepper until evenly coated."),
                InstructionStep(stepNumber: 3, title: "Cook", description: "Heat a skillet over medium heat. Add the potatoes and cook for 15–20 minutes, stirring occasionally, until golden brown and crispy."),
                InstructionStep(stepNumber: 4, title: "Serve", description: "Remove from heat, garnish with fresh parsley, and serve immediately while hot.")
            ]
        ),
        
        // Lunch (2 items)
        Recipe(
            id: UUID(),
            name: "Spicy Thai Chicken",
            mealType: .lunch,
            prepTime: "15 min",
            calories: 450,
            imageName: "thai_chicken",
            ingredients: [
                Ingredient(name: "chicken breast, sliced", amount: "1 lb"),
                Ingredient(name: "tbsp vegetable oil", amount: "2"),
                Ingredient(name: "tbsp Thai red curry paste", amount: "2"),
                Ingredient(name: "cup coconut milk", amount: "1"),
                Ingredient(name: "tbsp fish sauce", amount: "1"),
                Ingredient(name: "Fresh basil leaves"),
                Ingredient(name: "Red chili flakes to taste")
            ],
            instructions: [
                InstructionStep(stepNumber: 1, title: "Prep the chicken", description: "Slice the chicken breast into thin strips. Season lightly with salt."),
                InstructionStep(stepNumber: 2, title: "Sear the chicken", description: "Heat oil in a wok over high heat. Add chicken and cook for 3-4 minutes until golden."),
                InstructionStep(stepNumber: 3, title: "Add curry", description: "Stir in the curry paste and cook for 30 seconds until fragrant. Pour in coconut milk and fish sauce."),
                InstructionStep(stepNumber: 4, title: "Simmer and serve", description: "Simmer for 5 minutes until sauce thickens. Garnish with fresh basil and chili flakes.")
            ]
        ),
        Recipe(
            id: UUID(),
            name: "Pan-Seared Salmon",
            mealType: .lunch,
            prepTime: "25 min",
            calories: 380,
            imageName: "salmon",
            ingredients: [
                Ingredient(name: "salmon fillets", amount: "2"),
                Ingredient(name: "tbsp olive oil", amount: "2"),
                Ingredient(name: "tbsp butter", amount: "1"),
                Ingredient(name: "cloves garlic, minced", amount: "2"),
                Ingredient(name: "Lemon wedges"),
                Ingredient(name: "Fresh dill for garnish"),
                Ingredient(name: "Salt and pepper to taste")
            ],
            instructions: [
                InstructionStep(stepNumber: 1, title: "Season the salmon", description: "Pat salmon dry and season generously with salt and pepper on both sides."),
                InstructionStep(stepNumber: 2, title: "Heat the pan", description: "Heat olive oil in a skillet over medium-high heat until shimmering."),
                InstructionStep(stepNumber: 3, title: "Sear the salmon", description: "Place salmon skin-side up, cook 4 minutes. Flip and cook 3 more minutes. Add butter and garlic in the last minute."),
                InstructionStep(stepNumber: 4, title: "Serve", description: "Transfer to plates, spoon garlic butter over top, and garnish with fresh dill and lemon wedges.")
            ]
        ),
        
        // Dinner (2 items)
        Recipe(
            id: UUID(),
            name: "Mushroom Risotto",
            mealType: .dinner,
            prepTime: "40 min",
            calories: 520,
            imageName: "risotto",
            ingredients: [
                Ingredient(name: "cups arborio rice", amount: "1.5"),
                Ingredient(name: "cups mixed mushrooms, sliced", amount: "2"),
                Ingredient(name: "cups warm chicken stock", amount: "4"),
                Ingredient(name: "cup dry white wine", amount: "1/2"),
                Ingredient(name: "cup parmesan, grated", amount: "1/2"),
                Ingredient(name: "tbsp butter", amount: "3"),
                Ingredient(name: "shallot, finely diced", amount: "1"),
                Ingredient(name: "Fresh thyme")
            ],
            instructions: [
                InstructionStep(stepNumber: 1, title: "Sauté mushrooms", description: "Melt 1 tbsp butter, cook mushrooms until golden (5-6 min). Set aside."),
                InstructionStep(stepNumber: 2, title: "Toast the rice", description: "Sauté shallot in remaining butter until soft. Add rice and toast for 2 minutes until edges are translucent."),
                InstructionStep(stepNumber: 3, title: "Build the risotto", description: "Add wine and stir until absorbed. Add stock one ladle at a time, stirring constantly, waiting until absorbed before adding more."),
                InstructionStep(stepNumber: 4, title: "Finish and serve", description: "Stir in mushrooms, parmesan, and thyme. Season to taste and serve immediately.")
            ]
        ),
        Recipe(
            id: UUID(),
            name: "Beef Wellington",
            mealType: .dinner,
            prepTime: "1h 10m",
            calories: 680,
            imageName: "beef_wellington",
            ingredients: [
                Ingredient(name: "lb beef tenderloin", amount: "2"),
                Ingredient(name: "sheets puff pastry", amount: "2"),
                Ingredient(name: "cups mushroom duxelles", amount: "1.5"),
                Ingredient(name: "slices prosciutto", amount: "8"),
                Ingredient(name: "tbsp Dijon mustard", amount: "2"),
                Ingredient(name: "egg, beaten", amount: "1"),
                Ingredient(name: "Salt and pepper to taste")
            ],
            instructions: [
                InstructionStep(stepNumber: 1, title: "Sear the beef", description: "Season beef and sear in a hot pan on all sides until browned. Brush with Dijon mustard and let cool."),
                InstructionStep(stepNumber: 2, title: "Wrap in prosciutto", description: "Layer prosciutto on plastic wrap, spread mushroom duxelles, place beef and roll tightly. Chill for 30 minutes."),
                InstructionStep(stepNumber: 3, title: "Wrap in pastry", description: "Roll out puff pastry, wrap the beef roll, seal edges with egg wash. Score the top decoratively."),
                InstructionStep(stepNumber: 4, title: "Bake and rest", description: "Bake at 425°F for 25-30 minutes until golden. Rest 10 minutes before slicing.")
            ]
        ),
        
        // Dessert (1 item)
        Recipe(
            id: UUID(),
            name: "Choco Lava Cake",
            mealType: .dessert,
            prepTime: "30 min",
            calories: 410,
            imageName: "lava_cake",
            ingredients: [
                Ingredient(name: "oz dark chocolate", amount: "4"),
                Ingredient(name: "tbsp butter", amount: "4"),
                Ingredient(name: "eggs", amount: "2"),
                Ingredient(name: "egg yolks", amount: "2"),
                Ingredient(name: "cup powdered sugar", amount: "1/4"),
                Ingredient(name: "tbsp flour", amount: "2"),
                Ingredient(name: "Vanilla ice cream for serving")
            ],
            instructions: [
                InstructionStep(stepNumber: 1, title: "Melt chocolate", description: "Melt chocolate and butter together in a double boiler or microwave. Stir until smooth and let cool slightly."),
                InstructionStep(stepNumber: 2, title: "Mix the batter", description: "Whisk eggs, yolks, and sugar until thick. Fold in the chocolate mixture, then gently fold in flour."),
                InstructionStep(stepNumber: 3, title: "Prepare ramekins", description: "Butter and flour 4 ramekins. Divide batter evenly among them."),
                InstructionStep(stepNumber: 4, title: "Bake and serve", description: "Bake at 425°F for 12-14 minutes. Edges should be firm, center soft. Invert onto plates and serve with ice cream.")
            ]
        )
    ]
    
    static func recipes(for mealType: MealType) -> [Recipe] {
        recipes.filter { $0.mealType == mealType }
    }
}
