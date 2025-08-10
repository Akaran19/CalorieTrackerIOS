//
//  HomeView.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI
import CoreData
import UIKit

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Meal.timestamp, ascending: false)],
        predicate: NSPredicate(format: "timestamp >= %@", Calendar.current.startOfDay(for: Date()) as NSDate),
        animation: .default)
    private var todaysMeals: FetchedResults<Meal>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.id, ascending: true)],
        animation: .default)
    private var userProfiles: FetchedResults<UserProfile>
    
    @State private var showingAddMeal = false
    @State private var lastRequestId: String? // Store the last generated request_id
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily Progress Ring
                    DailyProgressRingView(meals: todaysMeals, userProfile: userProfiles.first)
                    
                    // Macro Pills
                    MacroPillsView(meals: todaysMeals, userProfile: userProfiles.first)
                    
                    // Today's Meals
                    TodaysMealsView(meals: todaysMeals)
                    
                    // Streak Badges
                    StreakBadgesView()
                    
                    // Add Meal CTA
                    AddMealCTAView(showingAddMeal: $showingAddMeal)
                }
                .padding()
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showingAddMeal) {
                PhotoSubmissionView { requestId in
                    // Handle the generated request_id here
                    lastRequestId = requestId
                    print("Generated request_id from HomeView: \(requestId)")
                    // You can use this request_id for polling Google Sheets or other purposes
                }
            }
        }
    }
}

struct DailyProgressRingView: View {
    let meals: FetchedResults<Meal>
    let userProfile: UserProfile?
    
    var totalCalories: Double {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    var calorieGoal: Double {
        userProfile?.calorieGoal ?? 2000.0
    }
    
    var progress: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(totalCalories / calorieGoal, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .green]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: progress)
                
                VStack {
                    Text("\(Int(totalCalories))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("of \(Int(calorieGoal))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 200, height: 200)
            
            Text("Daily Progress")
                .font(.headline)
        }
    }
}

struct MacroPillsView: View {
    let meals: FetchedResults<Meal>
    let userProfile: UserProfile?
    
    var totalProtein: Double {
        meals.reduce(0.0) { $0 + (($1.proteinG) ?? 0.0) }
    }
    
    var totalCarbs: Double {
        meals.reduce(0.0) { $0 + (($1.carbsG) ?? 0.0) }
    }
    
    var totalFat: Double {
        meals.reduce(0.0) { $0 + (($1.fatG) ?? 0.0) }
    }
    
    var proteinTarget: Double {
        guard let userProfile = userProfile, userProfile.weightKg > 0 else { return 0 }
        return userProfile.weightKg * 1.2 // 1.2g per kg
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macros")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                MacroPill(
                    title: "Protein",
                    value: totalProtein,
                    target: proteinTarget,
                    color: .blue,
                    unit: "g"
                )
                
                MacroPill(
                    title: "Carbs",
                    value: totalCarbs,
                    target: 250, // Default target
                    color: .green,
                    unit: "g"
                )
                
                MacroPill(
                    title: "Fat",
                    value: totalFat,
                    target: 65, // Default target
                    color: .orange,
                    unit: "g"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct MacroPill: View {
    let title: String
    let value: Double
    let target: Double
    let color: Color
    let unit: String
    
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(value / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text("\(Int(value))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(unit)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 60, height: 60)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TodaysMealsView: View {
    let meals: FetchedResults<Meal>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.headline)
                .padding(.horizontal)
            
            if meals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No meals logged today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Take a photo to log your first meal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(meals) { meal in
                            MealCardView(meal: meal)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct MealCardView: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let path = meal.thumbnailFilePath,
               let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 80)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.title ?? "Meal")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text("\(Int(meal.calories)) cal")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120)
    }
}

struct StreakBadgesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                StreakBadge(
                    title: "Logging",
                    count: 5,
                    color: .blue
                )
                
                StreakBadge(
                    title: "Goal",
                    count: 3,
                    color: .green
                )
            }
            .padding(.horizontal)
        }
    }
}

struct StreakBadge: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                VStack {
                    Text("\(count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("days")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AddMealCTAView: View {
    @Binding var showingAddMeal: Bool
    
    var body: some View {
        Button(action: {
            showingAddMeal = true
        }) {
            HStack {
                Image(systemName: "camera.fill")
                    .font(.title2)
                Text("Add Meal")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
