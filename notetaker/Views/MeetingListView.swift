import SwiftUI

struct MeetingListView: View {
    @StateObject private var viewModel = MeetingListViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                // Only render meeting sections when there are meetings or loading state
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
            .overlay {
                if viewModel.filteredMeetings.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        viewModel.searchText.isEmpty ? "No Meetings Yet" : "No Results",
                        systemImage: viewModel.searchText.isEmpty ? "mic.slash" : "magnifyingglass",
                        description: Text(viewModel.searchText.isEmpty ? "Start a new meeting to begin transcribing" : "Try a different search term")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Meetings")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    // Search field (leftmost within the right-aligned group)
                    HStack(spacing: 4) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search meetings...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.5))
                    )
                    .frame(width: 220)
                    // Settings button (middle)
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    // Plus button (rightmost)
                    Button {
                        let newMeeting = viewModel.createNewMeeting()
                        navigationPath.append(newMeeting)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
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
    
    private var groupedMeetings: [DayGroup] {
        let calendar = Calendar.current
        let now = Date()
        
        let grouped = Dictionary(grouping: viewModel.filteredMeetings) { meeting in
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