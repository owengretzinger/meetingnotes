// NotesGenerator.swift
// Handles AI-powered note generation using OpenAI

import Foundation
import OpenAI

/// Generates meeting notes using OpenAI API
class NotesGenerator {
    static let shared = NotesGenerator()
    
    private init() {}
    
    /// Generates meeting notes from transcript and user notes
    /// - Parameters:
    ///   - transcript: The meeting transcript
    ///   - userNotes: Additional notes from the user
    ///   - userBlurb: Information about the user for context
    ///   - systemPrompt: The system prompt for AI generation
    /// - Returns: Generated meeting notes
    func generateNotes(transcript: String,
                      userNotes: String,
                      userBlurb: String,
                      systemPrompt: String) async throws -> String {
        
        guard let apiKey = KeychainHelper.shared.get(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw NSError(domain: "NotesGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
        }
        
        let openAI = OpenAI(apiToken: apiKey)
        
        // Compose system prompt with user blurb wrapped in XML tags for clarity
        let systemContent = "\(systemPrompt)\n\n<user_blurb>\n\(userBlurb)\n</user_blurb>"
        let systemMessage = ChatQuery.ChatCompletionMessageParam(role: .system, content: systemContent)!
        
        // Provide the model with structured XML-tagged input variables for improved parsing
        let userContent = "<task>Generate concise and well-structured meeting notes using the information below.</task>\n\n<transcript>\n\(transcript)\n</transcript>\n\n<user_notes>\n\(userNotes)\n</user_notes>"
        let userMessage = ChatQuery.ChatCompletionMessageParam(role: .user, content: userContent)!
        
        let query = ChatQuery(messages: [systemMessage, userMessage], model: .gpt4_1_mini)
        
        let result = try await openAI.chats(query: query)
        
        guard let generatedNotes = result.choices.first?.message.content else {
            throw NSError(domain: "NotesGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate notes"])
        }
        
        return generatedNotes
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