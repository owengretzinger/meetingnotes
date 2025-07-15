// ErrorHandler.swift
// Centralized error handling service for OpenAI API and network errors

import Foundation

/// Centralized error handling service
class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// Handles errors from OpenAI API calls and network requests
    /// - Parameter error: The error to handle
    /// - Returns: User-friendly error message
    func handleError(_ error: Error) -> String {
        // Handle network errors
        if let urlError = error as? URLError {
            return handleNetworkError(urlError)
        }
        
        // Handle HTTP response errors
        if let httpError = error as? HTTPError {
            return handleHTTPError(httpError)
        }
        
        // Handle OpenAI API errors by checking error description
        let errorDescription = error.localizedDescription.lowercased()
        if let openAIError = categorizeOpenAIError(errorDescription) {
            return openAIError
        }
        
        // Generic error fallback
        return "An unexpected error occurred: \(error.localizedDescription)"
    }
    
    /// Handles WebSocket close codes
    /// - Parameter closeCode: WebSocket close code
    /// - Returns: User-friendly error message
    func handleWebSocketCloseCode(_ closeCode: Int) -> String {
        switch closeCode {
        case 1000: // Normal closure
            return "Connection closed normally"
        case 1001: // Going away
            return "Connection lost. Please try again."
        case 1002: // Protocol error
            return "Connection protocol error. Please try again."
        case 1003: // Unsupported data
            return "Unsupported data format. Please update the app."
        case 1008: // Policy violation
            return "API policy violation. Please check your API key and account status."
        case 1011: // Server error
            return "OpenAI server error. Please try again later."
        case 4000: // Bad request
            return "Invalid request to OpenAI API. Please check your configuration."
        case 4001: // Unauthorized
            return "Invalid API key. Please check your OpenAI API key in Settings."
        case 4002: // Forbidden
            return "Access forbidden. Please check your API key permissions."
        case 4003: // Not found
            return "API endpoint not found. Please update the app."
        case 4004: // Method not allowed
            return "Invalid API method. Please update the app."
        case 4005: // Request timeout
            return "Request timeout. Please try again."
        case 4006: // Request too large
            return "Request too large. Please try again."
        case 4007: // Rate limited
            return "OpenAI API rate limit exceeded. Please try again later."
        case 4008: // Insufficient funds
            return "Insufficient funds in your OpenAI account. Please add credits."
        default:
            return "Connection error (code \(closeCode)). Please try again."
        }
    }
    
    /// Handles HTTP status codes
    /// - Parameter statusCode: HTTP status code
    /// - Parameter message: Optional error message
    /// - Returns: User-friendly error message
    func handleHTTPStatusCode(_ statusCode: Int, message: String? = nil) -> String {
        switch statusCode {
        case 200...299:
            return "Success"
        case 400:
            return "Bad request. Please check your input."
        case 401:
            return "Invalid OpenAI API key. Please check your API key in Settings."
        case 402:
            return "Insufficient funds in your OpenAI account. Please add credits to your account."
        case 403:
            return "Access forbidden. Please check your API key permissions."
        case 404:
            return "API endpoint not found. Please update the app."
        case 429:
            return "OpenAI API rate limit exceeded. Please try again later."
        case 500...599:
            return "OpenAI server error. Please try again later."
        default:
            return "HTTP error \(statusCode): \(message ?? "Unknown error")"
        }
    }
    
    /// Determines if an error should trigger a retry
    /// - Parameter error: The error to check
    /// - Returns: True if the error is retryable
    func shouldRetry(_ error: Error) -> Bool {
        // Network errors are generally retryable
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotFindHost, .networkConnectionLost, .cannotConnectToHost:
                return true
            default:
                return false
            }
        }
        
        // WebSocket close codes
        if let closeCode = (error as NSError?)?.userInfo["closeCode"] as? Int {
            return closeCode < 4000 // Only retry for non-API errors
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    private func handleNetworkError(_ urlError: URLError) -> String {
        switch urlError.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network and try again."
        case .timedOut:
            return "Request timed out. Please try again."
        case .cannotFindHost:
            return "Cannot reach OpenAI servers. Please check your internet connection."
        case .cannotConnectToHost:
            return "Cannot connect to OpenAI servers. Please check your internet connection."
        case .networkConnectionLost:
            return "Network connection lost. Please try again."
        case .httpTooManyRedirects:
            return "Too many redirects. Please try again later."
        case .secureConnectionFailed:
            return "Secure connection failed. Please check your internet connection."
        case .serverCertificateUntrusted:
            return "Server certificate untrusted. Please try again."
        default:
            return "Network error: \(urlError.localizedDescription)"
        }
    }
    
    private func handleHTTPError(_ httpError: HTTPError) -> String {
        return handleHTTPStatusCode(httpError.statusCode, message: httpError.message)
    }
    
    private func categorizeOpenAIError(_ errorDescription: String) -> String? {
        if errorDescription.contains("unauthorized") || errorDescription.contains("401") {
            return "Invalid OpenAI API key. Please check your API key in Settings."
        } else if errorDescription.contains("insufficient") || errorDescription.contains("402") {
            return "Insufficient funds in your OpenAI account. Please add credits to your account."
        } else if errorDescription.contains("rate limit") || errorDescription.contains("429") {
            return "OpenAI API rate limit exceeded. Please try again later."
        } else if errorDescription.contains("server error") || errorDescription.contains("500") {
            return "OpenAI server error. Please try again later."
        } else if errorDescription.contains("forbidden") || errorDescription.contains("403") {
            return "Access forbidden. Please check your API key permissions."
        } else if errorDescription.contains("not found") || errorDescription.contains("404") {
            return "API endpoint not found. Please update the app."
        }
        
        return nil
    }
}

/// HTTP error type
struct HTTPError: Error {
    let statusCode: Int
    let message: String?
    
    init(statusCode: Int, message: String? = nil) {
        self.statusCode = statusCode
        self.message = message
    }
}

/// Common error messages
enum ErrorMessage {
    static let noAPIKey = "OpenAI API key not found. Please configure your API key in Settings."
    static let noTemplate = "No template content found. Please select a valid template."
    static let noTranscript = "No transcript available. Please record some audio first."
    static let connectionTimeout = "Failed to connect to OpenAI transcription service. Please check your internet connection and API key."
    static let configurationFailed = "Failed to configure transcription session."
    static let invalidURL = "Invalid API URL configuration."
    static let noModelsAvailable = "No models available with your API key. Please check your account status."
}