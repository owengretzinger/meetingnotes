// CostCalculator.swift
// Handles cost calculation for AI model usage

import Foundation

/// Model pricing information
struct ModelPricing {
    let inputCostPerMillionTokens: Double
    let outputCostPerMillionTokens: Double
    let cachedInputCostPerMillionTokens: Double?
    
    // Cost per token (in dollars)
    var inputCostPerToken: Double {
        return inputCostPerMillionTokens / 1_000_000.0
    }
    
    var outputCostPerToken: Double {
        return outputCostPerMillionTokens / 1_000_000.0
    }
    
    var cachedInputCostPerToken: Double? {
        return cachedInputCostPerMillionTokens.map { $0 / 1_000_000.0 }
    }
}

/// Tracks usage and cost information for a meeting
struct MeetingCostInfo: Codable {
    let transcriptionInputTokens: Int
    let transcriptionOutputTokens: Int
    let notesInputTokens: Int
    let notesOutputTokens: Int
    let notesCachedInputTokens: Int
    let transcriptionCost: Double
    let notesCost: Double
    let totalCost: Double
    
    init(transcriptionInputTokens: Int = 0,
         transcriptionOutputTokens: Int = 0,
         notesInputTokens: Int = 0,
         notesOutputTokens: Int = 0,
         notesCachedInputTokens: Int = 0,
         transcriptionCost: Double = 0.0,
         notesCost: Double = 0.0,
         totalCost: Double = 0.0) {
        self.transcriptionInputTokens = transcriptionInputTokens
        self.transcriptionOutputTokens = transcriptionOutputTokens
        self.notesInputTokens = notesInputTokens
        self.notesOutputTokens = notesOutputTokens
        self.notesCachedInputTokens = notesCachedInputTokens
        self.transcriptionCost = transcriptionCost
        self.notesCost = notesCost
        self.totalCost = totalCost
    }
}

/// Calculates costs for AI model usage
class CostCalculator {
    static let shared = CostCalculator()
    
    private init() {}
    
    // Model pricing as specified
    static let gpt4oMiniTranscribePricing = ModelPricing(
        inputCostPerMillionTokens: 1.25,
        outputCostPerMillionTokens: 5.0,
        cachedInputCostPerMillionTokens: nil
    )
    
    static let gpt41Pricing = ModelPricing(
        inputCostPerMillionTokens: 2.0,
        outputCostPerMillionTokens: 8.0,
        cachedInputCostPerMillionTokens: 0.5
    )
    
    /// Estimates token count for text (rough approximation: 1 token ≈ 4 characters)
    func estimateTokenCount(_ text: String) -> Int {
        // This is a rough approximation. For more accuracy, you'd use a proper tokenizer
        // GPT models typically use ~4 characters per token on average
        return max(1, text.count / 4)
    }
    
    /// Calculates cost based on actual token usage
    func calculateCost(inputTokens: Int, outputTokens: Int, cachedInputTokens: Int = 0, pricing: ModelPricing) -> Double {
        var cost = 0.0
        
        // Calculate input cost
        let regularInputTokens = inputTokens - cachedInputTokens
        cost += Double(regularInputTokens) * pricing.inputCostPerToken
        
        // Calculate cached input cost if applicable
        if let cachedCost = pricing.cachedInputCostPerToken {
            cost += Double(cachedInputTokens) * cachedCost
        }
        
        // Calculate output cost
        cost += Double(outputTokens) * pricing.outputCostPerToken
        
        return cost
    }
    
    /// Estimates cost for transcription (using gpt-4o-mini-transcribe pricing)
    func estimateTranscriptionCost(for meeting: Meeting) -> Double {
        let transcript = meeting.formattedTranscript
        if transcript.isEmpty {
            return 0.0
        }
        
        // For transcription, estimate based on expected cost per minute
        // $0.003/minute as specified
        let meetingDuration = estimateMeetingDuration(meeting)
        return meetingDuration * 0.003
    }
    
    /// Estimates cost for notes generation (using gpt-4.1 pricing)
    func estimateNotesGenerationCost(for meeting: Meeting) -> Double {
        let systemPrompt = KeychainHelper.shared.get(forKey: "systemPrompt") ?? Settings.defaultSystemPrompt()
        let userBlurb = KeychainHelper.shared.get(forKey: "userBlurb") ?? ""
        
        // Estimate input tokens (system prompt + transcript + user notes)
        let inputText = systemPrompt + meeting.formattedTranscript + meeting.userNotes + userBlurb
        let inputTokens = estimateTokenCount(inputText)
        
        // Estimate output tokens (generated notes)
        let outputTokens = estimateTokenCount(meeting.generatedNotes)
        
        return calculateCost(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            pricing: CostCalculator.gpt41Pricing
        )
    }
    
    /// Estimates total cost for a meeting
    func estimateTotalCost(for meeting: Meeting) -> Double {
        return estimateTranscriptionCost(for: meeting) + estimateNotesGenerationCost(for: meeting)
    }
    
    /// Estimates meeting duration in minutes based on transcript chunks
    private func estimateMeetingDuration(_ meeting: Meeting) -> Double {
        guard let firstChunk = meeting.transcriptChunks.first,
              let lastChunk = meeting.transcriptChunks.last else {
            return 0.0
        }
        
        let duration = lastChunk.timestamp.timeIntervalSince(firstChunk.timestamp)
        return max(1.0, duration / 60.0) // At least 1 minute
    }
    
    /// Creates cost info from actual API usage
    func createCostInfo(
        transcriptionInputTokens: Int = 0,
        transcriptionOutputTokens: Int = 0,
        notesInputTokens: Int = 0,
        notesOutputTokens: Int = 0,
        notesCachedInputTokens: Int = 0
    ) -> MeetingCostInfo {
        let transcriptionCost = calculateCost(
            inputTokens: transcriptionInputTokens,
            outputTokens: transcriptionOutputTokens,
            pricing: CostCalculator.gpt4oMiniTranscribePricing
        )
        
        let notesCost = calculateCost(
            inputTokens: notesInputTokens,
            outputTokens: notesOutputTokens,
            cachedInputTokens: notesCachedInputTokens,
            pricing: CostCalculator.gpt41Pricing
        )
        
        return MeetingCostInfo(
            transcriptionInputTokens: transcriptionInputTokens,
            transcriptionOutputTokens: transcriptionOutputTokens,
            notesInputTokens: notesInputTokens,
            notesOutputTokens: notesOutputTokens,
            notesCachedInputTokens: notesCachedInputTokens,
            transcriptionCost: transcriptionCost,
            notesCost: notesCost,
            totalCost: transcriptionCost + notesCost
        )
    }
}