import Foundation
import SwiftUI
import Combine

// Add notification name for meeting saved events
extension Notification.Name {
    static let meetingSaved = Notification.Name("MeetingSaved")
    static let meetingDeleted = Notification.Name("MeetingDeleted")
}

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
    @Published var selectedTab: MeetingViewTab = .transcript  // Default to transcript tab
    @Published var recordingState: RecordingState = .idle
    @Published var isDeleted = false
    
    private let audioManager = AudioManager()
    private var cancellables = Set<AnyCancellable>()
    private var isNewMeeting = false
    
    // Computed property to check if meeting is empty
    var isEmpty: Bool {
        return meeting.transcriptChunks.isEmpty && 
               meeting.userNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
               meeting.generatedNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               meeting.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(meeting: Meeting = Meeting()) {
        // Load the latest version of the meeting from storage if it exists
        if let savedMeeting = LocalStorageManager.shared.loadMeetings().first(where: { $0.id == meeting.id }) {
            print("🔄 Loading latest version of meeting: \(meeting.id)")
            self.meeting = savedMeeting
        } else {
            print("🆕 Using provided meeting: \(meeting.id)")
            self.meeting = meeting
        }
        
        // Detect if this is a new meeting based on content, not storage existence
        isNewMeeting = isEmpty
        
        // Set initial tab based on notes existence
        if !self.meeting.generatedNotes.isEmpty {
            selectedTab = .enhancedNotes
        } else {
            selectedTab = .transcript
        }
        
        // NEW: Seed the audio manager with any existing transcript chunks so the initial
        // published value doesn't overwrite the saved transcript with an empty array.
        audioManager.transcriptChunks = self.meeting.transcriptChunks
        
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
            .sink { [weak self] meeting in
                print("🔄 Auto-saving meeting: \(meeting.id) - title: '\(meeting.title)', notes: '\(meeting.userNotes.prefix(50))...'")
                self?.saveMeeting()
            }
            .store(in: &cancellables)
        
        // Auto-start recording for empty meetings
        if isNewMeeting {
            print("🚀 Auto-starting recording for empty meeting")
            startRecording()
        }
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
        
        // Auto-generate notes if there's a transcript and no existing notes
        if !meeting.formattedTranscript.isEmpty && meeting.generatedNotes.isEmpty {
            print("🤖 Auto-generating notes after recording stopped")
            // Switch to enhanced notes tab immediately when starting generation
            selectedTab = .enhancedNotes
            Task {
                await generateNotes()
            }
        }
    }
    
    func generateNotes() async {
        isGeneratingNotes = true
        errorMessage = nil
        
        do {
            // Load settings for generation
            let userBlurb = KeychainHelper.shared.get(forKey: "userBlurb") ?? ""
            let systemPrompt = KeychainHelper.shared.get(forKey: "systemPrompt") ?? Settings.defaultSystemPrompt()
            
            let result = try await NotesGenerator.shared.generateNotes(
                meeting: meeting,
                userBlurb: userBlurb,
                systemPrompt: systemPrompt
            )
            
            meeting.generatedNotes = result.notes
            
            // Update cost info, merging with existing transcription costs if any
            if let existingCostInfo = meeting.costInfo {
                meeting.costInfo = MeetingCostInfo(
                    transcriptionInputTokens: existingCostInfo.transcriptionInputTokens,
                    transcriptionOutputTokens: existingCostInfo.transcriptionOutputTokens,
                    notesInputTokens: result.costInfo.notesInputTokens,
                    notesOutputTokens: result.costInfo.notesOutputTokens,
                    notesCachedInputTokens: result.costInfo.notesCachedInputTokens,
                    transcriptionCost: existingCostInfo.transcriptionCost,
                    notesCost: result.costInfo.notesCost,
                    totalCost: existingCostInfo.transcriptionCost + result.costInfo.notesCost
                )
            } else {
                meeting.costInfo = result.costInfo
            }
            
            saveMeeting()
        } catch {
            errorMessage = "Failed to generate notes: \(error.localizedDescription)"
        }
        
        isGeneratingNotes = false
    }
    
    func saveMeeting() {
        if isDeleted { return }
        print("💾 Saving meeting: \(meeting.id)")
        let success = LocalStorageManager.shared.saveMeeting(meeting)
        print("💾 Save result: \(success ? "SUCCESS" : "FAILED")")
        if success {
            NotificationCenter.default.post(name: .meetingSaved, object: meeting)
        }
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
    
    func deleteMeeting() {
        let success = LocalStorageManager.shared.deleteMeeting(meeting)
        if success {
            isDeleted = true
            NotificationCenter.default.post(name: .meetingDeleted, object: meeting)
        }
    }
    
    func deleteIfEmpty() {
        if isEmpty {
            print("🗑️ Auto-deleting empty meeting")
            deleteMeeting()
        } else {
            saveMeeting()
        }
    }
} 