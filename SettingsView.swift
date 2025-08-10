//
//  SettingsView.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.id, ascending: true)],
        animation: .default)
    private var userProfiles: FetchedResults<UserProfile>
    
    @State private var showingOnboarding = false
    @State private var showingExportSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile & Goals Section
                Section("Profile & Goals") {
                    if let userProfile = userProfiles.first {
                        NavigationLink(destination: ProfileEditView(userProfile: userProfile)) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(userProfile.name ?? "")
                                        .font(.headline)
                                    Text("Goal: \((userProfile.goal ?? "").capitalized)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                    } else {
                        Button(action: {
                            showingOnboarding = true
                        }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Set up your profile")
                                        .font(.headline)
                                    Text("Add your goals and preferences")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // App Settings Section
                Section("App Settings") {
                    NavigationLink(destination: UnitsSettingsView()) {
                        HStack {
                            Image(systemName: "ruler.fill")
                                .foregroundColor(.green)
                            Text("Units")
                            Spacer()
                            Text(userProfiles.first?.unitSystem?.capitalized ?? "Metric")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Notifications")
                        }
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    Button(action: {
                        showingExportSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Export Data")
                        }
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Delete All Data")
                        }
                    }
                }
                
                // About Section
                Section("About") {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("About CalorieCam")
                        }
                    }
                    
                    NavigationLink(destination: PrivacyView()) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.green)
                            Text("Privacy Policy")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingOnboarding) {
                OnboardingView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView()
            }
            .alert("Delete All Data", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your meals, profile, and settings. This action cannot be undone.")
            }
        }
    }
    
    private func deleteAllData() {
        // Delete all meals
        let mealRequest: NSFetchRequest<NSFetchRequestResult> = Meal.fetchRequest()
        let mealDeleteRequest = NSBatchDeleteRequest(fetchRequest: mealRequest)
        
        // Delete all daily summaries
        let summaryRequest: NSFetchRequest<NSFetchRequestResult> = DailySummary.fetchRequest()
        let summaryDeleteRequest = NSBatchDeleteRequest(fetchRequest: summaryRequest)
        
        // Delete all streaks
        let streakRequest: NSFetchRequest<NSFetchRequestResult> = Streak.fetchRequest()
        let streakDeleteRequest = NSBatchDeleteRequest(fetchRequest: streakRequest)
        
        // Delete all analytics events
        let analyticsRequest: NSFetchRequest<NSFetchRequestResult> = AnalyticsEvent.fetchRequest()
        let analyticsDeleteRequest = NSBatchDeleteRequest(fetchRequest: analyticsRequest)
        
        // Delete all user profiles
        let profileRequest: NSFetchRequest<NSFetchRequestResult> = UserProfile.fetchRequest()
        let profileDeleteRequest = NSBatchDeleteRequest(fetchRequest: profileRequest)
        
        do {
            try viewContext.execute(mealDeleteRequest)
            try viewContext.execute(summaryDeleteRequest)
            try viewContext.execute(streakDeleteRequest)
            try viewContext.execute(analyticsDeleteRequest)
            try viewContext.execute(profileDeleteRequest)
            try viewContext.save()
        } catch {
            print("Error deleting data: \(error)")
        }
    }
}

struct ProfileEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var userProfile: UserProfile
    
    @State private var name: String
    @State private var age: String
    @State private var gender: String
    @State private var weight: String
    @State private var height: String
    @State private var goal: String
    @State private var calorieGoal: String
    @State private var unitSystem: String
    
    init(userProfile: UserProfile) {
        self._userProfile = State(initialValue: userProfile)
        self._name = State(initialValue: userProfile.name ?? "")
        self._age = State(initialValue: String(userProfile.age))
        self._gender = State(initialValue: userProfile.gender ?? "")
        self._weight = State(initialValue: String(userProfile.weightKg))
        self._height = State(initialValue: String(userProfile.heightCm))
        self._goal = State(initialValue: userProfile.goal ?? "maintain")
        self._calorieGoal = State(initialValue: String(userProfile.calorieGoal))
        self._unitSystem = State(initialValue: userProfile.unitSystem ?? "metric")
    }
    
    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
                
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("male")
                    Text("Female").tag("female")
                    Text("Other").tag("other")
                }
                
                TextField("Weight (kg)", text: $weight)
                    .keyboardType(.decimalPad)
                
                TextField("Height (cm)", text: $height)
                    .keyboardType(.decimalPad)
            }
            
            Section("Goals") {
                Picker("Goal", selection: $goal) {
                    Text("Lose Weight").tag("lose")
                    Text("Maintain Weight").tag("maintain")
                    Text("Gain Weight").tag("gain")
                }
                
                TextField("Daily Calorie Goal", text: $calorieGoal)
                    .keyboardType(.numberPad)
            }
            
            Section("Units") {
                Picker("Unit System", selection: $unitSystem) {
                    Text("Metric").tag("metric")
                    Text("Imperial").tag("imperial")
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveProfile()
                }
            }
        }
    }
    
    private func saveProfile() {
        userProfile.name = name
        userProfile.age = Int16(age) ?? 0
        userProfile.gender = gender
        userProfile.weightKg = Double(weight) ?? 0
        userProfile.heightCm = Double(height) ?? 0
        userProfile.goal = goal
        userProfile.calorieGoal = Double(calorieGoal) ?? 2000
        userProfile.unitSystem = unitSystem
        userProfile.updatedAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

struct UnitsSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.id, ascending: true)],
        animation: .default)
    private var userProfiles: FetchedResults<UserProfile>
    
    var body: some View {
        Form {
            Section {
                Picker("Unit System", selection: Binding(
                    get: { userProfiles.first?.unitSystem ?? "metric" },
                    set: { newValue in
                        if let userProfile = userProfiles.first {
                            userProfile.unitSystem = newValue
                            userProfile.updatedAt = Date()
                            try? viewContext.save()
                        }
                    }
                )) {
                    Text("Metric (kg, cm)").tag("metric")
                    Text("Imperial (lbs, in)").tag("imperial")
                }
            } footer: {
                Text("This affects how weights and measurements are displayed throughout the app.")
            }
        }
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationSettingsView: View {
    @State private var streakWarnings = true
    
    var body: some View {
        Form {
            Section {
                Toggle("Streak Warnings", isOn: $streakWarnings)
            } footer: {
                Text("Receive notifications when you're at risk of breaking your streaks.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("CalorieCam")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            Section("Features") {
                FeatureRow(icon: "camera.fill", title: "Photo-based logging", description: "Take photos of your meals for instant calorie estimation")
                FeatureRow(icon: "target", title: "Goal tracking", description: "Set and track your calorie and macro goals")
                FeatureRow(icon: "flame.fill", title: "Streaks", description: "Build healthy habits with logging and goal streaks")
                FeatureRow(icon: "chart.bar.fill", title: "Analytics", description: "View your progress with detailed analytics")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
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
        .padding(.vertical, 4)
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Group {
                    Text("Data Collection")
                        .font(.headline)
                    
                    Text("CalorieCam collects and stores your meal photos, nutrition data, and app usage information locally on your device. We do not share your personal data with third parties.")
                    
                    Text("Photo Usage")
                        .font(.headline)
                    
                    Text("Photos you take are used solely for calorie estimation and are stored locally on your device. They are not uploaded to external servers except for the AI calorie estimation service.")
                    
                    Text("Data Storage")
                        .font(.headline)
                    
                    Text("All your data is stored locally on your device using Core Data. You can export your data at any time or delete all data from the settings.")
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExportDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Export Data")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Export your meal data as a CSV file that you can open in Excel, Google Sheets, or any spreadsheet application.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: {
                    exportData()
                }) {
                    Text("Export CSV")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        // Implementation for CSV export
        // This would generate a CSV file with all meal data
        print("Exporting data...")
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
