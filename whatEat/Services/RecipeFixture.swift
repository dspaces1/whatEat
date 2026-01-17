#if DEBUG
import Foundation

struct RecipeFixture {
    static let dailySuggestionsJSON = """
    {
      "suggestions": {
        "breakfast": [
          {
            "generated_at": "2026-01-13T21:08:23.265746+00:00",
            "id": "c0aa85ef-2b17-49fd-bf60-8e716e556518",
            "rank": 1,
            "recipe_data": {
              "id": "7b402848-2d5c-4cc2-bfcb-c7d7eadd1829",
              "title": "Emerald Shakshuka with Lemon Labneh & Toasted Seeds",
              "calories": 530,
              "prep_time_minutes": 10,
              "cook_time_minutes": 15,
              "ingredients": [
                { "raw_text": "1 tbsp olive oil" },
                { "raw_text": "1 small onion, thinly sliced" },
                { "raw_text": "2 cloves garlic, minced" },
                { "raw_text": "1 tsp ground cumin" },
                { "raw_text": "1/2 tsp smoked paprika" },
                { "raw_text": "4 cups fresh spinach (packed) or 10 oz baby spinach" },
                { "raw_text": "1 cup frozen peas, thawed" },
                { "raw_text": "4 large eggs" },
                { "raw_text": "1/2 cup labneh or thick Greek yogurt" },
                { "raw_text": "Zest and 1 tbsp lemon juice" },
                { "raw_text": "2 tbsp toasted pumpkin seeds (pepitas) or chopped pistachios" },
                { "raw_text": "Salt and black pepper to taste" },
                { "raw_text": "4 slices whole-grain bread or gluten-free toast (optional)" }
              ],
              "steps": [
                {
                  "instruction": "Heat the olive oil in a 10-inch skillet over medium heat. Add the sliced\\nonion and cook, stirring occasionally, until soft and translucent, about 5 minutes. Add the garlic, cumin, and smoked paprika and cook 30 seconds until fragrant."
                },
                {
                  "instruction": "Add the spinach and cook, stirring, until wilted (2-3 minutes). Stir in\\nthe thawed peas and season generously with salt and pepper. If mixture seems dry, splash 1-2 tablespoons water to help everything meld."
                },
                {
                  "instruction": "Use the back of a spoon to make four small wells in the greens. Crack an\\negg into each well. Reduce heat to medium-low, cover the skillet, and cook until egg whites are set but yolks are still runny, 6-8 minutes (cook longer for firmer yolks)."
                },
                {
                  "instruction": "While eggs cook, stir the labneh (or Greek yogurt) with lemon zest,\\nlemon juice, and a pinch of salt in a small bowl. Toast pumpkin seeds in a dry skillet over medium heat for 1-2 minutes until fragrant, or skip if already toasted."
                },
                {
                  "instruction": "Toast the bread if using. When eggs are done, remove the skillet from\\nheat. Dollop the lemon labneh around the skillet, sprinkle the toasted seeds over the top, and crack a little extra black pepper."
                },
                {
                  "instruction": "Serve straight from the pan with toast for scooping, or enjoy on its own. For a gluten-free option, omit the bread and serve with extra seeds and lemon wedges."
                }
              ],
              "metadata": {
                "meal_type": "breakfast"
              }
            }
          }
        ]
      }
    }
    """

    static func loadDailySuggestions() throws -> DailySuggestionsResponse {
        let data = Data(dailySuggestionsJSON.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(DailySuggestionsResponse.self, from: data)
    }
}
#endif
