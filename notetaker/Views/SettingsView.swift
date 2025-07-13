import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingTemplateManager = false
    
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
                    
                    // Templates Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note Templates")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Templates help structure your meeting notes. Select a template or create custom ones.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        // Template Selector
                        HStack {
                            Picker("Template", selection: Binding(
                                get: { viewModel.settings.selectedTemplateId ?? UUID() },
                                set: { viewModel.selectTemplate($0) }
                            )) {
                                ForEach(viewModel.settings.templates) { template in
                                    Text(template.title).tag(template.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            
                            Button("Manage Templates") {
                                showingTemplateManager = true
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(6)
                        }
                        
                        // Show selected template preview
                        if let selectedTemplate = viewModel.settings.selectedTemplate {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Selected Template:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.semibold)
                                
                                Text(selectedTemplate.context)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 4)
                                
                                Text("Sections:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.semibold)
                                
                                ForEach(selectedTemplate.sections) { section in
                                    Text("• \(section.title)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                }
                            }
                            .padding(8)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
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
        .sheet(isPresented: $showingTemplateManager) {
            TemplateManagerView(settingsViewModel: viewModel)
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
} 