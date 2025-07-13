import Foundation

struct TemplateSection: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    
    init(id: UUID = UUID(), title: String, description: String) {
        self.id = id
        self.title = title
        self.description = description
    }
}

struct Template: Codable, Identifiable {
    let id: UUID
    var title: String
    var context: String
    var sections: [TemplateSection]
    var isDefault: Bool
    
    init(id: UUID = UUID(), title: String, context: String, sections: [TemplateSection], isDefault: Bool = false) {
        self.id = id
        self.title = title
        self.context = context
        self.sections = sections
        self.isDefault = isDefault
    }
    
    // Generate system prompt content for this template
    func generateSystemPromptContent() -> String {
        let sectionsText = sections.map { "- \($0.title): \($0.description)" }.joined(separator: "\n")
        
        return """
        \(context)
        
        Your enhanced meeting notes should include the following sections:
        \(sectionsText)
        
        Include only these section headers, unless the user requests otherwise (see formatting_requests section).
        """
    }
}

extension Template {
    // Default templates
    static let defaultTemplates: [Template] = [
        Template(
            title: "General Meeting",
            context: "Please create structured meeting notes that capture the key information and outcomes from this meeting.",
            sections: [
                TemplateSection(title: "Key Discussion Points", description: "The main topics and issues discussed during the meeting"),
                TemplateSection(title: "Action Items", description: "Specific tasks and assignments with responsible parties"),
                TemplateSection(title: "Decisions Made", description: "Key decisions and conclusions reached during the meeting"),
                TemplateSection(title: "Deadlines and Follow-up", description: "Important dates and required follow-up actions")
            ],
            isDefault: true
        ),
        
        Template(
            title: "1:1 Meeting",
            context: "I am having a 1:1 meeting with someone in my team, please capture these meeting notes in a concise and actionable format. Focus on immediate priorities, progress, challenges, and personal feedback, ensuring the notes are structured for clarity, efficiency and easy follow-up.",
            sections: [
                TemplateSection(title: "Top of mind", description: "What's the most pressing issue or priority? Capture the top concerns or focus areas that need immediate attention."),
                TemplateSection(title: "Updates and wins", description: "Highlight recent achievements and progress. What's going well? Document key updates that show momentum."),
                TemplateSection(title: "Challenges and blockers", description: "What obstacles are in the way? Note any blockers that are slowing progress."),
                TemplateSection(title: "Mutual feedback", description: "Did they give me any feedback on what I could do differently? Is there anything I should change about our team to make us more successful? Did I share any feedback for them? List it all here."),
                TemplateSection(title: "Next Milestone", description: "Define clear action items and next steps. Who's doing what by when? Ensure accountability and follow-up.")
            ],
            isDefault: true
        ),
        
        Template(
            title: "Customer Discovery",
            context: "I had a call with a potential customer. This call helps me to understand their needs, concerns, and goals, and ensure that I gather all the necessary information to follow up effectively. I'm interested in the details that might help me close a deal. Please pull out specific figures and helpful quotes. Focus only on what they say, not me.",
            sections: [
                TemplateSection(title: "Their background", description: "I care about key details about the client's business, industry, and role. This context helps me understand where they are coming from and what might be driving their needs for my product."),
                TemplateSection(title: "Pain points and needs", description: "Please highlight the specific challenges and needs they express. This section is crucial for understanding what problems they are trying to solve and what they are looking for in a solution."),
                TemplateSection(title: "Questions or concerns", description: "Capture any questions or concerns they raise during the meeting. This section ensures that I address their worries and provide relevant follow-up information."),
                TemplateSection(title: "Budget and timeline", description: "How much do they have to spend? Are there any key dates I should be aware of?"),
                TemplateSection(title: "Next Steps", description: "Outline the next steps based on our conversation. This could include scheduling another meeting, sending additional information, or any other follow-up actions needed to keep the conversation moving forward. Include any relevant dates and deadlines which are mentioned.")
            ],
            isDefault: true
        ),
        
        Template(
            title: "Hiring Interview",
            context: "I met with a job candidate to assess their suitability for a position within our company.",
            sections: [
                TemplateSection(title: "Their background", description: "Detail the candidate's professional journey, education, and overall career progression. Include information about their current role and responsibilities, as well as any significant achievements or projects they've worked on."),
                TemplateSection(title: "Skills and experience", description: "Highlight the specific skills and experiences that are most relevant to the position. Focus on technical abilities, soft skills, and any particular areas of expertise that align with the job requirements."),
                TemplateSection(title: "Motivation and fit", description: "Include the candidate's career aspirations and why they're interested in this particular role and company."),
                TemplateSection(title: "Availability and salary expectations", description: "Note down the candidate's current notice period or earliest start date. Include their salary expectations and any other compensation-related questions."),
                TemplateSection(title: "My thoughts", description: "I may have written my thoughts in the raw notes, list them here. Otherwise, put N/A."),
                TemplateSection(title: "Next steps", description: "Write here any subsequent stages in the hiring process that I mention. Include any considerations regarding the candidate's availability or timelines that they mention.")
            ],
            isDefault: true
        ),
        
        Template(
            title: "Stand-Up Meeting",
            context: "I attended a daily standup meeting. The goal is to document each participant's updates regarding their recent accomplishments, current focus, and any blockers they are facing. Keep these notes short and to-the-point.",
            sections: [
                TemplateSection(title: "Announcements", description: "Include any note-worthy points from the small-talk or announcements at the beginning of the call."),
                TemplateSection(title: "Updates", description: "Break these down into what was achieved yesterday, or accomplishments, what each person is working on today and highlight any blockers that could impact progress."),
                TemplateSection(title: "Sidebar", description: "Summarize any further discussions or issues that were explored after the main updates. Note any collaborative efforts, decisions made, or additional points raised."),
                TemplateSection(title: "Action Items", description: "Document and assign next steps from the meeting, summarize immediate tasks, provide reminders, and ensure accountability and clarity on responsibilities.")
            ],
            isDefault: true
        ),
        
        Template(
            title: "Weekly Team Meeting",
            context: "I met with my team to assess our project's health and align our efforts. My aim was to gain a clear understanding of our progress, address any emerging challenges, and ensure each team member is clear on their role in advancing our goals",
            sections: [
                TemplateSection(title: "Announcements", description: "Note here any significant announcements made, whether they relate to professional and company-wide updates, or important events in the personal lives of my colleagues."),
                TemplateSection(title: "Review of Progress", description: "Capture the discussion on the team's progress towards the overall strategic goals."),
                TemplateSection(title: "Key Achievements", description: "Summarize the notable achievements and results shared by team members, highlighting significant successes or completed tasks from the past week."),
                TemplateSection(title: "Challenges and Adjustments Needed", description: "Document any challenges the team is facing, including obstacles that have arisen. Note any adjustments or changes in strategy that were discussed to overcome these challenges."),
                TemplateSection(title: "Action Items and Accountability for the Week Ahead", description: "Record the action items assigned for the upcoming week, including who is responsible for each task and any deadlines or accountability measures that were agreed upon.")
            ],
            isDefault: true
        )
    ]
}