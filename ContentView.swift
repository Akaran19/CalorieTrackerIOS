//
//  ContentView.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var lastRequestId: String? // Store the last generated request_id
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 60))
                
                Text("Calorie Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track your meals and nutrition")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                NavigationLink(destination: PhotoSubmissionView { requestId in
                    // Handle the generated request_id here
                    lastRequestId = requestId
                    print("Generated request_id from ContentView: \(requestId)")
                    // You can use this request_id for polling Google Sheets or other purposes
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Submit Photo")
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
                
                Spacer()
            }
            .padding()
            .navigationTitle("Home")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
