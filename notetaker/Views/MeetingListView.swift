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
                    ForEach(groupedMeetings, id: \.day) { dayGroup in
                        Section {
                            ForEach(dayGroup.meetings) { meeting in
                                NavigationLink(value: meeting) {
                                    MeetingRowView(meeting: meeting)
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    viewModel.deleteMeeting(dayGroup.meetings[index])
                                }
                            }
                        } header: {
                            Text(dayGroup.day)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
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
            .onAppear {
                viewModel.loadMeetings()
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading meetings...")
            }
        }
    }
    
    private var groupedMeetings: [DayGroup] {
        let calendar = Calendar.current
        let now = Date()
        
        let grouped = Dictionary(grouping: viewModel.meetings) { meeting in
            calendar.startOfDay(for: meeting.date)
        }
        
        return grouped.map { (date, meetings) in
            let dayString: String
            
            if calendar.isDateInToday(date) {
                dayString = "Today"
            } else if calendar.isDateInYesterday(date) {
                dayString = "Yesterday"
            } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
                dayString = date.formatted(.dateTime.weekday(.wide))
            } else {
                dayString = date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
            }
            
            return DayGroup(day: dayString, date: date, meetings: meetings.sorted { $0.date > $1.date })
        }.sorted { $0.date > $1.date }
    }
}

struct DayGroup {
    let day: String
    let date: Date
    let meetings: [Meeting]
}

struct MeetingRowView: View {
    let meeting: Meeting
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // Title or default
                Text(meeting.title.isEmpty ? "Untitled meeting" : meeting.title)
                    .font(.headline)
                    .lineLimit(1)
                
                // Notes preview or placeholder
                HStack {
                    if !meeting.generatedNotes.isEmpty {
                        Text(meeting.generatedNotes.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("No notes yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    Spacer()
                }
                .padding(.trailing, 20)
            }
            
            Spacer()
            
            // Date on the right
            Text(meeting.date, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MeetingListView()
} 