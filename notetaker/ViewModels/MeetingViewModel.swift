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
    @Published var availableTemplates: [Template] = []
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
        
        // Load templates from settings
        loadTemplates()
        
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
            let systemPrompt = getSystemPromptWithTemplate()
            
            meeting.generatedNotes = try await NotesGenerator.shared.generateNotes(
                meeting: meeting,
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
    
    // Template-related methods
    func loadTemplates() {
        if let templatesData = KeychainHelper.shared.get(forKey: "templates")?.data(using: .utf8),
           let loadedTemplates = try? JSONDecoder().decode([Template].self, from: templatesData) {
            availableTemplates = loadedTemplates
        } else {
            availableTemplates = Template.defaultTemplates
        }
        
        // Load selected template ID - first check if meeting has a specific template
        if let meetingTemplateId = meeting.selectedTemplateId {
            self.selectedTemplateId = meetingTemplateId
        } else if let selectedTemplateIdString = KeychainHelper.shared.get(forKey: "selectedTemplateId"),
                  let selectedTemplateId = UUID(uuidString: selectedTemplateIdString) {
            self.selectedTemplateId = selectedTemplateId
            // Update meeting to match global selection
            meeting.selectedTemplateId = selectedTemplateId
        } else {
            let defaultTemplateId = availableTemplates.first?.id
            self.selectedTemplateId = defaultTemplateId
            meeting.selectedTemplateId = defaultTemplateId
        }
    }
    
    func selectTemplate(_ templateId: UUID) {
        selectedTemplateId = templateId
        meeting.selectedTemplateId = templateId
        // Save the selection globally
        KeychainHelper.shared.save(templateId.uuidString, forKey: "selectedTemplateId")
        // Save the meeting with the updated template selection
        saveMeeting()
    }
    
    var selectedTemplateName: String {
        guard let selectedId = selectedTemplateId else { return "General" }
        return availableTemplates.first { $0.id == selectedId }?.title ?? "General"
    }
    
    private func getSystemPromptWithTemplate() -> String {
        var settings = Settings()
        settings.userBlurb = KeychainHelper.shared.get(forKey: "userBlurb") ?? ""
        settings.templates = availableTemplates
        settings.selectedTemplateId = selectedTemplateId
        
        return settings.getSystemPromptWithTemplate()
    }
} 