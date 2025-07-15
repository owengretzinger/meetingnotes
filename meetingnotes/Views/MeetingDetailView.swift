import SwiftUI

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

struct MeetingDetailView: View {
    @StateObject private var viewModel: MeetingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var isEditing = false
    
    init(meeting: Meeting) {
        self._viewModel = StateObject(wrappedValue: MeetingViewModel(meeting: meeting))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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
                // Replace checkbox-style toggles with a native segmented control for a cleaner look
                Picker("", selection: $viewModel.selectedTab) {
                    ForEach(MeetingViewTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260) // keep it compact so the recording controls have space
                
                Spacer()
                
                // Right: Recording and Copy Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.toggleRecording()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: viewModel.recordingState == .recording ? "stop.circle.fill" : "record.circle")
                                .foregroundColor(viewModel.recordingState == .recording ? .red : .accentColor)
                            Text(viewModel.recordingButtonText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.recordingState == .recording ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        viewModel.copyCurrentTabContent()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Content Area
            VStack(alignment: .leading, spacing: 8) {
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
        .navigationTitle("")
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
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this meeting? This action cannot be undone.")
        }
        .onDisappear {
            // Stop recording if it's in progress when leaving the page
            if viewModel.isRecording {
                print("🛑 Stopping recording because user is leaving the page")
                viewModel.stopRecording()
            }
            
            // Auto-delete empty meetings when leaving, otherwise save
            viewModel.deleteIfEmpty()
        }
    }
    
    // MARK: - Content Views
    
    private var myNotesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("My Notes")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $viewModel.meeting.userNotes)
                .font(.body)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
                .frame(maxHeight: .infinity)
        }
    }
    
    private var transcriptView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transcript")
                .font(.headline)
                .foregroundColor(.secondary)
            
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
    }
    
    private var enhancedNotesView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Enhanced Notes")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if viewModel.isGeneratingNotes {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    // Template selector
                    Picker("", selection: $viewModel.selectedTemplateId) {
                        ForEach(viewModel.templates) { template in
                            Text(template.title).tag(template.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                    
                    Button(action: {
                        Task {
                            await viewModel.generateNotes()
                            isEditing = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("Generate")
                        }
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.meeting.transcript.isEmpty)
                }
                Button(action: {
                    isEditing.toggle()
                }) {
                    Image(systemName: isEditing ? "pencil.circle.fill" : "pencil.circle")
                }
                .buttonStyle(.plain)
            }
            
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

#Preview {
    NavigationStack {
        MeetingDetailView(meeting: Meeting())
    }
} 

