import Foundation
import SwiftUI
import Combine

/// Manages recording sessions at the app level to persist across navigation
@MainActor
class RecordingSessionManager: ObservableObject {
    static let shared = RecordingSessionManager()
    
    @Published var isRecording = false
    @Published var activeMeetingId: UUID?
    @Published var errorMessage: String?
    @Published var activeRecordingTranscriptChunksUpdated: [TranscriptChunk] = []
    
    private let audioManager = AudioManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let transcriptUpdateSubject = PassthroughSubject<[TranscriptChunk], Never>()
    
    // Store transcript chunks for the active recording session
    private var activeRecordingTranscriptChunks: [TranscriptChunk] = []
    
    private init() {
        setupAudioManagerBindings()
        setupDebouncedSaving()
    }
    
    private func setupAudioManagerBindings() {
        // Bind to audio manager state
        audioManager.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
            }
            .store(in: &cancellables)
        
        audioManager.$errorMessage
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
            }
            .store(in: &cancellables)
        
        // When transcript chunks change, store them for the active recording and send to debouncer
        audioManager.$transcriptChunks
            .sink { [weak self] newChunks in
                guard let self = self, self.isRecording, self.activeMeetingId != nil else { return }
                self.activeRecordingTranscriptChunks = newChunks
                self.activeRecordingTranscriptChunksUpdated = newChunks
                
                self.transcriptUpdateSubject.send(newChunks)
            }
            .store(in: &cancellables)
    }
    
    private func setupDebouncedSaving() {
        transcriptUpdateSubject
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] chunks in
                guard let self = self, let activeMeetingId = self.activeMeetingId else { return }
                print("💾 Debounced save triggered for meeting: \(activeMeetingId.uuidString)")
                self.updateActiveMeetingTranscript(meetingId: activeMeetingId, chunks: chunks)
            }
            .store(in: &cancellables)
    }
    
    func startRecording(for meetingId: UUID) {
        print("🎙️ Starting recording for meeting: \(meetingId)")
        
        // Load the meeting to get existing transcript chunks
        if let existingMeeting = LocalStorageManager.shared.loadMeetings().first(where: { $0.id == meetingId }) {
            activeRecordingTranscriptChunks = existingMeeting.transcriptChunks
            // Seed the audio manager with existing chunks
            audioManager.transcriptChunks = existingMeeting.transcriptChunks
        }
        
        activeMeetingId = meetingId
        audioManager.startRecording()
    }
    
    func stopRecording() {
        print("🛑 Stopping recording for meeting: \(activeMeetingId?.uuidString ?? "unknown")")
        
        audioManager.stopRecording()
        
        // Perform a final, immediate save of transcript chunks to the meeting
        if let activeMeetingId = activeMeetingId {
            updateActiveMeetingTranscript(meetingId: activeMeetingId, chunks: activeRecordingTranscriptChunks)
        }
        
        activeMeetingId = nil
        activeRecordingTranscriptChunks = []
    }
    
    func isRecordingMeeting(_ meetingId: UUID) -> Bool {
        return isRecording && activeMeetingId == meetingId
    }
    
    private func updateActiveMeetingTranscript(meetingId: UUID, chunks: [TranscriptChunk]) {
        // Load all meetings
        var meetings = LocalStorageManager.shared.loadMeetings()
        
        // Find and update the active meeting
        if let index = meetings.firstIndex(where: { $0.id == meetingId }) {
            meetings[index].transcriptChunks = chunks
            
            // Save the updated meeting
            let success = LocalStorageManager.shared.saveMeeting(meetings[index])
            if success {
                print("✅ Saved meeting transcript: \(meetingId.uuidString)")
                NotificationCenter.default.post(name: .meetingSaved, object: meetings[index])
            } else {
                print("❌ Failed to save meeting transcript: \(meetingId.uuidString)")
            }
        }
    }
    
    func getActiveRecordingTranscriptChunks() -> [TranscriptChunk] {
        return activeRecordingTranscriptChunks
    }
    
    /// Get transcript chunks for a specific meeting, ensuring proper data separation
    func getTranscriptChunks(for meetingId: UUID) -> [TranscriptChunk] {
        if isRecording && activeMeetingId == meetingId {
            // Return live transcript chunks for the active recording
            return activeRecordingTranscriptChunks
        } else {
            // Load saved transcript chunks from storage for non-active meetings
            if let savedMeeting = LocalStorageManager.shared.loadMeetings().first(where: { $0.id == meetingId }) {
                return savedMeeting.transcriptChunks
            }
            return []
        }
    }
} 