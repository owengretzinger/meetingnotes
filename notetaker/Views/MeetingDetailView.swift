import SwiftUI

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
                        Text(viewModel.meeting.transcript.isEmpty ? "Transcript will appear here..." : viewModel.meeting.transcript)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
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