import SwiftUI

struct TemplateEditView: View {
    @State private var template: NoteTemplate
    let onSave: (NoteTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    init(template: NoteTemplate, onSave: @escaping (NoteTemplate) -> Void) {
        self._template = State(initialValue: template)
        self.onSave = onSave
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                // Template Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Template Name", text: $template.title)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Context
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meeting Context")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Provide context about the type of meeting this template is for")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $template.context)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Sections
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sections")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                template.sections.append(
                                    TemplateSection(
                                        title: "New Section",
                                        description: "Description of this section"
                                    )
                                )
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                Text("Add Section")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("Define the sections that will appear in the generated notes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(template.sections.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("Section Title", text: $template.sections[index].title)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    TextEditor(text: $template.sections[index].description)
                                        .scrollContentBackground(.hidden)
                                        .padding(8)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(8)
                                        .frame(minHeight: 60)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                                
                                Button {
                                    withAnimation {
                                        let _ = template.sections.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                                .padding(.leading, 8)
                            }
                        }
                        .padding()
                        // Adaptive background for light & dark mode
                        .background(
                            Color.secondary.opacity(0.1)
                        )
                        .cornerRadius(8)
                    }
                }
                
                // Save button
                Button {
                    onSave(template)
                    dismiss()
                } label: {
                    Text("Save Template")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.top)
                .disabled(template.title.isEmpty || template.sections.isEmpty)
            }
            .padding(24)
        }
        .navigationTitle("Edit Template")
    }
}

#Preview {
    NavigationStack {
        TemplateEditView(
            template: NoteTemplate(
                title: "Sample Template",
                context: "This is a sample context",
                sections: [
                    TemplateSection(title: "Section 1", description: "Description 1"),
                    TemplateSection(title: "Section 2", description: "Description 2")
                ]
            )
        ) { _ in }
    }
} 