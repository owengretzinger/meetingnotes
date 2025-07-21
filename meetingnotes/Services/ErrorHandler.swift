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
        case 1000: return "Connection closed normally"
        case 1001: return ErrorMessage.connectionLost
        case 1002: return "Connection protocol error. Please try again."
        case 1003: return ErrorMessage.unsupportedData
        case 1008: return "API policy violation. Please check your API key and account status."
        case 1011: return ErrorMessage.apiServerError
        case 4000: return ErrorMessage.badRequest
        case 4001: return ErrorMessage.invalidAPIKey
        case 4002: return ErrorMessage.accessForbidden
        case 4003: return ErrorMessage.apiEndpointNotFound
        case 4004: return "Invalid API method. Please update the app."
        case 4005: return ErrorMessage.requestTimeout
        case 4006: return ErrorMessage.requestTooLarge
        case 4007: return ErrorMessage.rateLimited
        case 4008: return ErrorMessage.insufficientFunds
        default:   return "Connection error (code \(closeCode)). Please try again."
        }
    }
    
    /// Handles HTTP status codes
    /// - Parameter statusCode: HTTP status code
    /// - Parameter message: Optional error message
    /// - Returns: User-friendly error message
    func handleHTTPStatusCode(_ statusCode: Int, message: String? = nil) -> String {
        switch statusCode {
        case 200...299:
            return ErrorMessage.success
        case 400:
            return ErrorMessage.badRequest
        case 401:
            return ErrorMessage.invalidAPIKey
        case 402:
            return ErrorMessage.insufficientFunds
        case 403:
            return ErrorMessage.accessForbidden
        case 404:
            return ErrorMessage.apiEndpointNotFound
        case 429:
            return ErrorMessage.rateLimited
        case 500...599:
            return ErrorMessage.apiServerError
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
        
        // Handle POSIX socket errors (e.g., "Socket is not connected")
        if let nsError = error as NSError?, nsError.domain == NSPOSIXErrorDomain {
            switch nsError.code {
            case 57: // ENOTCONN - Socket is not connected
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
            return ErrorMessage.invalidAPIKey
        } else if errorDescription.contains("insufficient") || errorDescription.contains("402") {
            return ErrorMessage.insufficientFunds
        } else if errorDescription.contains("rate limit") || errorDescription.contains("429") {
            return ErrorMessage.rateLimited
        } else if errorDescription.contains("server error") || errorDescription.contains("500") {
            return ErrorMessage.apiServerError
        } else if errorDescription.contains("forbidden") || errorDescription.contains("403") {
            return ErrorMessage.accessForbidden
        } else if errorDescription.contains("not found") || errorDescription.contains("404") {
            return ErrorMessage.apiEndpointNotFound
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

    // Centralized messages used across handlers
    static let success = "Success"
    static let badRequest = "Bad request. Please check your input."
    static let invalidAPIKey = "Invalid OpenAI API key. Please check your API key in Settings."
    static let insufficientFunds = "Insufficient funds in your OpenAI account. Please add credits to your account."
    static let accessForbidden = "Access forbidden. Please check your API key permissions."
    static let apiEndpointNotFound = "API endpoint not found. Please update the app."
    static let rateLimited = "OpenAI API rate limit exceeded. Please try again later."
    static let apiServerError = "OpenAI server error. Please try again later."
    static let requestTimeout = "Request timeout. Please try again."
    static let requestTooLarge = "Request too large. Please try again."
    static let unsupportedData = "Unsupported data format. Please update the app."
    static let connectionLost = "Connection lost. Please try again."
}