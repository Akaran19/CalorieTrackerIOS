//
//  PhotoSubmissionView.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import SwiftUI
import CoreData
import UIKit

struct PhotoSubmissionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedImage: UIImage?
    @State private var contextText: String = ""
    @State private var isShowingImagePicker = false
    @State private var isShowingCamera = false
    @State private var isSubmitting = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isSuccess = false
    @State private var requestId: String? // Store the generated request_id for later access
    
    // Completion handler to return the request_id to parent views
    var onRequestIdGenerated: ((String) -> Void)?
    
    // Default initializer
    init(onRequestIdGenerated: ((String) -> Void)? = nil) {
        self.onRequestIdGenerated = onRequestIdGenerated
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Image display area
            VStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No photo selected")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                            }
                        )
                }
            }
            .padding(.horizontal)
            
            // Photo selection buttons
            HStack(spacing: 20) {
                Button(action: {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        isShowingCamera = true
                    } else {
                        showAlert(title: "Error", message: "Camera is not available on this device", isSuccess: false)
                    }
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .accessibilityLabel("Take Photo")
                
                Button(action: {
                    if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                        isShowingImagePicker = true
                    } else {
                        showAlert(title: "Error", message: "Photo library is not available on this device", isSuccess: false)
                    }
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Choose Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .accessibilityLabel("Choose Photo")
            }
            .padding(.horizontal)
            
            // Context text input
            VStack(alignment: .leading) {
                Text("Context")
                    .font(.headline)
                    .padding(.horizontal)
                
                TextEditor(text: $contextText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .accessibilityLabel("Context text input")
                
                HStack {
                    Spacer()
                    Text("\(contextText.count) characters")
                        .font(.caption)
                        .foregroundColor(contextText.count >= 3 ? .green : .red)
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Submit button
            Button(action: submitPhoto) {
                HStack {
                    if isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(isSubmitting ? "Submitting..." : "Submit Photo")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!isFormValid || isSubmitting)
            .padding(.horizontal)
            .padding(.bottom)
            .accessibilityLabel("Submit Photo")
            .accessibilityHint(isFormValid ? "Submit photo and context" : "Please select a photo and enter context first")
        }
        .navigationTitle("Photo Submission")
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if isSuccess {
                    clearForm()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        let trimmedContext = contextText.trimmingCharacters(in: .whitespacesAndNewlines)
        return selectedImage != nil && !trimmedContext.isEmpty && trimmedContext.count >= 3
    }
    
    private func submitPhoto() {
        guard let image = selectedImage, let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(title: "Error", message: "Failed to process image", isSuccess: false)
            return
        }
        
        guard let url = URL(string: "https://hooks.zapier.com/hooks/catch/23448574/u3mpie6/") else {
            showAlert(title: "Error", message: "Invalid URL", isSuccess: false)
            return
        }
        
        isSubmitting = true
        
        // Generate a new UUID for this request - this will be used as request_id
        let generatedRequestId = UUID().uuidString
        requestId = generatedRequestId // Store the request_id for later access
        
        // Notify parent view of the generated request_id
        onRequestIdGenerated?(generatedRequestId)
        
        // Create the multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add request_id field as top-level JSON field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"request_id\"\r\n\r\n".data(using: .utf8)!)
        body.append(generatedRequestId.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add context field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"context\"\r\n\r\n".data(using: .utf8)!)
        body.append(contextText.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add image field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    showAlert(title: "Error", message: "Failed to submit: \(error.localizedDescription)", isSuccess: false)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        // Parse the response and save the meal
                        if let data = data {
                            saveMealFromResponse(data: data, image: image, requestId: generatedRequestId)
                        } else {
                            showAlert(title: "Error", message: "No response data received", isSuccess: false)
                        }
                    } else {
                        let responseData = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No response data"
                        showAlert(title: "Error", message: "Server returned status code: \(httpResponse.statusCode). Response: \(responseData)", isSuccess: false)
                    }
                } else {
                    showAlert(title: "Error", message: "Invalid response from server", isSuccess: false)
                }
            }
        }.resume()
    }
    
    private func saveMealFromResponse(data: Data, image: UIImage, requestId: String) {
        do {
            // Try to parse the response as JSON
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let calories = json["calories"] as? Double ?? 0
                let protein = json["proteinG"] as? Double
                let carbs = json["carbsG"] as? Double
                let fat = json["fatG"] as? Double
                let label = json["label"] as? String ?? "Meal"
                
                // Save the image and create the meal
                saveMealToCoreData(
                    title: label,
                    notes: contextText,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    image: image,
                    requestId: requestId
                )
                
                showAlert(title: "Success", message: "Meal logged successfully!", isSuccess: true)
            } else {
                // If JSON parsing fails, save with default values
                saveMealToCoreData(
                    title: "Meal",
                    notes: contextText,
                    calories: 0,
                    protein: nil,
                    carbs: nil,
                    fat: nil,
                    image: image,
                    requestId: requestId
                )
                
                showAlert(title: "Success", message: "Meal logged successfully! (Calories will need to be added manually)", isSuccess: true)
            }
        } catch {
            print("Error parsing response: \(error)")
            // Save with default values if parsing fails
            saveMealToCoreData(
                title: "Meal",
                notes: contextText,
                calories: 0,
                protein: nil,
                carbs: nil,
                fat: nil,
                image: image,
                requestId: requestId
            )
            
            showAlert(title: "Success", message: "Meal logged successfully! (Calories will need to be added manually)", isSuccess: true)
        }
    }
    
    private func saveMealToCoreData(title: String, notes: String, calories: Double, protein: Double?, carbs: Double?, fat: Double?, image: UIImage, requestId: String) {
        let meal = Meal(context: viewContext)
        meal.id = UUID() // Required field
        meal.title = title // Required field with default value
        meal.notes = notes.isEmpty ? nil : notes
        meal.calories = calories
        meal.proteinG = protein ?? 0
        meal.carbsG = carbs ?? 0
        meal.fatG = fat ?? 0
        meal.timestamp = Date() // Required field
        meal.source = "camera" // Required field with default value
        meal.isEdited = false
        meal.aiRequestId = requestId // Store the request_id in the meal for later reference
        
        // Save the image
        if let imagePath = saveImage(image) {
            meal.imageFilePath = imagePath
            meal.thumbnailFilePath = saveThumbnail(image)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving meal: \(error)")
            showAlert(title: "Error", message: "Failed to save meal to database", isSuccess: false)
        }
    }
    
    private func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imagesDirectory = documentsDirectory.appendingPathComponent("MealImages")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try? FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    private func saveThumbnail(_ image: UIImage) -> String? {
        let size = CGSize(width: 200, height: 200)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.6) else { return nil }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let thumbnailsDirectory = documentsDirectory.appendingPathComponent("Thumbnails")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: thumbnailsDirectory.path) {
            try? FileManager.default.createDirectory(at: thumbnailsDirectory, withIntermediateDirectories: true)
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = thumbnailsDirectory.appendingPathComponent(fileName)
        
        do {
            try thumbnailData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving thumbnail: \(error)")
            return nil
        }
    }
    
    private func showAlert(title: String, message: String, isSuccess: Bool) {
        self.alertTitle = title
        self.alertMessage = message
        self.isSuccess = isSuccess
        self.showingAlert = true
    }
    
    private func clearForm() {
        selectedImage = nil
        contextText = ""
        requestId = nil // Clear the request_id when form is cleared
    }
}

// Extension to provide a way to access the request_id from outside the view
extension PhotoSubmissionView {
    /// Returns the current request_id if one has been generated
    func getCurrentRequestId() -> String? {
        return requestId
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PhotoSubmissionView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
