import Foundation

enum AudioSource: String, Codable, CaseIterable {
    case mic = "MIC"
    case system = "SYS"
    
    var displayName: String {
        switch self {
        case .mic:
            return "Microphone"
        case .system:
            return "System Audio"
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

struct Meeting: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    var transcriptChunks: [TranscriptChunk]
    var userNotes: String
    var generatedNotes: String
    
    init(id: UUID = UUID(), 
         date: Date = Date(), 
         transcriptChunks: [TranscriptChunk] = [],
         userNotes: String = "", 
         generatedNotes: String = "") {
        self.id = id
        self.date = date
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