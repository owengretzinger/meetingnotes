import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // API Keys Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("API Keys")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Deepgram API Key")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                SecureField("Enter your Deepgram API key", text: $viewModel.settings.deepgramKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("OpenAI API Key")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                SecureField("Enter your OpenAI API key", text: $viewModel.settings.openAIKey)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Personal Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personal Information")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Yourself")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("This information will be included in the AI context when generating meeting notes.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $viewModel.settings.userBlurb)
                                .frame(minHeight: 80, maxHeight: 120)
                                .scrollContentBackground(.hidden)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separatorColor), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // AI Generation Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("AI Generation")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            Button("Reset to Default") {
                                viewModel.resetToDefaults()
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("System Prompt")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Customize how the AI generates your meeting notes.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $viewModel.settings.systemPrompt)
                                .frame(minHeight: 100, maxHeight: 160)
                                .scrollContentBackground(.hidden)
                                .background(Color(.controlBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.separatorColor), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 20)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("Settings")
            .frame(minWidth: 600, minHeight: 500)
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
                    .buttonStyle(.borderedProminent)
                }
            }
            .onChange(of: viewModel.saveSuccessful) { _, isSuccessful in
                if isSuccessful {
                    dismiss()
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