import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var settings = Settings()
    @Published var saveMessage = ""
    @Published var showingSaveMessage = false
    @Published var templates: [NoteTemplate] = []
    
    init() {
        loadSettings()
        loadTemplates()
    }
    
    func loadSettings() {
        settings.openAIKey = KeychainHelper.shared.get(forKey: "openAIKey") ?? ""
        settings.userBlurb = KeychainHelper.shared.get(forKey: "userBlurb") ?? ""
        settings.systemPrompt = KeychainHelper.shared.get(forKey: "systemPrompt") ?? Settings.defaultSystemPrompt()
        
        // Load selected template ID
        if let templateIdString = KeychainHelper.shared.get(forKey: "selectedTemplateId"),
           let templateId = UUID(uuidString: templateIdString) {
            settings.selectedTemplateId = templateId
        }
    }
    
    func loadTemplates() {
        templates = LocalStorageManager.shared.loadTemplates()
        
        // Validate that the selected template still exists
        if let selectedId = settings.selectedTemplateId {
            if !templates.contains(where: { $0.id == selectedId }) {
                // Selected template was deleted, clear the selection
                settings.selectedTemplateId = nil
            }
        }
        
        // If no template is selected, select the first default template
        if settings.selectedTemplateId == nil {
            if let defaultTemplate = templates.first(where: { $0.title == "Standard Meeting" }) {
                settings.selectedTemplateId = defaultTemplate.id
            } else if let firstTemplate = templates.first {
                // Fallback to first available template
                settings.selectedTemplateId = firstTemplate.id
            }
        }
    }
    
    func saveSettings(showMessage: Bool = true) {
        // Validate that systemPrompt contains all required template placeholders
        let requiredKeys = ["meeting_title", "meeting_date", "transcript", "user_blurb", "user_notes", "template_content"]
        let missing = requiredKeys.filter { !settings.systemPrompt.contains("{{\($0)}}") }
        if !missing.isEmpty {
            if showMessage {
                saveMessage = "Cannot save settings: missing placeholders \(missing.map { "{{\($0)}}" }.joined(separator: ", ")) in system prompt"
                showingSaveMessage = true
            }
            return
        }

        let openAISaved = KeychainHelper.shared.save(settings.openAIKey, forKey: "openAIKey")
        let blurbSaved = KeychainHelper.shared.save(settings.userBlurb, forKey: "userBlurb")
        let promptSaved = KeychainHelper.shared.save(settings.systemPrompt, forKey: "systemPrompt")

        // Save selected template ID
        var templateIdSaved = true
        if let templateId = settings.selectedTemplateId {
            templateIdSaved = KeychainHelper.shared.save(templateId.uuidString, forKey: "selectedTemplateId")
        }

        if showMessage {
            if openAISaved && blurbSaved && promptSaved && templateIdSaved {
                saveMessage = "Settings saved successfully!"
            } else {
                saveMessage = "Error saving settings"
            }

            showingSaveMessage = true

            // Hide the message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showingSaveMessage = false
            }
        }
    }
    
    func resetToDefaults() {
        settings.systemPrompt = Settings.defaultSystemPrompt()
    }
} 