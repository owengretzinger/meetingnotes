// APIKeyValidator.swift
// Service to validate OpenAI API keys and check for sufficient funds

import Foundation

/// Service to validate OpenAI API keys
class APIKeyValidator {
    static let shared = APIKeyValidator()
    
    private init() {}
    
    /// Validates the OpenAI API key by making a test request
    /// - Parameter apiKey: The API key to validate
    /// - Returns: Result indicating success or failure with error message
    func validateAPIKey(_ apiKey: String) async -> Result<Void, APIKeyValidationError> {
        guard !apiKey.isEmpty else {
            return .failure(.emptyKey)
        }
        
        // Make a simple request to validate the key
        guard let url = URL(string: "https://api.openai.com/v1/models") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.networkError("Invalid response"))
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Key is valid - check if models are available
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["data"] as? [[String: Any]], !models.isEmpty {
                    return .success(())
                } else {
                    return .failure(.noModelsAvailable)
                }
            default:
                let errorMessage = ErrorHandler.shared.handleHTTPStatusCode(httpResponse.statusCode)
                return .failure(.httpError(errorMessage))
            }
        } catch {
            let errorMessage = ErrorHandler.shared.handleError(error)
            return .failure(.networkError(errorMessage))
        }
    }
    
    /// Validates the currently stored API key
    /// - Returns: Result indicating success or failure with error message
    func validateCurrentAPIKey() async -> Result<Void, APIKeyValidationError> {
        guard let apiKey = KeychainHelper.shared.getAPIKey() else {
            return .failure(.emptyKey)
        }
        
        return await validateAPIKey(apiKey)
    }
}

/// Errors that can occur during API key validation
enum APIKeyValidationError: Error, LocalizedError {
    case emptyKey
    case invalidURL
    case noModelsAvailable
    case networkError(String)
    case httpError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return ErrorMessage.noAPIKey
        case .invalidURL:
            return ErrorMessage.invalidURL
        case .noModelsAvailable:
            return ErrorMessage.noModelsAvailable
        case .networkError(let message):
            return message
        case .httpError(let message):
            return message
        }
    }
}