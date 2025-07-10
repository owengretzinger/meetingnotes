import Foundation

enum AudioSource: String, Codable, CaseIterable {
    case mic = "MIC"
    case system = "SYS"
    
    var displayName: String {
        switch self {
        case .mic:
            return "Me"
        case .system:
            return "Them"
        }
    }
    
    var copyPrefix: String {
        switch self {
        case .mic:
            return "Me"
        case .system:
            return "Them"
        }
    }
    
    var icon: String {
        switch self {
        case .mic:
            return "mic.fill"
        case .system:
            return "speaker.wave.2.fill"
        }
    }
}

struct TranscriptChunk: Codable, Identifiable, Hashable {
    let id: UUID
    let timestamp: Date
    let source: AudioSource
    let text: String
    let isFinal: Bool
    
    init(id: UUID = UUID(), timestamp: Date = Date(), source: AudioSource, text: String, isFinal: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.text = text
        self.isFinal = isFinal
    }
}

struct CollapsedTranscriptChunk: Identifiable {
    let id: UUID
    let timestamp: Date
    let source: AudioSource
    let combinedText: String
    
    init(id: UUID = UUID(), timestamp: Date, source: AudioSource, combinedText: String) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.combinedText = combinedText
    }
}

struct Meeting: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    var title: String
    var transcriptChunks: [TranscriptChunk]
    var userNotes: String
    var generatedNotes: String
    
    init(id: UUID = UUID(), 
         date: Date = Date(),
         title: String = "",
         transcriptChunks: [TranscriptChunk] = [],
         userNotes: String = "", 
         generatedNotes: String = "") {
        self.id = id
        self.date = date
        self.title = title
        self.transcriptChunks = transcriptChunks
        self.userNotes = userNotes
        self.generatedNotes = generatedNotes
    }
    
    // Computed property for backward compatibility with existing code
    var transcript: String {
        return transcriptChunks
            .filter { $0.isFinal }
            .map { "[\($0.source.rawValue)] \($0.text)" }
            .joined(separator: " ")
    }
    
    // Formatted transcript for copying with collapsed sequential chunks
    var formattedTranscript: String {
        let finalChunks = transcriptChunks.filter { $0.isFinal }
        
        guard !finalChunks.isEmpty else { return "" }
        
        var result: [String] = []
        var currentSource: AudioSource?
        var currentTexts: [String] = []
        
        for chunk in finalChunks {
            if chunk.source != currentSource {
                // Finish previous section if exists
                if let source = currentSource, !currentTexts.isEmpty {
                    let combinedText = currentTexts.joined(separator: " ")
                    result.append("\(source.copyPrefix): \(combinedText)")
                }
                
                // Start new section
                currentSource = chunk.source
                currentTexts = [chunk.text]
            } else {
                // Same source, add to current section
                currentTexts.append(chunk.text)
            }
        }
        
        // Finish last section
        if let source = currentSource, !currentTexts.isEmpty {
            let combinedText = currentTexts.joined(separator: " ")
            result.append("\(source.copyPrefix): \(combinedText)")
        }
        
        return result.joined(separator: "  \n")
    }
    
    // Collapsed chunks for UI display
    var collapsedTranscriptChunks: [CollapsedTranscriptChunk] {
        guard !transcriptChunks.isEmpty else { return [] }
        
        var result: [CollapsedTranscriptChunk] = []
        var currentSource: AudioSource?
        var currentTexts: [String] = []
        var currentTimestamp: Date?
        
        for chunk in transcriptChunks {
            if chunk.source != currentSource {
                // Finish previous section if exists
                if let source = currentSource, !currentTexts.isEmpty, let timestamp = currentTimestamp {
                    let combinedText = currentTexts.joined(separator: " ")
                    result.append(CollapsedTranscriptChunk(
                        timestamp: timestamp,
                        source: source,
                        combinedText: combinedText
                    ))
                }
                
                // Start new section
                currentSource = chunk.source
                currentTexts = [chunk.text]
                currentTimestamp = chunk.timestamp
            } else {
                // Same source, add to current section
                currentTexts.append(chunk.text)
            }
        }
        
        // Finish last section
        if let source = currentSource, !currentTexts.isEmpty, let timestamp = currentTimestamp {
            let combinedText = currentTexts.joined(separator: " ")
            result.append(CollapsedTranscriptChunk(
                timestamp: timestamp,
                source: source,
                combinedText: combinedText
            ))
        }
        
        return result
    }
    
    // Separate computed properties for mic and system transcripts
    var micTranscript: String {
        return transcriptChunks
            .filter { $0.source == .mic && $0.isFinal }
            .map { $0.text }
            .joined(separator: " ")
    }
    
    var systemTranscript: String {
        return transcriptChunks
            .filter { $0.source == .system && $0.isFinal }
            .map { $0.text }
            .joined(separator: " ")
    }
} 