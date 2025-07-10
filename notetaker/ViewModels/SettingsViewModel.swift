import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var settings: Settings
    @Published var isSaving = false
    @Published var saveSuccessful = false
    @Published var errorMessage: String?
    
    init() {
        self.settings = Settings()
        loadSettings()
    }
    
    func loadSettings() {
        // Load API keys from Keychain
        settings.deepgramKey = KeychainHelper.shared.get(forKey: "deepgramKey") ?? ""
        settings.openAIKey = KeychainHelper.shared.get(forKey: "openAIKey") ?? ""
        settings.userBlurb = KeychainHelper.shared.get(forKey: "userBlurb") ?? ""
        settings.systemPrompt = KeychainHelper.shared.get(forKey: "systemPrompt") ?? Settings.defaultSystemPrompt
    }
    
    func saveSettings() {
        isSaving = true
        errorMessage = nil
        saveSuccessful = false
        
        // Save to Keychain
        let deepgramSaved = KeychainHelper.shared.save(settings.deepgramKey, forKey: "deepgramKey")
        let openAISaved = KeychainHelper.shared.save(settings.openAIKey, forKey: "openAIKey")
        let blurbSaved = KeychainHelper.shared.save(settings.userBlurb, forKey: "userBlurb")
        let promptSaved = KeychainHelper.shared.save(settings.systemPrompt, forKey: "systemPrompt")
        
        if deepgramSaved && openAISaved && blurbSaved && promptSaved {
            saveSuccessful = true
            // Show success briefly
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.saveSuccessful = false
            }
        } else {
            errorMessage = "Failed to save some settings. Please try again."
        }
        
        isSaving = false
    }
    
    func resetToDefaults() {
        settings.systemPrompt = Settings.defaultSystemPrompt
    }
} 