import Foundation
import SwiftUI
import Combine

enum MeetingViewTab: String, CaseIterable {
    case myNotes = "My Notes"
    case transcript = "Transcript"
    case enhancedNotes = "Enhanced Notes"
}

enum RecordingState {
    case idle // Not recording, shows "Transcribe"
    case recording // Recording, shows "Stop"
    case paused // Paused, shows "Resume"
}

@MainActor
class MeetingViewModel: ObservableObject {
    @Published var meeting: Meeting
    @Published var isGeneratingNotes = false
    @Published var errorMessage: String?
    @Published var isRecording = false
    @Published var selectedTab: MeetingViewTab = .myNotes
    @Published var recordingState: RecordingState = .idle
    
    private let audioManager = AudioManager()
    private var cancellables = Set<AnyCancellable>()
    
    init(meeting: Meeting = Meeting()) {
        self.meeting = meeting
        
        // Update meeting transcript chunks when audio manager transcript chunks change
        audioManager.$transcriptChunks
            .sink { [weak self] newChunks in
                self?.meeting.transcriptChunks = newChunks
            }
            .store(in: &cancellables)
        
        // Update isRecording when audio manager recording state changes
        audioManager.$isRecording
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
                self?.updateRecordingState()
            }
            .store(in: &cancellables)
        
        // Auto-save when meeting properties change
        $meeting
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveMeeting()
            }
            .store(in: &cancellables)
    }
    
    private func updateRecordingState() {
        if isRecording {
            recordingState = .recording
        } else if recordingState == .recording {
            recordingState = .paused
        }
    }
    
    var recordingButtonText: String {
        switch recordingState {
        case .idle:
            return "Transcribe"
        case .recording:
            return "Stop"
        case .paused:
            return "Resume"
        }
    }
    
    func toggleRecording() {
        switch recordingState {
        case .idle, .paused:
            startRecording()
        case .recording:
            stopRecording()
        }
    }
    
    func startRecording() {
        audioManager.startRecording()
    }
    
    func stopRecording() {
        audioManager.stopRecording()
        saveMeeting()
    }
    
    func generateNotes() async {
        isGeneratingNotes = true
        errorMessage = nil
        
        do {
            // Load settings for generation
            let userBlurb = KeychainHelper.shared.get(forKey: "userBlurb") ?? ""
            let systemPrompt = KeychainHelper.shared.get(forKey: "systemPrompt") ?? Settings.defaultSystemPrompt
            
            // Generate notes
            meeting.generatedNotes = try await NotesGenerator.shared.generateNotes(
                transcript: meeting.transcript,
                userNotes: meeting.userNotes,
                userBlurb: userBlurb,
                systemPrompt: systemPrompt
            )
            
            saveMeeting()
        } catch {
            errorMessage = "Failed to generate notes: \(error.localizedDescription)"
        }
        
        isGeneratingNotes = false
    }
    
    func saveMeeting() {
        _ = LocalStorageManager.shared.saveMeeting(meeting)
    }
    
    func copyTranscript() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(meeting.formattedTranscript, forType: .string)
    }
    
    func copyNotes() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(meeting.generatedNotes, forType: .string)
    }
    
    func copyCurrentTabContent() {
        NSPasteboard.general.clearContents()
        
        let content: String
        switch selectedTab {
        case .myNotes:
            content = meeting.userNotes
        case .transcript:
            content = meeting.formattedTranscript
        case .enhancedNotes:
            content = meeting.generatedNotes
        }
        
        NSPasteboard.general.setString(content, forType: .string)
    }
} 