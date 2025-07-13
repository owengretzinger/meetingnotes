import Foundation

struct Settings: Codable {
    var openAIKey: String
    var userBlurb: String
    var systemPrompt: String
    var selectedTemplateId: UUID?
    var hasCompletedOnboarding: Bool
    var hasAcceptedTerms: Bool
    
    // System prompt default loading
    static func defaultSystemPrompt() -> String {
        guard let path = Bundle.main.path(forResource: "DefaultSystemPrompt", ofType: "txt"),
              let content = try? String(contentsOfFile: path) else {
            return "You are a helpful assistant that creates comprehensive meeting notes from transcript data."
        }
        return content
    }
    
    // Add a computed property for the full prompt
    var fullSystemPrompt: String {
        let defaultPrompt = Settings.defaultSystemPrompt()
        if userBlurb.isEmpty {
            return defaultPrompt
        }
        return "\(defaultPrompt)\n\nContext about the user: \(userBlurb)"
    }
    
    // Template processing method
    static func processTemplate(_ template: String, with variables: [String: String]) -> String {
        var result = template
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{{\(key)}}", with: value)
        }
        return result
    }
    
    init(openAIKey: String = "",
         userBlurb: String = "",
         systemPrompt: String = "",
         selectedTemplateId: UUID? = nil,
         hasCompletedOnboarding: Bool = false,
         hasAcceptedTerms: Bool = false) {
        self.openAIKey = openAIKey
        self.userBlurb = userBlurb
        self.systemPrompt = systemPrompt.isEmpty ? Settings.defaultSystemPrompt() : systemPrompt
        self.selectedTemplateId = selectedTemplateId
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasAcceptedTerms = hasAcceptedTerms
    }
} 