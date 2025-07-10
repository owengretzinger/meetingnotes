import SwiftUI

struct CollapsedTranscriptChunkView: View {
    let chunk: CollapsedTranscriptChunk
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
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
    
    init(meeting: Meeting) {
        self._viewModel = StateObject(wrappedValue: MeetingViewModel(meeting: meeting))
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
                        Button {
                            viewModel.copyTranscript()
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                    }
                    
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

