import SwiftUI

struct TemplateListView: View {
    @StateObject private var viewModel = TemplatesViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(viewModel.templates) { template in
                HStack {
                    NavigationLink(destination: TemplateEditView(template: template) { updatedTemplate in
                        viewModel.saveTemplate(updatedTemplate)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(template.title)
                                    .font(.headline)
                                if template.isDefault {
                                    Text("Default")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            if !template.context.isEmpty {
                                Text(template.context)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            Text("\(template.sections.count) sections")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Spacer()
                    
                    if !template.isDefault {
                        Button(role: .destructive) {
                            viewModel.deleteTemplate(template)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .contextMenu {
                    if !template.isDefault {
                        Button(role: .destructive) {
                            viewModel.deleteTemplate(template)
                        } label: {
                            Label("Delete Template", systemImage: "trash")
                        }
                    } else {
                        Text("Cannot delete default template")
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteTemplate(viewModel.templates[index])
                }
            }
        }
        .navigationTitle("Note Templates")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: TemplateEditView(template: viewModel.createNewTemplate()) { updatedTemplate in
                    viewModel.saveTemplate(updatedTemplate)
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("Loading templates...")
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

#Preview {
    TemplateListView()
} 