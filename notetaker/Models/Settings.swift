import Foundation

struct Settings: Codable {
    var deepgramKey: String
    var openAIKey: String
    var userBlurb: String
    var systemPrompt: String
    
    static let defaultSystemPrompt = "Generate concise meeting notes from the transcript and any additional notes provided. Focus on key points, action items, and decisions made."
    
    init(deepgramKey: String = "",
         openAIKey: String = "",
         userBlurb: String = "",
         systemPrompt: String = Settings.defaultSystemPrompt) {
        self.deepgramKey = deepgramKey
        self.openAIKey = openAIKey
        self.userBlurb = userBlurb
        self.systemPrompt = systemPrompt
    }
} 