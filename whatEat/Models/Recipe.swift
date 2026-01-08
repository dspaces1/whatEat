import Foundation
import SwiftUI

enum MealType: String, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case dessert
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .dessert: return "Dessert"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .breakfast: return Color(red: 0.96, green: 0.58, blue: 0.53) // Coral/salmon
        case .lunch: return Color(red: 0.56, green: 0.82, blue: 0.67)     // Soft green
        case .dinner: return Color(red: 0.96, green: 0.58, blue: 0.53)   // Coral/salmon
        case .dessert: return Color(red: 0.98, green: 0.82, blue: 0.52)  // Warm yellow/orange
        }
    }
}

struct Recipe: Identifiable {
    let id: UUID
    let name: String
    let mealType: MealType
    let prepTime: String
    let calories: Int
    let imageName: String
    
    var caloriesDisplay: String {
        "\(calories) kcal"
    }
}
