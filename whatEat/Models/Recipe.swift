import Foundation
import SwiftUI

enum MealType: String, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case dessert
    case other
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .dessert: return "Dessert"
        case .other: return "Other"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .breakfast: return Color(red: 0.96, green: 0.58, blue: 0.53) // Coral/salmon
        case .lunch: return Color(red: 0.56, green: 0.82, blue: 0.67)     // Soft green
        case .dinner: return Color(red: 0.96, green: 0.58, blue: 0.53)   // Coral/salmon
        case .dessert: return Color(red: 0.98, green: 0.82, blue: 0.52)  // Warm yellow/orange
        case .other: return Color(red: 0.84, green: 0.84, blue: 0.88)    // Soft gray
        }
    }

    init?(apiValue: String) {
        switch apiValue.lowercased() {
        case "breakfast":
            self = .breakfast
        case "lunch":
            self = .lunch
        case "dinner":
            self = .dinner
        case "dessert":
            self = .dessert
        case "other":
            self = .other
        default:
            return nil
        }
    }
}

struct Ingredient: Identifiable {
    let id: UUID
    let name: String
    let amount: String?
    let text: String?
    
    init(id: UUID = UUID(), name: String, amount: String? = nil, text: String? = nil) {
        self.id = id
        self.name = name
        self.amount = amount
        self.text = text
    }
    
    var displayText: String {
        if let text, !text.isEmpty {
            return text
        }
        if let amount, !amount.isEmpty {
            if name.isEmpty {
                return amount
            }
            return "\(amount) \(name)"
        }
        return name
    }
}

struct InstructionStep: Identifiable {
    let id: UUID
    let stepNumber: Int
    let title: String
    let description: String
    
    init(id: UUID = UUID(), stepNumber: Int, title: String, description: String) {
        self.id = id
        self.stepNumber = stepNumber
        self.title = title
        self.description = description
    }
}

struct Recipe: Identifiable {
    let id: String
    let name: String
    let mealType: MealType
    let prepTime: String
    let calories: Int?
    let imageURL: URL?
    let ingredients: [Ingredient]
    let instructions: [InstructionStep]
    
    var caloriesDisplay: String {
        if let calories {
            return "\(calories) kcal"
        }
        return "N/A kcal"
    }
}
