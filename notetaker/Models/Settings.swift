import Foundation

struct Settings: Codable {
    var openAIKey: String
    var userBlurb: String
    var systemPrompt: String
    var templates: [Template]
    var selectedTemplateId: UUID?
    
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
         templates: [Template] = Template.defaultTemplates,
         selectedTemplateId: UUID? = nil) {
        self.openAIKey = openAIKey
        self.userBlurb = userBlurb
        self.systemPrompt = systemPrompt.isEmpty ? Settings.defaultSystemPrompt() : systemPrompt
        self.templates = templates
        self.selectedTemplateId = selectedTemplateId ?? templates.first?.id
    }
    
    // Template management methods
    var selectedTemplate: Template? {
        guard let selectedId = selectedTemplateId else { return templates.first }
        return templates.first { $0.id == selectedId } ?? templates.first
    }
    
    mutating func addTemplate(_ template: Template) {
        templates.append(template)
    }
    
    mutating func updateTemplate(_ template: Template) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        }
    }
    
    mutating func deleteTemplate(_ templateId: UUID) {
        templates.removeAll { $0.id == templateId }
        // If we deleted the selected template, select the first one
        if selectedTemplateId == templateId {
            selectedTemplateId = templates.first?.id
        }
    }
    
    mutating func selectTemplate(_ templateId: UUID) {
        selectedTemplateId = templateId
    }
    
    // Get the full system prompt with template applied
    func getSystemPromptWithTemplate() -> String {
        let basePrompt = Settings.defaultSystemPrompt()
        
        if let template = selectedTemplate {
            // Replace the default sections with template sections
            let templateContent = template.generateSystemPromptContent()
            let updatedPrompt = basePrompt.replacingOccurrences(
                of: """
                Your enhanced meeting notes should include the following sections:
                - the key discussion points
                - action items
                - decisions made
                - any deadlines or follow-up required
                
                Include only these section headers, unless the user requests otherwise (see formatting_requests section).
                """,
                with: templateContent
            )
            
            if userBlurb.isEmpty {
                return updatedPrompt
            }
            return "\(updatedPrompt)\n\nContext about the user: \(userBlurb)"
        }
        
        return fullSystemPrompt
    }

} 