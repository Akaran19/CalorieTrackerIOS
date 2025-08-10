//
//  CalorieTrackerApp.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI

@main
struct CalorieTrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
