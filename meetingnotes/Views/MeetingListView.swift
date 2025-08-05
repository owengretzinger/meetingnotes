import SwiftUI

struct MeetingListView: View {
    @StateObject private var viewModel = MeetingListViewModel()
    @ObservedObject var settingsViewModel: SettingsViewModel
    @StateObject private var recordingSessionManager = RecordingSessionManager.shared
    @State private var selectedMeeting: Meeting?
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with meetings list
            sidebarContent
        } detail: {
            // Detail view with meeting content
            detailContent
        }
        .navigationSplitViewStyle(.balanced)
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading meetings...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
            }
        }
    }
    
    private var sidebarContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search meetings...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            
            Divider()
            
            Spacer().frame(height: 12) // Add space before list content

            List(selection: $selectedMeeting) {
                // Only render meeting sections when there are meetings or loading state
                ForEach(groupedMeetings, id: \.day) { dayGroup in
                    Section {
                        ForEach(dayGroup.meetings, id: \.id) { meeting in
                            MeetingRowView(meeting: meeting)
                                .tag(meeting)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let meetingToDelete = dayGroup.meetings[index]
                                viewModel.deleteMeeting(meetingToDelete)
                                // Clear selection if the deleted meeting was selected
                                if selectedMeeting?.id == meetingToDelete.id {
                                    selectedMeeting = nil
                                }
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
        }
        .navigationTitle("Meetings")
    }
    
    private var detailContent: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let selectedMeeting = selectedMeeting {
                    MeetingDetailContentView(meeting: selectedMeeting, onDelete: {
                        // When a meeting is deleted from the detail view, clear the selection
                        self.selectedMeeting = nil
                    })
                    .id(selectedMeeting.id) // Force recreation when selection changes
                } else {
                    ContentUnavailableView(
                        "Select a Meeting",
                        systemImage: "sidebar.leading",
                        description: Text("Choose a meeting from the sidebar to view its details")
                    )
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Spacer()

                    Button {
                        navigationPath.append("settings")
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .help("Settings")

                    Button {
                        let newMeeting = viewModel.createNewMeeting()
                        selectedMeeting = newMeeting
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(recordingSessionManager.isRecording)
                    .help(recordingSessionManager.isRecording ? "Cannot create new meeting while recording is active" : "New Meeting")
                }
            }
            .navigationDestination(for: String.self) { path in
                if path == "settings" {
                    SettingsView(viewModel: settingsViewModel, navigationPath: $navigationPath)
                } else if path == "templates" {
                    TemplateListView()
                }
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
    @StateObject private var recordingSessionManager = RecordingSessionManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title or default
            HStack(spacing: 4) {
                if recordingSessionManager.isRecordingMeeting(meeting.id) {
                    Image(systemName: "record.circle")
                        .foregroundColor(.red)
                        .font(.headline)
                }
                Text(meeting.title.isEmpty ? "Untitled meeting" : meeting.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            // Date
            HStack {
                Text(meeting.date, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Meeting Detail Content View
// This is a refactored version of MeetingDetailView that works within the sidebar layout

struct CollapsedTranscriptChunkView: View {
    let chunk: CollapsedTranscriptChunk
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Source indicator
            HStack(spacing: 4) {
                Image(systemName: chunk.source.icon)
                    .font(.caption)
                    .foregroundColor(chunk.source == .mic ? .blue : .orange)
                
                Text(chunk.source.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(chunk.source == .mic ? .blue : .orange)
            }
            .frame(width: 50, alignment: .leading)
            
            // Transcript text
            Text(chunk.combinedText)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}

struct MeetingDetailContentView: View {
    @StateObject private var viewModel: MeetingViewModel
    @StateObject private var recordingSessionManager = RecordingSessionManager.shared
    @State private var showDeleteAlert = false
    @State private var isEditing = false
    @State private var showCopyConfirmation = false
    let onDelete: () -> Void
    
    init(meeting: Meeting, onDelete: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: MeetingViewModel(meeting: meeting))
        self.onDelete = onDelete
    }
    
    // Computed property to determine if recording button should be disabled
    private var cannotStartRecording: Bool {
        // Disable if another meeting is recording (not this one)
        return recordingSessionManager.isRecording && !recordingSessionManager.isRecordingMeeting(viewModel.meeting.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            VStack(alignment: .leading, spacing: 8) {
                // Meeting Title with Menu
                HStack {
                    TextField("Meeting Title", text: $viewModel.meeting.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .textFieldStyle(.plain)
                    
                    Spacer()
                    
                    // Ellipsis menu
                    Menu {
                        Button("Delete Meeting", role: .destructive) {
                            showDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundColor(.secondary)
                    }
                    .labelStyle(.iconOnly)
                    .menuIndicator(.hidden)
                    .menuStyle(BorderlessButtonMenuStyle())
                    .frame(width: 20, height: 20)
                }
                .padding(.bottom, 10)
                
                // Controls Section
                HStack {
                    // Left: Tab Toggles
                    Picker("", selection: $viewModel.selectedTab) {
                        ForEach(MeetingViewTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 260)
                    
                    Spacer()
                    
                    // Right: Generate and Recording Buttons
                    HStack(spacing: 8) {
                        // Generate Button (Dropdown)
                        Menu {
                            ForEach(viewModel.templates) { template in
                                Button(template.title) {
                                    viewModel.selectedTemplateId = template.id
                                    viewModel.selectedTab = .enhancedNotes
                                    isEditing = false
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if viewModel.isGeneratingNotes {
                                    ProgressView()
                                        .scaleEffect(0.4)
                                        .frame(width: 12, height: 12)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                }
                                Text("Generate")
                            }
                            .frame(minWidth: 110, minHeight: 36)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                // Shimmer overlay when ready
                                Group {
                                    if viewModel.shouldAnimateGenerateButton {
                                        ShimmerOverlay(color: .green)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.meeting.transcript.isEmpty || viewModel.isGeneratingNotes || viewModel.isRecording || viewModel.isStartingRecording)
                        .help("Generate enhanced notes using a template")
                        
                        // Recording Button
                        Button(action: {
                            viewModel.toggleRecording()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "record.circle")
                                    .foregroundColor(viewModel.isRecording ? .red : .accentColor)
                                Text(viewModel.recordingButtonText)
                            }
                            .frame(minWidth: 110, minHeight: 36)
                            .background(viewModel.isRecording ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                // Shimmer overlay when ready to transcribe
                                Group {
                                    if viewModel.shouldAnimateTranscribeButton {
                                        ShimmerOverlay(color: .accentColor)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(cannotStartRecording || viewModel.isValidatingKey || viewModel.isStartingRecording)
                        .help(cannotStartRecording ? "Another meeting is currently being recorded" : "Start or stop recording for this meeting")
                    }
                }
            }
            
            // Content Area with Tab-specific Headers
            VStack(alignment: .leading, spacing: 8) {
                // Tab Header with Copy and Edit buttons
                HStack(spacing: 8) {
                    Text(viewModel.selectedTab.rawValue)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Edit/Preview button (for My Notes and Enhanced Notes)
                    if viewModel.selectedTab == .myNotes || viewModel.selectedTab == .enhancedNotes {
                        Button(action: {
                            isEditing.toggle()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isEditing ? "eye" : "pencil")
                                Text(isEditing ? "Preview" : "Edit")
                            }
                            .frame(minWidth: 75, minHeight: 24)
                            .font(.caption)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Copy button
                    Button(action: {
                        viewModel.copyCurrentTabContent()
                        showCopyConfirmation = true
                        
                        // Reset confirmation after 1 second
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showCopyConfirmation = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showCopyConfirmation ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundColor(showCopyConfirmation ? .green : .primary)
                            Text(showCopyConfirmation ? "Copied!" : "Copy")
                                .foregroundColor(showCopyConfirmation ? .green : .primary)
                        }
                        .frame(minWidth: 70, minHeight: 24)
                        .font(.caption)
                        .background(showCopyConfirmation ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                // Tab Content
                switch viewModel.selectedTab {
                case .myNotes:
                    myNotesView
                case .transcript:
                    transcriptView
                case .enhancedNotes:
                    enhancedNotesView
                }
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Delete Meeting", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteMeeting()
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this meeting? This action cannot be undone.")
        }
        .onDisappear {
            // Auto-delete empty meetings when leaving, otherwise save
            viewModel.deleteIfEmpty()
        }
    }
    
    // MARK: - Content Views
    
    private var myNotesView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditing {
                TextEditor(text: $viewModel.meeting.userNotes)
                    .font(.body)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(viewModel.meeting.userNotes.isEmpty ? "No notes yet..." : viewModel.meeting.userNotes)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .foregroundColor(viewModel.meeting.userNotes.isEmpty ? .secondary : .primary)
                }
                .frame(maxHeight: .infinity)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            }
        }
    }
    
    private var transcriptView: some View {
        ScrollView {
            if viewModel.meeting.collapsedTranscriptChunks.isEmpty {
                Text("Transcript will appear here...")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .foregroundColor(.secondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(viewModel.meeting.collapsedTranscriptChunks) { chunk in
                        CollapsedTranscriptChunkView(chunk: chunk)
                    }
                }
                .padding()
            }
        }
        .frame(maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var enhancedNotesView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditing {
                TextEditor(text: Binding(
                    get: { viewModel.meeting.generatedNotes },
                    set: { viewModel.meeting.generatedNotes = $0 }
                ))
                    .font(.body)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .frame(maxHeight: .infinity)
            } else {
                RenderedNotesView(text: viewModel.meeting.generatedNotes)
                    .font(.body)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .frame(maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Shimmer Overlay
struct ShimmerOverlay: View {
    @State private var animate: Bool = false
    let color: Color
    
    init(color: Color = .green) {
        self.color = color
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, color.opacity(0.1), Color.clear]),
                        startPoint: UnitPoint(x: animate ? 2.5 : -1, y: 0.5),
                        endPoint: UnitPoint(x: animate ? 3.5 : 0, y: 0.5)
                    )
                )
                .frame(width: width, height: height)
                .onAppear {
                    animate = true
                }
                .animation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                    value: animate
                )
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    MeetingListView(settingsViewModel: SettingsViewModel())
} 
