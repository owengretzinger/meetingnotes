import SwiftUI

struct TranscriptChunkView: View {
    let chunk: TranscriptChunk
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Source indicator
            HStack(spacing: 4) {
                Image(systemName: chunk.source.icon)
                    .font(.caption)
                    .foregroundColor(chunk.source == .mic ? .blue : .orange)
                
                Text(chunk.source.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(chunk.source == .mic ? .blue : .orange)
            }
            .frame(width: 60, alignment: .leading)
            
            // Transcript text
            Text(chunk.text)
                .font(.body)
                .foregroundColor(chunk.isFinal ? .primary : .secondary)
                .italic(!chunk.isFinal)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
        .opacity(chunk.isFinal ? 1.0 : 0.7)
    }
}

struct MeetingDetailView: View {
    @StateObject private var viewModel: MeetingViewModel
    @State private var selectedTranscriptFilter: TranscriptFilter = .all
    
    init(meeting: Meeting) {
        self._viewModel = StateObject(wrappedValue: MeetingViewModel(meeting: meeting))
    }
    
    enum TranscriptFilter: String, CaseIterable {
        case all = "All"
        case mic = "Microphone"
        case system = "System Audio"
        
        var icon: String {
            switch self {
            case .all: return "waveform"
            case .mic: return "mic.fill"
            case .system: return "speaker.wave.2.fill"
            }
        }
    }
    
    private var filteredTranscriptChunks: [TranscriptChunk] {
        switch selectedTranscriptFilter {
        case .all:
            return viewModel.meeting.transcriptChunks
        case .mic:
            return viewModel.meeting.transcriptChunks.filter { $0.source == .mic }
        case .system:
            return viewModel.meeting.transcriptChunks.filter { $0.source == .system }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Recording Controls
            VStack(spacing: 12) {
                Toggle("Capture System Audio", isOn: $viewModel.captureSystemAudio)
                    .disabled(viewModel.isRecording)
                
                HStack {
                    Button {
                        viewModel.startRecording()
                    } label: {
                        Label("Start Recording", systemImage: "record.circle")
                    }
                    .disabled(viewModel.isRecording)
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        viewModel.stopRecording()
                    } label: {
                        Label("Stop Recording", systemImage: "stop.circle")
                    }
                    .disabled(!viewModel.isRecording)
                    .buttonStyle(.bordered)
                }
                
                if viewModel.isRecording {
                    Label("Recording...", systemImage: "dot.radiowaves.left.and.right")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Transcript and Notes
            HStack(spacing: 20) {
                // Transcript Column
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Live Transcript")
                            .font(.headline)
                        Spacer()
                        
                        // Filter controls
                        Picker("Filter", selection: $selectedTranscriptFilter) {
                            ForEach(TranscriptFilter.allCases, id: \.self) { filter in
                                Label(filter.rawValue, systemImage: filter.icon)
                                    .tag(filter)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                        
                        Menu {
                            Button {
                                viewModel.copyTranscript()
                            } label: {
                                Label("Copy All", systemImage: "doc.on.doc")
                            }
                            
                            Button {
                                viewModel.copyMicTranscript()
                            } label: {
                                Label("Copy Microphone Only", systemImage: "mic.fill")
                            }
                            
                            Button {
                                viewModel.copySystemTranscript()
                            } label: {
                                Label("Copy System Audio Only", systemImage: "speaker.wave.2.fill")
                            }
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                    
                    ScrollView {
                        if filteredTranscriptChunks.isEmpty {
                            Text("Transcript will appear here...")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .foregroundColor(.secondary)
                        } else {
                            LazyVStack(alignment: .leading, spacing: 4) {
                                ForEach(filteredTranscriptChunks) { chunk in
                                    TranscriptChunkView(chunk: chunk)
                                }
                            }
                            .padding()
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                }
                
                // Notes Column
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Notes")
                        .font(.headline)
                    
                    TextEditor(text: $viewModel.meeting.userNotes)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            .frame(maxHeight: 300)
            
            // Generated Notes Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Generated Notes")
                        .font(.headline)
                    Spacer()
                    
                    if viewModel.isGeneratingNotes {
                        ProgressView()
                            .scaleEffect(0.7)
                    } else {
                        Button {
                            Task {
                                await viewModel.generateNotes()
                            }
                        } label: {
                            Label("Generate", systemImage: "sparkles")
                        }
                        .disabled(viewModel.meeting.transcript.isEmpty)
                        
                        Button {
                            viewModel.copyNotes()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .disabled(viewModel.meeting.generatedNotes.isEmpty)
                    }
                }
                
                TextEditor(text: $viewModel.meeting.generatedNotes)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .frame(minHeight: 150)
            }
        }
        .padding()
        .navigationTitle("Meeting Notes")
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        MeetingDetailView(meeting: Meeting())
    }
} 