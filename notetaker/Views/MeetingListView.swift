import SwiftUI

struct MeetingListView: View {
    @StateObject private var viewModel = MeetingListViewModel()
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                if viewModel.meetings.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Meetings Yet",
                        systemImage: "mic.slash",
                        description: Text("Start a new meeting to begin transcribing")
                    )
                } else {
                    ForEach(viewModel.meetings) { meeting in
                        NavigationLink(value: meeting) {
                            MeetingRowView(meeting: meeting)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteMeeting(viewModel.meetings[index])
                        }
                    }
                }
            }
            .navigationTitle("Meetings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        let newMeeting = viewModel.createNewMeeting()
                        navigationPath.append(newMeeting)
                    } label: {
                        Label("New Meeting", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: Meeting.self) { meeting in
                MeetingDetailView(meeting: meeting)
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading meetings...")
            }
        }
    }
}

struct MeetingRowView: View {
    let meeting: Meeting
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meeting.date, style: .date)
                .font(.headline)
            
            if !meeting.transcript.isEmpty {
                Text(meeting.transcript)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text("No transcript")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MeetingListView()
} 