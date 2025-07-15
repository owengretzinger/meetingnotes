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
            case 401:
                return .failure(.invalidKey)
            case 429:
                return .failure(.rateLimited)
            case 402:
                return .failure(.insufficientFunds)
            case 403:
                return .failure(.forbidden)
            case 500...599:
                return .failure(.serverError)
            default:
                return .failure(.networkError("HTTP \(httpResponse.statusCode)"))
            }
        } catch {
            return .failure(.networkError(error.localizedDescription))
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
    case invalidKey
    case insufficientFunds
    case rateLimited
    case forbidden
    case serverError
    case networkError(String)
    case invalidURL
    case noModelsAvailable
    
    var errorDescription: String? {
        switch self {
        case .emptyKey:
            return "OpenAI API key is not configured. Please add your API key in Settings."
        case .invalidKey:
            return "Invalid OpenAI API key. Please check your API key in Settings."
        case .insufficientFunds:
            return "Insufficient funds in your OpenAI account. Please add credits to your account."
        case .rateLimited:
            return "OpenAI API rate limit exceeded. Please try again later."
        case .forbidden:
            return "Access forbidden. Please check your API key permissions."
        case .serverError:
            return "OpenAI server error. Please try again later."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidURL:
            return "Invalid API URL configuration."
        case .noModelsAvailable:
            return "No models available with your API key. Please check your account status."
        }
    }
}