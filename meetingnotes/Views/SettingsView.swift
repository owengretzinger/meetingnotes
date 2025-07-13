import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingTemplateManager = false
    @Binding var navigationPath: NavigationPath
    
    init(viewModel: SettingsViewModel, navigationPath: Binding<NavigationPath> = .constant(NavigationPath())) {
        self.viewModel = viewModel
        self._navigationPath = navigationPath
    }
    
    var body: some View {
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
                
                // Note Templates Section: only the Manage Templates button
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note Templates")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Create and manage note templates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button {
                        navigationPath.append("templates")
                    } label: {
                        Text("Manage Templates")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                
                // User Information Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("User Information")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Meetingnotes works best when it knows a bit about you. You should give your name, role, company, and any other relevant information.")
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
                    HStack {
                        Text("System Prompt")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Button {
                            viewModel.resetToDefaults()
                        } label: {
                            Text("Reset to Default")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
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
                    
                    // Link to GitHub repository
                    Link("https://github.com/owengretzinger/meetingnotes",
                         destination: URL(string: "https://github.com/owengretzinger/meetingnotes")!)
                        .foregroundColor(.blue)

                    // Link to landing page
                    Link("https://meetingnotes.owengretzinger.com",
                         destination: URL(string: "https://meetingnotes.owengretzinger.com")!)
                        .foregroundColor(.blue)
                }
                
                // Save button
                Button {
                    viewModel.saveSettings()
                } label: {
                    Text("Save Settings")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.top)
            }
            .padding(24)
        }
        .navigationTitle("Settings")
        .frame(minWidth: 600, minHeight: 600)
        .onAppear {
            viewModel.loadSettings()
            viewModel.loadTemplates()
        }
        .onDisappear {
            DispatchQueue.main.async {
                viewModel.saveSettings(showMessage: false)
            }
        }
        .alert("Settings Saved", isPresented: $viewModel.showingSaveMessage) {
            Button("OK") { }
        } message: {
            Text(viewModel.saveMessage)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
} 