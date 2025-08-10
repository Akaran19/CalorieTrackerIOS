//
//  StreakEngine.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import Foundation
import CoreData

class StreakEngine: ObservableObject {
    static let shared = StreakEngine()
    
    private init() {}
    
    func updateStreaks(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        
        // Get or create streaks
        let loggingStreak = getOrCreateStreak(type: "logging", context: context)
        let goalStreak = getOrCreateStreak(type: "goal", context: context)
        
        // Check if we already counted today
        if let lastDate = loggingStreak.lastDateCounted,
           calendar.isDate(lastDate, inSameDayAs: today) {
            return // Already counted today
        }
        
        // Check logging streak
        let hasLoggedToday = hasLoggedMealToday(context: context)
        if hasLoggedToday {
            if let lastDate = loggingStreak.lastDateCounted,
               calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
                // Consecutive day
                loggingStreak.currentCount += 1
            } else {
                // New streak or gap
                loggingStreak.currentCount = 1
            }
            loggingStreak.lastDateCounted = startOfToday
            
            if loggingStreak.currentCount > loggingStreak.longestCount {
                loggingStreak.longestCount = loggingStreak.currentCount
            }
        }
        
        // Check goal streak
        let hitGoalToday = hasHitGoalToday(context: context)
        if hitGoalToday {
            if let lastDate = goalStreak.lastDateCounted,
               calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)!) {
                // Consecutive day
                goalStreak.currentCount += 1
            } else {
                // New streak or gap
                goalStreak.currentCount = 1
            }
            goalStreak.lastDateCounted = startOfToday
            
            if goalStreak.currentCount > goalStreak.longestCount {
                goalStreak.longestCount = goalStreak.currentCount
            }
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving streaks: \(error)")
        }
    }
    
    private func getOrCreateStreak(type: String, context: NSManagedObjectContext) -> Streak {
        let request: NSFetchRequest<Streak> = Streak.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", type)
        request.fetchLimit = 1
        
        do {
            if let existingStreak = try context.fetch(request).first {
                return existingStreak
            } else {
                let newStreak = Streak(context: context)
                newStreak.id = UUID() // Required field
                newStreak.type = type // Required field with default value
                newStreak.currentCount = 0
                newStreak.longestCount = 0
                newStreak.lastDateCounted = nil // Optional field
                return newStreak
            }
        } catch {
            print("Error fetching streak: \(error)")
            let newStreak = Streak(context: context)
            newStreak.id = UUID() // Required field
            newStreak.type = type // Required field with default value
            newStreak.currentCount = 0
            newStreak.longestCount = 0
            newStreak.lastDateCounted = nil // Optional field
            return newStreak
        }
    }
    
    private func hasLoggedMealToday(context: NSManagedObjectContext) -> Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfToday as NSDate, endOfToday as NSDate)
        request.fetchLimit = 1
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking meals today: \(error)")
            return false
        }
    }
    
    private func hasHitGoalToday(context: NSManagedObjectContext) -> Bool {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        let request: NSFetchRequest<DailySummary> = DailySummary.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfToday as NSDate, endOfToday as NSDate)
        request.fetchLimit = 1
        
        do {
            if let summary = try context.fetch(request).first {
                return summary.hitCalorieGoal && summary.hitProteinGoal
            }
            return false
        } catch {
            print("Error checking daily summary: \(error)")
            return false
        }
    }
    
    func calculateDailySummary(for date: Date, context: NSManagedObjectContext) -> DailySummary? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        request.predicate = NSPredicate(format: "timestamp >= %@ AND timestamp < %@", startOfDay as NSDate, endOfDay as NSDate)
        
        do {
            let meals = try context.fetch(request)
            
            let totalCalories = meals.reduce(0.0) { $0 + $1.calories }
            let totalProtein = meals.reduce(0.0) { $0 + ($1.proteinG ?? 0.0) }
            let totalCarbs   = meals.reduce(0.0) { $0 + ($1.carbsG ?? 0.0) }
            let totalFat     = meals.reduce(0.0) { $0 + ($1.fatG ?? 0.0) }

            // Get user profile for goals
            let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            let userProfile = try context.fetch(profileRequest).first

            let calorieGoal = userProfile?.calorieGoal ?? 2000.0
            let proteinTarget = (userProfile?.weightKg ?? 70.0) * 1.2 // 1.2g per kg

            let hitCalorieGoal = totalCalories <= calorieGoal
            let hitProteinGoal = totalProtein >= proteinTarget
            
            // Check if summary already exists
            let summaryRequest: NSFetchRequest<DailySummary> = DailySummary.fetchRequest()
            summaryRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
            
            let existingSummary = try context.fetch(summaryRequest).first
            
            if let summary = existingSummary {
                summary.totalCalories = totalCalories
                summary.proteinG = totalProtein
                summary.carbsG = totalCarbs
                summary.fatG = totalFat
                summary.calorieGoal = calorieGoal
                summary.proteinTargetG = proteinTarget
                summary.hitCalorieGoal = hitCalorieGoal
                summary.hitProteinGoal = hitProteinGoal
                return summary
            } else {
                let summary = DailySummary(context: context)
                summary.id = UUID() // Required field
                summary.date = startOfDay // Required field
                summary.totalCalories = totalCalories
                summary.proteinG = totalProtein
                summary.carbsG = totalCarbs
                summary.fatG = totalFat
                summary.calorieGoal = calorieGoal
                summary.proteinTargetG = proteinTarget
                summary.hitCalorieGoal = hitCalorieGoal
                summary.hitProteinGoal = hitProteinGoal
                return summary
            }
        } catch {
            print("Error calculating daily summary: \(error)")
            return nil
        }
    }
}
