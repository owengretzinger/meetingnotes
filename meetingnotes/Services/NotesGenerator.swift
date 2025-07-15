// NotesGenerator.swift
// Handles AI-powered note generation using OpenAI

import Foundation
import OpenAI

/// Result type for note generation streaming
enum GenerationResult {
    case content(String)
    case error(String)
}

/// Generates meeting notes using OpenAI API
class NotesGenerator {
    static let shared = NotesGenerator()
    
    private init() {}
    
    /// Generates meeting notes from meeting data using template-based system prompt with streaming
    /// - Parameters:
    ///   - meeting: The meeting object containing all necessary data
    ///   - userBlurb: Information about the user for context
    ///   - systemPrompt: The system prompt template with placeholders
    ///   - templateId: Optional template ID to use for generating notes
    /// - Returns: AsyncStream of partial generated notes
    func generateNotesStream(meeting: Meeting,
                            userBlurb: String,
                            systemPrompt: String,
                            templateId: UUID? = nil) -> AsyncStream<GenerationResult> {
        
        return AsyncStream<GenerationResult>(GenerationResult.self) { continuation in
            Task {
                do {
                    guard let apiKey = KeychainHelper.shared.getAPIKey(), !apiKey.isEmpty else {
                        continuation.yield(.error("OpenAI API key not found. Please configure your API key in Settings."))
                        continuation.finish()
                        return
                    }
                    
                    // Validate API key before proceeding
                    let validationResult = await APIKeyValidator.shared.validateAPIKey(apiKey)
                    switch validationResult {
                    case .failure(let error):
                        continuation.yield(.error(error.localizedDescription))
                        continuation.finish()
                        return
                    case .success():
                        break
                    }
                    
                    let openAI = OpenAI(apiToken: apiKey)
                    
                    // Create date formatter for meeting date
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .full
                    dateFormatter.timeStyle = .short
                    
                    // Load template content
                    var templateContent = ""
                    if let templateId = templateId {
                        let templates = LocalStorageManager.shared.loadTemplates()
                        if let template = templates.first(where: { $0.id == templateId }) {
                            templateContent = template.formattedContent
                        }
                    }
                    
                    // If no template content, use default
                    if templateContent.isEmpty {
                        continuation.yield(.error("No template content found. Please select a valid template."))
                        continuation.finish()
                        return
                    }
                    
                    // Check if transcript is empty
                    if meeting.formattedTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        continuation.yield(.error("No transcript available. Please record some audio first."))
                        continuation.finish()
                        return
                    }
                    
                    // Prepare template variables
                    let templateVariables: [String: String] = [
                        "meeting_title": meeting.title.isEmpty ? "Untitled Meeting" : meeting.title,
                        "meeting_date": dateFormatter.string(from: meeting.date),
                        "transcript": meeting.formattedTranscript,
                        "user_blurb": userBlurb,
                        "user_notes": meeting.userNotes,
                        "template_content": templateContent
                    ]
                    
                    // Process the system prompt template
                    let systemContent = Settings.processTemplate(systemPrompt, with: templateVariables)
                    let systemMessage = ChatQuery.ChatCompletionMessageParam(role: .system, content: systemContent)!

                    print(systemContent)
                
                    let query = ChatQuery(messages: [systemMessage], model: .gpt4_1)
                    
                    let stream: AsyncThrowingStream<ChatStreamResult, Error> = openAI.chatsStream(query: query)
                    
                    for try await result in stream {
                        if let content = result.choices.first?.delta.content {
                            continuation.yield(.content(content))
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    let errorMessage = handleOpenAIError(error)
                    print("Error in streaming generation: \(error)")
                    continuation.yield(.error(errorMessage))
                    continuation.finish()
                }
            }
        }
    }
    
    private func handleOpenAIError(_ error: Error) -> String {
        // Check for network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "No internet connection. Please check your network and try again."
            case .timedOut:
                return "Request timed out. Please try again."
            case .cannotFindHost:
                return "Cannot reach OpenAI servers. Please check your internet connection."
            default:
                return "Network error: \(urlError.localizedDescription)"
            }
        }
        
        // Check error description for common OpenAI API errors
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("unauthorized") || errorDescription.contains("401") {
            return "Invalid OpenAI API key. Please check your API key in Settings."
        } else if errorDescription.contains("insufficient") || errorDescription.contains("402") {
            return "Insufficient funds in your OpenAI account. Please add credits to your account."
        } else if errorDescription.contains("rate limit") || errorDescription.contains("429") {
            return "OpenAI API rate limit exceeded. Please try again later."
        } else if errorDescription.contains("server error") || errorDescription.contains("5") {
            return "OpenAI server error. Please try again later."
        }
        
        return "Failed to generate notes: \(error.localizedDescription)"
    }
    
    /// Validates if OpenAI API key is configured
    /// - Returns: True if API key exists, false otherwise
    func isConfigured() -> Bool {
        guard let key = KeychainHelper.shared.getAPIKey(),
              !key.isEmpty else {
            return false
        }
        return true
    }
} 