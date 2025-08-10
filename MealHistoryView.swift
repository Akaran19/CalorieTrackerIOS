import SwiftUI
import CoreData
import UIKit

struct MealHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var selectedDateRange: DateRange = .allTime
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            VStack {
                SearchFilterBar(
                    searchText: $searchText,
                    selectedDateRange: $selectedDateRange,
                    showingDatePicker: $showingDatePicker
                )
                MealListView(searchText: searchText, dateRange: selectedDateRange)
            }
            .navigationTitle("Meal Log")
            .sheet(isPresented: $showingDatePicker) {
                DateRangePickerView(selectedRange: $selectedDateRange)
            }
        }
    }
}

struct SearchFilterBar: View {
    @Binding var searchText: String
    @Binding var selectedDateRange: DateRange
    @Binding var showingDatePicker: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Search meals...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            HStack {
                Button { showingDatePicker = true } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text(selectedDateRange.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct MealListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let searchText: String
    let dateRange: DateRange
    
    var body: some View {
        List {
            ForEach(filteredMeals) { meal in
                NavigationLink(destination: MealDetailView(meal: meal)) {
                    MealRowView(meal: meal)
                }
            }
            .onDelete(perform: deleteMeals)
        }
        .listStyle(PlainListStyle())
    }
    
    private var filteredMeals: [Meal] {
        let request: NSFetchRequest<Meal> = Meal.fetchRequest()
        var predicates: [NSPredicate] = []
        
        if let datePredicate = dateRange.predicate { predicates.append(datePredicate) }
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@ OR notes CONTAINS[cd] %@", searchText, searchText))
        }
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.timestamp, ascending: false)]
        
        do { return try viewContext.fetch(request) }
        catch {
            print("Error fetching meals: \(error)")
            return []
        }
    }
    
    private func deleteMeals(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredMeals[$0] }.forEach(viewContext.delete)
            do { try viewContext.save() } catch { print("Error deleting meal: \(error)") }
        }
    }
}

struct MealRowView: View {
    let meal: Meal
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            if let path = meal.value(forKey: "thumbnailFilePath") as? String,
               let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                let title = (meal.value(forKey: "title") as? String) ?? "Meal"
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                
                if let notes = meal.value(forKey: "notes") as? String, !notes.isEmpty {
                    Text(notes).font(.caption).foregroundColor(.secondary).lineLimit(1)
                }
                
                if let ts = meal.value(forKey: "timestamp") as? Date {
                    Text(ts, style: .date).font(.caption2).foregroundColor(.secondary)
                } else {
                    Text("No date").font(.caption2).foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int((meal.value(forKey: "calories") as? NSNumber)?.doubleValue ?? meal.calories))")
                    .font(.title2).fontWeight(.bold)
                Text("cal").font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MealDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var meal: Meal
    @State private var isEditing = false
    
    init(meal: Meal) { self._meal = State(initialValue: meal) }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let path = meal.value(forKey: "imageFilePath") as? String,
                   let image = UIImage(contentsOfFile: path) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    let title = (meal.value(forKey: "title") as? String) ?? "Meal"
                    Text(title).font(.title2).fontWeight(.bold)
                    
                    if let notes = meal.value(forKey: "notes") as? String, !notes.isEmpty {
                        Text(notes).font(.body).foregroundColor(.secondary)
                    }
                    
                    NutritionInfoView(meal: meal)
                    
                    if let ts = meal.value(forKey: "timestamp") as? Date {
                        HStack {
                            Image(systemName: "clock")
                            Text(ts, style: .date)
                            Text(ts, style: .time)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Meal Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) { MealEditView(meal: meal) }
    }
}

struct NutritionInfoView: View {
    let meal: Meal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition").font(.headline)
            HStack(spacing: 20) {
                NutritionItem(title: "Calories",
                              value: (meal.value(forKey: "calories") as? NSNumber)?.doubleValue ?? meal.calories,
                              unit: "cal",
                              color: .blue)
                
                if let n = meal.value(forKey: "proteinG") as? NSNumber {
                    NutritionItem(title: "Protein", value: n.doubleValue, unit: "g", color: .green)
                }
                if let n = meal.value(forKey: "carbsG") as? NSNumber {
                    NutritionItem(title: "Carbs", value: n.doubleValue, unit: "g", color: .orange)
                }
                if let n = meal.value(forKey: "fatG") as? NSNumber {
                    NutritionItem(title: "Fat", value: n.doubleValue, unit: "g", color: .red)
                }
            }
        }
    }
}

struct NutritionItem: View {
    let title: String
    let value: Double
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value))").font(.title3).fontWeight(.bold).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(unit).font(.caption2).foregroundColor(.secondary)
        }
    }
}

enum DateRange: CaseIterable {
    case today, yesterday, last7Days, last30Days, allTime
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .yesterday: return "Yesterday"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .allTime: return "All Time"
        }
    }
    
    var predicate: NSPredicate? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        case .yesterday:
            let start = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))!
            let end = calendar.startOfDay(for: now)
            return NSPredicate(format: "timestamp >= %@ AND timestamp < %@", start as NSDate, end as NSDate)
        case .last7Days:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return NSPredicate(format: "timestamp >= %@", start as NSDate)
        case .last30Days:
            let start = calendar.date(byAdding: .day, value: -30, to: now)!
            return NSPredicate(format: "timestamp >= %@", start as NSDate)
        case .allTime:
            return nil
        }
    }
}

struct DateRangePickerView: View {
    @Binding var selectedRange: DateRange
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(DateRange.allCases, id: \.self) { range in
                    Button {
                        selectedRange = range
                        dismiss()
                    } label: {
                        HStack {
                            Text(range.displayName)
                            Spacer()
                            if selectedRange == range { Image(systemName: "checkmark").foregroundColor(.blue) }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

#Preview {
    MealHistoryView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
