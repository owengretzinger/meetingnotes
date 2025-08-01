import Foundation
import SwiftUI
import Combine
import PostHog

@MainActor
class MeetingListViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let recordingSessionManager = RecordingSessionManager.shared
    
    // Computed property to filter meetings based on search text
    var filteredMeetings: [Meeting] {
        guard !searchText.isEmpty else { return meetings }
        
        return meetings.filter { meeting in
            // Search in title
            meeting.title.localizedCaseInsensitiveContains(searchText) ||
            // Search in user notes
            meeting.userNotes.localizedCaseInsensitiveContains(searchText) ||
            // Search in generated notes
            meeting.generatedNotes.localizedCaseInsensitiveContains(searchText) ||
            // Search in transcript text
            meeting.transcriptChunks.contains { chunk in
                chunk.text.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    init() {
        loadMeetings()
        
        // Listen for saved meeting notifications to refresh the list
        NotificationCenter.default.publisher(for: .meetingSaved)
            .sink { [weak self] _ in
                print("🔔 Meeting saved notification received. Reloading meetings list...")
                self?.loadMeetings()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .meetingDeleted)
            .sink { [weak self] _ in
                print("🔔 Meeting deleted notification received. Reloading meetings list...")
                self?.loadMeetings()
            }
            .store(in: &cancellables)
    }
    
    func loadMeetings() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.async { [weak self] in
            let loadedMeetings = LocalStorageManager.shared.loadMeetings()
            print("📋 Loaded \(loadedMeetings.count) meetings")
            self?.meetings = loadedMeetings
            self?.isLoading = false
        }
    }
    
    func deleteMeeting(_ meeting: Meeting) {
        meetings.removeAll { $0.id == meeting.id }
        _ = LocalStorageManager.shared.deleteMeeting(meeting)
    }
    
    func createNewMeeting() -> Meeting {
        let newMeeting = Meeting()
        meetings.insert(newMeeting, at: 0)
        _ = LocalStorageManager.shared.saveMeeting(newMeeting)
        // Track meeting creation event
        PostHogSDK.shared.capture("meeting_created")
        return newMeeting
    }
} 