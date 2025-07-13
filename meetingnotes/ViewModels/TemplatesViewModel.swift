import Foundation
import SwiftUI

@MainActor
class TemplatesViewModel: ObservableObject {
    @Published var templates: [NoteTemplate] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadTemplates()
    }
    
    func loadTemplates() {
        isLoading = true
        templates = LocalStorageManager.shared.loadTemplates()
        isLoading = false
    }
    
    func saveTemplate(_ template: NoteTemplate) {
        if LocalStorageManager.shared.saveTemplate(template) {
            loadTemplates()
        } else {
            errorMessage = "Failed to save template"
        }
    }
    
    func deleteTemplate(_ template: NoteTemplate) {
        if LocalStorageManager.shared.deleteTemplate(template) {
            loadTemplates()
        } else {
            errorMessage = "Cannot delete default templates"
        }
    }
    
    func createNewTemplate() -> NoteTemplate {
        return NoteTemplate(
            title: "New Template",
            context: "",
            sections: [
                TemplateSection(title: "Section 1", description: "Description of section 1")
            ]
        )
    }
} 