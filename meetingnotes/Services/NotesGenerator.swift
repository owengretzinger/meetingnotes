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
                        continuation.yield(.error(ErrorMessage.noAPIKey))
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
                        continuation.yield(.error(ErrorMessage.noTemplate))
                        continuation.finish()
                        return
                    }
                    
                    // Check if transcript is empty
                    if meeting.formattedTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        continuation.yield(.error(ErrorMessage.noTranscript))
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
                    let errorMessage = ErrorHandler.shared.handleError(error)
                    print("Error in streaming generation: \(error)")
                    continuation.yield(.error(errorMessage))
                    continuation.finish()
                }
            }
        }
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