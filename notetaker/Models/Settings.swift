import Foundation

struct Settings: Codable {
    var deepgramKey: String
    var openAIKey: String
    var userBlurb: String
    var systemPrompt: String
    
    static let defaultSystemPrompt: String = {
        guard let url = Bundle.main.url(forResource: "DefaultSystemPrompt", withExtension: "txt"),
              let content = try? String(contentsOf: url) else {
            assertionFailure("DefaultSystemPrompt.txt missing from bundle")
            return ""
        }
        return content
    }()
    
    // Required variables for the template
    static let requiredVariables: Set<String> = [
        "meeting_title",
        "meeting_date", 
        "transcript",
        "user_blurb",
        "user_notes"
    ]
    
    init(deepgramKey: String = "",
         openAIKey: String = "",
         userBlurb: String = "",
         systemPrompt: String = Settings.defaultSystemPrompt) {
        self.deepgramKey = deepgramKey
        self.openAIKey = openAIKey
        self.userBlurb = userBlurb
        self.systemPrompt = systemPrompt
    }
    
    // MARK: - Template Methods
    
    /// Extracts all template variables from a system prompt string
    static func extractTemplateVariables(from template: String) -> Set<String> {
        let pattern = #"\{\{(\w+)\}\}"#
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: template, options: [], range: NSRange(location: 0, length: template.count))
        
        var variables: Set<String> = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: template) {
                variables.insert(String(template[range]))
            }
        }
        return variables
    }
    
    /// Validates that all required variables are present in the system prompt
    func validateSystemPrompt() -> (isValid: Bool, missingVariables: Set<String>) {
        let presentVariables = Settings.extractTemplateVariables(from: systemPrompt)
        let missingVariables = Settings.requiredVariables.subtracting(presentVariables)
        return (isValid: missingVariables.isEmpty, missingVariables: missingVariables)
    }
    
    /// Replaces template variables in the system prompt with actual values
    static func processTemplate(_ template: String, with variables: [String: String]) -> String {
        var result = template
        
        for (key, value) in variables {
            let placeholder = "{{\(key)}}"
            result = result.replacingOccurrences(of: placeholder, with: value)
        }
        
        return result
    }
} 