import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var settings = Settings()
    @Published var saveMessage = ""
    @Published var showingSaveMessage = false
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        settings.openAIKey = KeychainHelper.shared.get(forKey: "openAIKey") ?? ""
        settings.userBlurb = KeychainHelper.shared.get(forKey: "userBlurb") ?? ""
        settings.systemPrompt = KeychainHelper.shared.get(forKey: "systemPrompt") ?? Settings.defaultSystemPrompt()
        
        // Load templates
        if let templatesData = KeychainHelper.shared.get(forKey: "templates")?.data(using: .utf8),
           let loadedTemplates = try? JSONDecoder().decode([Template].self, from: templatesData) {
            settings.templates = loadedTemplates
        } else {
            settings.templates = Template.defaultTemplates
        }
        
        // Load selected template ID
        if let selectedTemplateIdString = KeychainHelper.shared.get(forKey: "selectedTemplateId"),
           let selectedTemplateId = UUID(uuidString: selectedTemplateIdString) {
            settings.selectedTemplateId = selectedTemplateId
        } else {
            settings.selectedTemplateId = settings.templates.first?.id
        }
    }
    
    func saveSettings() {
        let openAISaved = KeychainHelper.shared.save(settings.openAIKey, forKey: "openAIKey")
        let blurbSaved = KeychainHelper.shared.save(settings.userBlurb, forKey: "userBlurb")
        let promptSaved = KeychainHelper.shared.save(settings.systemPrompt, forKey: "systemPrompt")
        
        // Save templates
        var templatesSaved = false
        if let templatesData = try? JSONEncoder().encode(settings.templates),
           let templatesString = String(data: templatesData, encoding: .utf8) {
            templatesSaved = KeychainHelper.shared.save(templatesString, forKey: "templates")
        }
        
        // Save selected template ID
        let selectedTemplateIdSaved = KeychainHelper.shared.save(
            settings.selectedTemplateId?.uuidString ?? "",
            forKey: "selectedTemplateId"
        )
        
        if openAISaved && blurbSaved && promptSaved && templatesSaved && selectedTemplateIdSaved {
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
    
    func resetToDefaults() {
        settings.systemPrompt = Settings.defaultSystemPrompt()
    }
    
    // Template management methods
    func addTemplate(_ template: Template) {
        settings.addTemplate(template)
        saveSettings()
    }
    
    func updateTemplate(_ template: Template) {
        settings.updateTemplate(template)
        saveSettings()
    }
    
    func deleteTemplate(_ templateId: UUID) {
        settings.deleteTemplate(templateId)
        saveSettings()
    }
    
    func selectTemplate(_ templateId: UUID) {
        settings.selectTemplate(templateId)
        saveSettings()
    }
} 