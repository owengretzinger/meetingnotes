import Foundation
import SwiftUI
import Combine
import PostHog

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
    case idle // Not recording, shows "Transcribe" or "Resume" based on transcript content
    case recording // Recording, shows "Stop"
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
    @Published var templates: [NoteTemplate] = []
    @Published var selectedTemplateId: UUID?
    
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
        
        // Load templates and selected template
        loadTemplates()
        // Observe template selection: save to meeting and regenerate notes on changes (skip initial)
        $selectedTemplateId
            .dropFirst()
            .sink { [weak self] newTemplateId in
                guard let self = self else { return }
                self.meeting.templateId = newTemplateId
                Task {
                    await self.generateNotes()
                }
            }
            .store(in: &cancellables)
        
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
        
        // Update error message when audio manager encounters errors
        audioManager.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                print("🚨 Audio Manager Error: \(errorMessage)")
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
        } else {
            recordingState = .idle
        }
    }
    
    var recordingButtonText: String {
        switch recordingState {
        case .idle:
            // Check if there's existing transcript content
            return meeting.transcriptChunks.isEmpty ? "Transcribe" : "Resume"
        case .recording:
            return "Stop"
        }
    }
    
    func toggleRecording() {
        switch recordingState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        }
    }
    
    func startRecording() {
        // Validate API key before starting recording
        Task {
            let validationResult = await APIKeyValidator.shared.validateCurrentAPIKey()
            
            switch validationResult {
            case .success():
                // Key is valid, proceed with recording
                audioManager.startRecording()
            case .failure(let error):
                // Show error message
                errorMessage = error.localizedDescription
                print("❌ API key validation failed: \(error.localizedDescription)")
            }
        }
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
    
    func loadTemplates() {
        templates = LocalStorageManager.shared.loadTemplates()

        // Load per-meeting template or default to Standard Meeting
        if let meetingTemplateId = meeting.templateId {
            selectedTemplateId = meetingTemplateId
        } else if let defaultTemplate = templates.first(where: { $0.title == "Standard Meeting" }) {
            selectedTemplateId = defaultTemplate.id
        }
    }
    
    func generateNotes() async {
        isGeneratingNotes = true
        errorMessage = nil
        
        // Clear any audio manager errors as well
        audioManager.errorMessage = nil
        
        // Clear existing notes for streaming
        meeting.generatedNotes = ""
        
        // Load settings for generation
        let userBlurb = UserDefaultsManager.shared.userBlurb
        let systemPrompt = UserDefaultsManager.shared.systemPrompt
        
        // Use streaming generation
        let stream = NotesGenerator.shared.generateNotesStream(
            meeting: meeting,
            userBlurb: userBlurb,
            systemPrompt: systemPrompt,
            templateId: selectedTemplateId
        )
        
        var hasError = false
        for await result in stream {
            switch result {
            case .content(let chunk):
                meeting.generatedNotes += chunk
            case .error(let error):
                errorMessage = error
                hasError = true
                print("🚨 Note Generation Error: \(error)")
                break
            }
        }
        
        // Only save if there was no error
        if !hasError {
            saveMeeting()
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
    
    func copyCurrentTabContent() {
        NSPasteboard.general.clearContents()
        
        let content: String
        switch selectedTab {
        case .myNotes:
            content = meeting.userNotes
        case .transcript:
            content = meeting.formattedTranscript
        case .enhancedNotes:
            var enhancedContent = ""
            
            // Add title as h1 header if title is set
            if !meeting.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                enhancedContent += "# \(meeting.title)\n\n"
            }
            
            // Add the generated notes
            enhancedContent += meeting.generatedNotes
            
            // Add attribution footer
            if !enhancedContent.isEmpty {
                enhancedContent += "\n\n---\n\nNotes generated using [Meetingnotes](https://meetingnotes.owengretzinger.com), the free, open source AI notetaker."
            }
            
            content = enhancedContent
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