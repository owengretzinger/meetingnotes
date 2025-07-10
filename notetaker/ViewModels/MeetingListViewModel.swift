import Foundation
import SwiftUI

@MainActor
class MeetingListViewModel: ObservableObject {
    @Published var meetings: [Meeting] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadMeetings()
    }
    
    func loadMeetings() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.async { [weak self] in
            self?.meetings = LocalStorageManager.shared.loadMeetings()
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