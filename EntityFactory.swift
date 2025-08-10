import CoreData
import Foundation

// Factory class to help create entities with default values
class EntityFactory {
    
    static let shared = EntityFactory()
    
    private init() {}
    
    // Create a new entity in the given context with default values
    func createEntity<T: NSManagedObject>(ofType type: T.Type, in context: NSManagedObjectContext) -> T {
        let entityName = String(describing: type)
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: context)!
        let object = T(entity: entity, insertInto: context)
        
        // Set default values based on entity type
        if let idAttribute = entity.attributesByName["id"], idAttribute.attributeType == .UUIDAttributeType {
            object.setValue(UUID(), forKey: "id")
        }
        
        let now = Date()
        
        // Set timestamp for entities that have it
        if entity.attributesByName["timestamp"] != nil {
            object.setValue(now, forKey: "timestamp")
        }
        
        // DailySummary specific
        if entityName == "DailySummary", entity.attributesByName["date"] != nil {
            object.setValue(now, forKey: "date")
        }
        
        // UserProfile specific
        if entityName == "UserProfile" {
            if entity.attributesByName["createdAt"] != nil {
                object.setValue(now, forKey: "createdAt")
            }
            if entity.attributesByName["updatedAt"] != nil {
                object.setValue(now, forKey: "updatedAt")
            }
        }
        
        return object
    }
}
