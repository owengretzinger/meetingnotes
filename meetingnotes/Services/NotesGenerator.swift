// NotesGenerator.swift
// Handles AI-powered note generation using OpenAI

import Foundation
import OpenAI

/// Generates meeting notes using OpenAI API
class NotesGenerator {
    static let shared = NotesGenerator()
    
    private init() {}
    
    /// Generates meeting notes from meeting data using template-based system prompt with streaming
    /// - Parameters:
    ///   - meeting: The meeting object containing all necessary data
    ///   - userBlurb: Information about the user for context
    ///   - systemPrompt: The system prompt template with placeholders
    /// - Returns: AsyncStream of partial generated notes
    func generateNotesStream(meeting: Meeting,
                            userBlurb: String,
                            systemPrompt: String) -> AsyncStream<String> {
        return AsyncStream { continuation in
            Task {
                do {
                    guard let apiKey = KeychainHelper.shared.get(forKey: "openAIKey"), !apiKey.isEmpty else {
                        continuation.finish()
                        return
                    }
                    
                    let openAI = OpenAI(apiToken: apiKey)
                    
                    // Create date formatter for meeting date
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateStyle = .full
                    dateFormatter.timeStyle = .short
                    
                    // Prepare template variables
                    let templateVariables: [String: String] = [
                        "meeting_title": meeting.title.isEmpty ? "Untitled Meeting" : meeting.title,
                        "meeting_date": dateFormatter.string(from: meeting.date),
                        "transcript": meeting.formattedTranscript,
                        "user_blurb": userBlurb,
                        "user_notes": meeting.userNotes
                    ]
                    
                    // Process the system prompt template
                    let systemContent = Settings.processTemplate(systemPrompt, with: templateVariables)
                    let systemMessage = ChatQuery.ChatCompletionMessageParam(role: .system, content: systemContent)!

                    print(systemContent)
                
                    let query = ChatQuery(messages: [systemMessage], model: .gpt4_1)
                    
                    let stream: AsyncThrowingStream<ChatStreamResult, Error> = openAI.chatsStream(query: query)
                    
                    for try await result in stream {
                        if let content = result.choices.first?.delta.content {
                            continuation.yield(content)
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    print("Error in streaming generation: \(error)")
                    continuation.finish()
                }
            }
        }
    }
    
    /// Validates if OpenAI API key is configured
    /// - Returns: True if API key exists, false otherwise
    func isConfigured() -> Bool {
        guard let key = KeychainHelper.shared.get(forKey: "openAIKey"),
              !key.isEmpty else {
            return false
        }
        return true
    }
} 