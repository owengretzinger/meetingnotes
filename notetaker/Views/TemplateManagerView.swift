import SwiftUI

struct TemplateManagerView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTemplate = false
    @State private var editingTemplate: Template?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(settingsViewModel.settings.templates) { template in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(template.context)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if template.isDefault {
                                Text("Default")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        
                        // Show sections
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sections:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .fontWeight(.semibold)
                            
                            ForEach(template.sections) { section in
                                Text("• \(section.title)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .swipeActions(edge: .trailing) {
                        if !template.isDefault {
                            Button("Delete", role: .destructive) {
                                settingsViewModel.deleteTemplate(template.id)
                            }
                        }
                        
                        Button("Edit") {
                            editingTemplate = template
                        }
                        .tint(.orange)
                    }
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Template") {
                        showingAddTemplate = true
                    }
                }
            }
            .sheet(isPresented: $showingAddTemplate) {
                TemplateEditorView(settingsViewModel: settingsViewModel, template: nil)
            }
            .sheet(item: $editingTemplate) { template in
                TemplateEditorView(settingsViewModel: settingsViewModel, template: template)
            }
        }
    }
}

struct TemplateEditorView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    let template: Template?
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var context: String = ""
    @State private var sections: [TemplateSection] = []
    
    var isEditing: Bool {
        template != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Information") {
                    TextField("Template Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Context")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $context)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                Section("Sections") {
                    ForEach(sections.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Section Title", text: $sections[index].title)
                                .textFieldStyle(.roundedBorder)
                            
                            TextEditor(text: $sections[index].description)
                                .frame(minHeight: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                sections.remove(at: index)
                            }
                        }
                    }
                    
                    Button("Add Section") {
                        sections.append(TemplateSection(title: "", description: ""))
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                        dismiss()
                    }
                    .disabled(title.isEmpty || sections.isEmpty)
                }
            }
        }
        .onAppear {
            if let template = template {
                title = template.title
                context = template.context
                sections = template.sections
            } else {
                // Add a default section for new templates
                sections = [TemplateSection(title: "", description: "")]
            }
        }
    }
    
    private func saveTemplate() {
        let templateToSave = Template(
            id: template?.id ?? UUID(),
            title: title,
            context: context,
            sections: sections,
            isDefault: template?.isDefault ?? false
        )
        
        if isEditing {
            settingsViewModel.updateTemplate(templateToSave)
        } else {
            settingsViewModel.addTemplate(templateToSave)
        }
    }
}

#Preview {
    TemplateManagerView(settingsViewModel: SettingsViewModel())
}