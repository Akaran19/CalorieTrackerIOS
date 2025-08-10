//
//  StreaksView.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI
import CoreData

struct StreaksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Streak.type, ascending: true)],
        animation: .default)
    private var streaks: FetchedResults<Streak>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(streaks) { streak in
                            StreakCardView(streak: streak)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Streak History
                    StreakHistoryView()
                    
                    // Motivation Section
                    MotivationView()
                }
                .padding(.vertical)
            }
            .navigationTitle("Streaks")
            .onAppear {
                updateStreaks()
            }
        }
    }
    
    private func updateStreaks() {
        // This would be called by the StreakEngine service
        // For now, we'll just ensure streaks exist
        ensureStreaksExist()
    }
    
    private func ensureStreaksExist() {
        let loggingStreak = streaks.first { $0.type == "logging" }
        let goalStreak = streaks.first { $0.type == "goal" }
        
        if loggingStreak == nil {
            let newLoggingStreak = Streak(context: viewContext)
            newLoggingStreak.id = UUID() // Required field
            newLoggingStreak.type = "logging" // Required field with default value
            newLoggingStreak.currentCount = 0
            newLoggingStreak.longestCount = 0
            newLoggingStreak.lastDateCounted = nil // Optional field
        }
        
        if goalStreak == nil {
            let newGoalStreak = Streak(context: viewContext)
            newGoalStreak.id = UUID() // Required field
            newGoalStreak.type = "goal" // Required field with default value
            newGoalStreak.currentCount = 0
            newGoalStreak.longestCount = 0
            newGoalStreak.lastDateCounted = nil // Optional field
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving streaks: \(error)")
        }
    }
}

struct StreakCardView: View {
    let streak: Streak
    
    var body: some View {
        VStack(spacing: 16) {
            // Streak Icon
            ZStack {
                Circle()
                    .fill(streakColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: streakIcon)
                    .font(.system(size: 32))
                    .foregroundColor(streakColor)
            }
            
            // Streak Info
            VStack(spacing: 8) {
                Text(streakTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(streak.currentCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(streakColor)
                
                Text("days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if streak.longestCount > 0 {
                    Text("Best: \(streak.longestCount) days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var streakTitle: String {
        switch streak.type {
        case "logging":
            return "Logging Streak"
        case "goal":
            return "Goal Streak"
        default:
            return "Streak"
        }
    }
    
    private var streakIcon: String {
        switch streak.type {
        case "logging":
            return "camera.fill"
        case "goal":
            return "target"
        default:
            return "flame.fill"
        }
    }
    
    private var streakColor: Color {
        switch streak.type {
        case "logging":
            return .blue
        case "goal":
            return .green
        default:
            return .orange
        }
    }
}

struct StreakHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DailySummary.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@", Calendar.current.date(byAdding: .day, value: -30, to: Date())! as NSDate),
        animation: .default)
    private var recentSummaries: FetchedResults<DailySummary>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(recentSummaries.prefix(7)) { summary in
                        DayStreakIndicator(summary: summary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct DayStreakIndicator: View {
    let summary: DailySummary
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(dayColor)
                .frame(width: 20, height: 20)
            
            Text(dayLabel)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var dayColor: Color {
        if summary.hitCalorieGoal && summary.hitProteinGoal {
            return .green
        } else if summary.totalCalories > 0 {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private static let weekdayFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "E"
    return f
}()

private var dayLabel: String {
    if let date = (summary.value(forKey: "date") as? Date) {
        return Self.weekdayFormatter.string(from: date)
    }
    return "—" // or "", or "N/A"
}
}

struct MotivationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Keep Going!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Every day you log a meal and hit your goals, you're building healthy habits that last a lifetime.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Motivation Tips
            VStack(alignment: .leading, spacing: 12) {
                MotivationTip(
                    icon: "camera.fill",
                    title: "Log Every Meal",
                    description: "Take photos of your meals to build a visual food diary"
                )
                
                MotivationTip(
                    icon: "target",
                    title: "Hit Your Goals",
                    description: "Stay within your calorie target and protein goals"
                )
                
                MotivationTip(
                    icon: "flame.fill",
                    title: "Build Streaks",
                    description: "Consistency is key - every day counts!"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

struct MotivationTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    StreaksView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
