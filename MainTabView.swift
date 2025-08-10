//
//  MainTabView.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var lastRequestId: String? // Store the last generated request_id
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            MealHistoryView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Log")
                }
                .tag(1)
            
            PhotoSubmissionView { requestId in
                // Handle the generated request_id here
                lastRequestId = requestId
                print("Generated request_id: \(requestId)")
                // You can use this request_id for polling Google Sheets or other purposes
            }
            .tabItem {
                Image(systemName: "camera.fill")
                Text("Add")
            }
            .tag(2)
            
            StreaksView()
                .tabItem {
                    Image(systemName: "flame.fill")
                    Text("Streaks")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
