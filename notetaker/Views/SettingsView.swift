import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("API Keys") {
                    SecureField("Deepgram API Key", text: $viewModel.settings.deepgramKey)
                        .textFieldStyle(.roundedBorder)
                    
                    SecureField("OpenAI API Key", text: $viewModel.settings.openAIKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Personal Information") {
                    VStack(alignment: .leading) {
                        Text("About Yourself")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.settings.userBlurb)
                            .frame(minHeight: 80)
                            .scrollContentBackground(.hidden)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                
                Section("AI Generation") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("System Prompt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Reset to Default") {
                                viewModel.resetToDefaults()
                            }
                            .font(.caption)
                        }
                        TextEditor(text: $viewModel.settings.systemPrompt)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveSettings()
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .overlay {
                if viewModel.saveSuccessful {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Settings saved successfully")
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        .padding()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

#Preview {
    SettingsView()
} 