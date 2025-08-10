//
//  MealEditView.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI
import CoreData
import UIKit

struct MealEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var meal: Meal

    @State private var title: String
    @State private var notes: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fat: String

    init(meal: Meal) {
        self._meal = State(initialValue: meal)

        // Strings
        self._title = State(initialValue: (meal.value(forKey: "title") as? String) ?? "")
        self._notes = State(initialValue: (meal.value(forKey: "notes") as? String) ?? "")

        // Numbers (handle both Double and NSNumber, optional or not)
        func str(_ any: Any?) -> String {
            if let n = any as? NSNumber { return String(n.doubleValue) }
            if let d = any as? Double   { return String(d) }
            return ""
        }

        self._calories = State(initialValue: str(meal.value(forKey: "calories")))
        self._protein  = State(initialValue: str(meal.value(forKey: "proteinG")))
        self._carbs    = State(initialValue: str(meal.value(forKey: "carbsG")))
        self._fat      = State(initialValue: str(meal.value(forKey: "fatG")))
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Meal Details") {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical).lineLimit(3...6)
                }

                Section("Nutrition") {
                    TextField("Calories", text: $calories).keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $protein).keyboardType(.decimalPad)
                    TextField("Carbs (g)", text: $carbs).keyboardType(.decimalPad)
                    TextField("Fat (g)", text: $fat).keyboardType(.decimalPad)
                }

                Section("Image") {
                    if let path = (meal.value(forKey: "imageFilePath") as? String),
                       let image = UIImage(contentsOfFile: path) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveMeal() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                                  calories.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveMeal() {
        // Strings
        meal.setValue(title, forKey: "title")
        meal.setValue(notes.isEmpty ? nil : notes, forKey: "notes")

        // Numbers
        func dbl(_ s: String) -> Double? {
            Double(s.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        meal.setValue(dbl(calories) ?? 0, forKey: "calories")
        meal.setValue(dbl(protein), forKey: "proteinG")
        meal.setValue(dbl(carbs),   forKey: "carbsG")
        meal.setValue(dbl(fat),     forKey: "fatG")

        meal.setValue(true, forKey: "isEdited")

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving meal: \(error)")
        }
    }
}


#Preview {
    MealEditView(meal: Meal())
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
