//
//  AICalorieService.swift
//  CalorieTracker
//
//  Created by Sivakumar Sivasamy on 09/08/2025.
//

import Foundation
import UIKit

class AICalorieService: ObservableObject {
    static let shared = AICalorieService()
    
    private let webhookURL = "https://hooks.zapier.com/hooks/catch/23448574/u3mpie6/"
    
    private init() {}
    
    func estimateCalories(image: UIImage, context: String) async throws -> AICalorieResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw AICalorieError.imageProcessingFailed
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: webhookURL)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add context field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"context\"\r\n\r\n".data(using: .utf8)!)
        body.append(context.data(using: .utf8)!)
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AICalorieError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AICalorieError.serverError(httpResponse.statusCode)
        }
        
        return try parseResponse(data: data)
    }
    
    private func parseResponse(data: Data) throws -> AICalorieResponse {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let calories = json["calories"] as? Double ?? 0
                let protein = json["proteinG"] as? Double
                let carbs = json["carbsG"] as? Double
                let fat = json["fatG"] as? Double
                let label = json["label"] as? String ?? "Meal"
                
                return AICalorieResponse(
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    label: label
                )
            } else {
                throw AICalorieError.invalidResponse
            }
        } catch {
            throw AICalorieError.parsingError(error)
        }
    }
}

struct AICalorieResponse {
    let calories: Double
    let protein: Double?
    let carbs: Double?
    let fat: Double?
    let label: String
}

enum AICalorieError: Error, LocalizedError {
    case imageProcessingFailed
    case invalidResponse
    case serverError(Int)
    case parsingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process image"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .parsingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        }
    }
}
