import Foundation
import SwiftUI
import Combine

@MainActor
class MeetingListViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
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
            for meeting in loadedMeetings.prefix(3) {
                print("📋 Meeting: \(meeting.id) - title: '\(meeting.title)', notes: '\(meeting.userNotes.prefix(50))...'")
            }
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
        return newMeeting
    }
} 