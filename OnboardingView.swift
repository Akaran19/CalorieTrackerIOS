//
//  OnboardingView.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI
import CoreData

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = ""
    @State private var gender = "male"
    @State private var weight = ""
    @State private var height = ""
    @State private var goal = "maintain"
    @State private var calorieGoal = ""
    @State private var unitSystem = "metric"
    @State private var notificationsEnabled = true
    
    private let steps = ["Welcome", "Profile", "Goals", "Preferences", "Review"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress Bar
                ProgressView(value: Double(currentStep + 1), total: Double(steps.count))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding()
                
                // Step Content
                TabView(selection: $currentStep) {
                    WelcomeStepView()
                        .tag(0)
                    
                    ProfileStepView(
                        name: $name,
                        age: $age,
                        gender: $gender,
                        weight: $weight,
                        height: $height
                    )
                    .tag(1)
                    
                    GoalsStepView(
                        goal: $goal,
                        calorieGoal: $calorieGoal
                    )
                    .tag(2)
                    
                    PreferencesStepView(
                        unitSystem: $unitSystem,
                        notificationsEnabled: $notificationsEnabled
                    )
                    .tag(3)
                    
                    ReviewStepView(
                        name: name,
                        age: age,
                        gender: gender,
                        weight: weight,
                        height: height,
                        goal: goal,
                        calorieGoal: calorieGoal,
                        unitSystem: unitSystem
                    )
                    .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation Buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Button(currentStep == steps.count - 1 ? "Get Started" : "Next") {
                        if currentStep == steps.count - 1 {
                            saveProfile()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
                }
                .padding()
            }
            .navigationTitle(steps[currentStep])
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return true
        case 1:
            return !name.isEmpty && !age.isEmpty && !weight.isEmpty && !height.isEmpty
        case 2:
            return !calorieGoal.isEmpty
        case 3:
            return true
        case 4:
            return true
        default:
            return false
        }
    }
    
    private func saveProfile() {
        let userProfile = UserProfile(context: viewContext)
        userProfile.id = UUID() // Required field
        userProfile.name = name // Required field with default value
        userProfile.age = Int16(age) ?? 0
        userProfile.gender = gender
        userProfile.weightKg = Double(weight) ?? 0
        userProfile.heightCm = Double(height) ?? 0
        userProfile.goal = goal // Required field with default value
        userProfile.calorieGoal = Double(calorieGoal) ?? 2000
        userProfile.unitSystem = unitSystem // Required field with default value
        userProfile.createdAt = Date() // Required field
        userProfile.updatedAt = Date() // Required field
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Welcome to CalorieCam")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Track your meals with photos and AI-powered calorie estimation. Build healthy habits and reach your nutrition goals.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                OnboardingFeatureRow(icon: "camera.fill", title: "Photo-based logging", description: "Take photos of your meals for instant calorie estimation")
                OnboardingFeatureRow(icon: "target", title: "Goal tracking", description: "Set and track your calorie and macro goals")
                OnboardingFeatureRow(icon: "flame.fill", title: "Streaks", description: "Build healthy habits with logging and goal streaks")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct ProfileStepView: View {
    @Binding var name: String
    @Binding var age: String
    @Binding var gender: String
    @Binding var weight: String
    @Binding var height: String
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Tell us about yourself")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                TextField("Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Age", text: $age)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                    Text("Other").tag("other")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                TextField("Weight (kg)", text: $weight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                
                TextField("Height (cm)", text: $height)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct GoalsStepView: View {
    @Binding var goal: String
    @Binding var calorieGoal: String
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Set your goals")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                Picker("Goal", selection: $goal) {
                    Text("Lose Weight").tag("lose")
                    Text("Maintain Weight").tag("maintain")
                    Text("Gain Weight").tag("gain")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                TextField("Daily Calorie Goal", text: $calorieGoal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                if !calorieGoal.isEmpty {
                    Text("This will be your daily calorie target. You can adjust it later in settings.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct PreferencesStepView: View {
    @Binding var unitSystem: String
    @Binding var notificationsEnabled: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unit System")
                        .font(.headline)
                    
                    Picker("Unit System", selection: $unitSystem) {
                        Text("Metric (kg, cm)").tag("metric")
                        Text("Imperial (lbs, in)").tag("imperial")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notifications")
                        .font(.headline)
                    
                    Toggle("Streak Warnings", isOn: $notificationsEnabled)
                        .padding(.vertical, 4)
                    
                    Text("Receive notifications when you're at risk of breaking your streaks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct ReviewStepView: View {
    let name: String
    let age: String
    let gender: String
    let weight: String
    let height: String
    let goal: String
    let calorieGoal: String
    let unitSystem: String
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Review your profile")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                ReviewRow(title: "Name", value: name)
                ReviewRow(title: "Age", value: "\(age) years")
                ReviewRow(title: "Gender", value: gender.capitalized)
                ReviewRow(title: "Weight", value: "\(weight) kg")
                ReviewRow(title: "Height", value: "\(height) cm")
                ReviewRow(title: "Goal", value: goal.capitalized)
                ReviewRow(title: "Daily Calorie Goal", value: "\(calorieGoal) calories")
                ReviewRow(title: "Unit System", value: unitSystem.capitalized)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Text("You can edit these settings anytime in the app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct ReviewRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct OnboardingFeatureRow: View {
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
    OnboardingView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
