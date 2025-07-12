import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // API Configuration Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("OpenAI API Key")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Stored locally and encrypted.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("OpenAI API Key", text: $viewModel.settings.openAIKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: .infinity)
                    }
                    
                    // User Information Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("User Information")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Meetingsnotes works best when it knows a bit about you. You should give your name, role, company, and any other relevant information.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $viewModel.settings.userBlurb)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                    }
                    
                    // System Prompt Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Prompt")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $viewModel.settings.systemPrompt)
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // GitHub Link Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Link(destination: URL(string: "https://github.com/owengretzinger/meetingnotes")!) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .foregroundColor(.blue)
                                Text("View on GitHub")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding(24)
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
                        dismiss()
                    }
                }
            }
            .frame(minWidth: 600, minHeight: 600)
        }
        .onAppear {
            viewModel.loadSettings()
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
} 