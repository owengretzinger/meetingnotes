import Foundation
import SwiftUI
import Combine

@MainActor
class MeetingViewModel: ObservableObject {
    @Published var meeting: Meeting
    @Published var isGeneratingNotes = false
    @Published var errorMessage: String?
    @Published var isRecording = false
    
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
            }
            .store(in: &cancellables)
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
} 