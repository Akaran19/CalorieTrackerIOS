import CoreData
import Foundation

// Helper extension to initialize Core Data entities with proper values
extension NSManagedObject {
    
    /// Call this method after creating a new Core Data entity to ensure proper initialization
    func initializeRequiredFields() {
        let now = Date()
        
        // Handle common ID field
        if let entity = self.entity.attributesByName["id"], 
           entity.attributeType == .UUIDAttributeType,
           self.value(forKey: "id") == nil {
            self.setValue(UUID(), forKey: "id")
        }
        
        // Entity-specific initializations
        switch self.entity.name {
        case "AnalyticsEvent":
            if self.value(forKey: "timestamp") == nil {
                self.setValue(now, forKey: "timestamp")
            }
            
        case "DailySummary":
            if self.value(forKey: "date") == nil {
                self.setValue(now, forKey: "date")
            }
            
        case "Meal":
            if self.value(forKey: "timestamp") == nil {
                self.setValue(now, forKey: "timestamp")
            }
            
        case "UserProfile":
            if self.value(forKey: "createdAt") == nil {
                self.setValue(now, forKey: "createdAt")
            }
            if self.value(forKey: "updatedAt") == nil {
                self.setValue(now, forKey: "updatedAt")
            }
            
        default:
            break
        }
    }
}

// Usage example:
/*
let context = PersistenceController.shared.container.viewContext
let meal = Meal(context: context)
meal.initializeRequiredFields()  // This sets id, timestamp, etc.
meal.title = "Lunch"
meal.calories = 500
// Save context
*/
