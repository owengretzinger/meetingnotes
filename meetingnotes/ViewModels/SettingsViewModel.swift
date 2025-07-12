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
    }
    
    func saveSettings() {
        let openAISaved = KeychainHelper.shared.save(settings.openAIKey, forKey: "openAIKey")
        let blurbSaved = KeychainHelper.shared.save(settings.userBlurb, forKey: "userBlurb")
        let promptSaved = KeychainHelper.shared.save(settings.systemPrompt, forKey: "systemPrompt")
        
        if openAISaved && blurbSaved && promptSaved {
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
} 