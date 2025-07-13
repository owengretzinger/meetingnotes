// NotesGenerator.swift
// Handles AI-powered note generation using OpenAI

import Foundation
import OpenAI

/// Generates meeting notes using OpenAI API
class NotesGenerator {
    static let shared = NotesGenerator()
    
    private init() {}
    
    /// Generates meeting notes from meeting data using template-based system prompt
    /// - Parameters:
    ///   - meeting: The meeting object containing all necessary data
    ///   - userBlurb: Information about the user for context
    ///   - systemPrompt: The system prompt template with placeholders
    /// - Returns: Generated meeting notes and token usage info
    func generateNotes(meeting: Meeting,
                      userBlurb: String,
                      systemPrompt: String) async throws -> (notes: String, costInfo: MeetingCostInfo) {
        
        guard let apiKey = KeychainHelper.shared.get(forKey: "openAIKey"), !apiKey.isEmpty else {
            throw NSError(domain: "NotesGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured"])
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
        
        let result = try await openAI.chats(query: query)
        
        guard let generatedNotes = result.choices.first?.message.content else {
            throw NSError(domain: "NotesGenerator", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate notes"])
        }
        
        // Extract token usage from the response
        let inputTokens = result.usage?.promptTokens ?? 0
        let outputTokens = result.usage?.completionTokens ?? 0
        let cachedInputTokens = result.usage?.promptTokensCacheHitDetails?.cacheHitTokens ?? 0
        
        // Calculate cost info
        let costInfo = CostCalculator.shared.createCostInfo(
            transcriptionInputTokens: 0, // Transcription is handled separately
            transcriptionOutputTokens: 0,
            notesInputTokens: inputTokens,
            notesOutputTokens: outputTokens,
            notesCachedInputTokens: cachedInputTokens
        )
        
        return (generatedNotes, costInfo)
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